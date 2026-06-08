#!/usr/bin/env python3
"""
MCP Server: Fuzz Runner
Runs Foundry fuzz tests and extracts A1 signals (profitability, execution trace, revert reason).
"""
import sys
import json
import asyncio
import tempfile
import subprocess
import logging
import os
import re
import shutil

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("fuzz_runner")

TOOL_NAME = "fuzz_runner"
TOOL_VERSION = "1.0.0"

FOUNDRY_TOML_TEMPLATE = """[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "0.8.20"
optimizer = true
optimizer_runs = 200
fuzz.runs = 256
fuzz.max_test_rejects = 65536

[profile.default.fuzz]
runs = 256
max_test_rejects = 65536
"""

TEST_FILE_TEMPLATE = """// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

{source_contract}

{test_contract}
"""


def build_tool_definitions() -> list:
    return [
        {
            "name": "run_fuzz_test",
            "description": "Run Foundry fuzz tests on a smart contract. Creates a temporary Foundry project, compiles, and executes fuzz tests. Returns execution traces, revert reasons, and profitability analysis.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "contract_code": {
                        "type": "string",
                        "description": "The Solidity source code of the contract to test"
                    },
                    "test_code": {
                        "type": "string",
                        "description": "The Foundry test contract code (must inherit Test and have test_ functions)"
                    },
                    "timeout": {
                        "type": "integer",
                        "description": "Timeout in seconds for the fuzz test (default: 300)",
                        "default": 300
                    }
                },
                "required": ["contract_code", "test_code"]
            }
        }
    ]


async def run_foundry_fuzz(contract_code: str, test_code: str, timeout: int = 300) -> dict:
    """Create a temp Foundry project, run fuzz tests, parse results."""
    tmp_dir = tempfile.mkdtemp(prefix="fuzz_")

    try:
        # Initialize Foundry project
        src_dir = os.path.join(tmp_dir, "src")
        lib_dir = os.path.join(tmp_dir, "lib")
        test_dir = os.path.join(tmp_dir, "test")
        os.makedirs(src_dir)
        os.makedirs(lib_dir)
        os.makedirs(test_dir)

        # Write foundry.toml
        with open(os.path.join(tmp_dir, "foundry.toml"), "w") as f:
            f.write(FOUNDRY_TOML_TEMPLATE)

        # Install forge-std
        logger.info("Installing forge-std...")
        proc = await asyncio.create_subprocess_exec(
            "git", "clone", "--depth=1", "https://github.com/foundry-rs/forge-std.git",
            os.path.join(lib_dir, "forge-std"),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        await proc.communicate()

        if proc.returncode != 0:
            return {"success": False, "error": "Failed to install forge-std"}

        # Write source contract
        source_path = os.path.join(src_dir, "Target.sol")
        with open(source_path, "w") as f:
            f.write(contract_code)

        # Write test contract
        test_path = os.path.join(test_dir, "FuzzTest.t.sol")
        with open(test_path, "w") as f:
            f.write(test_code)

        # Compile
        logger.info("Compiling contracts...")
        proc = await asyncio.create_subprocess_exec(
            "forge", "build", "--force",
            cwd=tmp_dir,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await proc.communicate()

        if proc.returncode != 0:
            stderr_text = stderr.decode("utf-8", errors="replace")
            return {
                "success": False,
                "error": "Compilation failed",
                "compile_error": stderr_text,
                "stdout": stdout.decode("utf-8", errors="replace")
            }

        # Run fuzz tests with maximum verbosity
        logger.info(f"Running fuzz tests (timeout: {timeout}s)...")
        proc = await asyncio.create_subprocess_exec(
            "forge", "test", "--json", "-vvvvv", "--fuzz-runs", "256",
            cwd=tmp_dir,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )

        try:
            stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=timeout)
        except asyncio.TimeoutError:
            proc.kill()
            return {"success": False, "error": f"Fuzz test timed out after {timeout}s"}

        stdout_text = stdout.decode("utf-8", errors="replace")
        stderr_text = stderr.decode("utf-8", errors="replace")

        # Parse JSON output
        test_results = parse_test_output(stdout_text)

        # Extract A1 signals
        a1_signals = extract_a1_signals(test_results, stderr_text)

        return {
            "success": True,
            "exit_code": proc.returncode,
            "tests_passed": proc.returncode == 0,
            "test_results": test_results,
            "a1_signals": a1_signals,
            "stderr": stderr_text[:2000] if stderr_text else None
        }

    except Exception as e:
        logger.exception("Error in fuzz runner")
        return {"success": False, "error": f"Unexpected error: {str(e)}"}
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def parse_test_output(stdout_text: str) -> list:
    """Parse forge test JSON output."""
    results = []

    try:
        # forge test --json outputs one JSON object per line
        for line in stdout_text.strip().split("\n"):
            line = line.strip()
            if not line:
                continue
            try:
                data = json.loads(line)
                test_name = data.get("test", data.get("name", ""))

                # Extract contract and function name
                parts = test_name.split("::")
                contract = parts[0] if len(parts) > 0 else ""
                function = parts[1] if len(parts) > 1 else test_name

                result = {
                    "test_name": test_name,
                    "contract": contract,
                    "function": function,
                    "status": "PASS" if data.get("result", {}).get("status") == "Success" else "FAIL",
                    "reason": data.get("result", {}).get("reason", None),
                    "duration": data.get("result", {}).get("duration", None),
                    "decoded_logs": data.get("decoded_logs", []),
                    "trace": data.get("result", {}).get("traces", [])
                }
                results.append(result)
            except json.JSONDecodeError:
                continue

        # Fallback: parse non-JSON output
        if not results:
            for line in stdout_text.split("\n"):
                if "[PASS]" in line:
                    results.append({"test_name": line.strip(), "status": "PASS"})
                elif "[FAIL]" in line:
                    results.append({"test_name": line.strip(), "status": "FAIL", "reason": line.strip()})

    except Exception as e:
        logger.warning(f"Error parsing test output: {e}")

    return results


def extract_a1_signals(test_results: list, stderr_text: str) -> dict:
    """Extract A1 analysis signals from fuzz test results."""
    signals = {
        "profitability": None,
        "execution_traces": [],
        "revert_reasons": [],
        "fuzz_statistics": {},
        "summary": ""
    }

    failed_tests = [r for r in test_results if r.get("status") == "FAIL"]

    # Signal 1: Profitability analysis
    # Look for balance changes, ETH transfers, or value-related assertions
    profitability_hints = []
    for result in test_results:
        logs = result.get("decoded_logs", [])
        for log in logs:
            if any(kw in log.lower() for kw in ["balance", "profit", "stolen", "eth", "wei"]):
                profitability_hints.append(log)

    if profitability_hints:
        signals["profitability"] = {
            "detected": True,
            "hints": profitability_hints
        }
    else:
        signals["profitability"] = {"detected": False, "hints": []}

    # Signal 2: Execution traces
    for result in test_results:
        if result.get("trace"):
            signals["execution_traces"].append({
                "test": result["test_name"],
                "trace_summary": summarize_trace(result["trace"])
            })

    # Signal 3: Revert reasons
    for result in failed_tests:
        reason = result.get("reason")
        if reason:
            signals["revert_reasons"].append({
                "test": result["test_name"],
                "reason": reason
            })

    # Fuzz statistics from stderr
    fuzz_stats = parse_fuzz_statistics(stderr_text)
    if fuzz_stats:
        signals["fuzz_statistics"] = fuzz_stats

    # Summary
    total = len(test_results)
    passed = sum(1 for r in test_results if r.get("status") == "PASS")
    failed = total - passed
    signals["summary"] = f"{total} tests: {passed} passed, {failed} failed"

    return signals


def summarize_trace(trace_data) -> str:
    """Summarize execution trace into readable format."""
    if isinstance(trace_data, str):
        return trace_data[:500]
    if isinstance(trace_data, list):
        return f"{len(trace_data)} trace entries"
    return str(trace_data)[:500]


def parse_fuzz_statistics(stderr_text: str) -> dict:
    """Extract fuzz run statistics from stderr."""
    stats = {}

    # Pattern: "Fuzz runs: 256"
    runs_match = re.search(r'fuzz runs[:\s]+(\d+)', stderr_text, re.IGNORECASE)
    if runs_match:
        stats["runs"] = int(runs_match.group(1))

    # Pattern: "Seed: 12345"
    seed_match = re.search(r'seed[:\s]+(\d+)', stderr_text, re.IGNORECASE)
    if seed_match:
        stats["seed"] = int(seed_match.group(1))

    # Pattern: "Max test rejects: 65536"
    rejects_match = re.search(r'max test rejects[:\s]+(\d+)', stderr_text, re.IGNORECASE)
    if rejects_match:
        stats["max_rejects"] = int(rejects_match.group(1))

    return stats


async def execute_tool(tool_name: str, arguments: dict) -> dict:
    if tool_name == "run_fuzz_test":
        contract_code = arguments.get("contract_code", "")
        test_code = arguments.get("test_code", "")
        timeout = arguments.get("timeout", 300)

        if not contract_code:
            return {"success": False, "error": "contract_code is required"}
        if not test_code:
            return {"success": False, "error": "test_code is required"}

        return await run_foundry_fuzz(contract_code, test_code, timeout)

    return {"success": False, "error": f"Unknown tool: {tool_name}"}


async def handle_request(request: dict) -> dict:
    method = request.get("method")
    params = request.get("params", {})

    if method == "initialize":
        return {
            "protocolVersion": "2024-11-05",
            "capabilities": {"tools": {}},
            "serverInfo": {"name": TOOL_NAME, "version": TOOL_VERSION}
        }
    elif method == "tools/list":
        return {"tools": build_tool_definitions()}
    elif method == "tools/call":
        tool_name = params.get("name")
        arguments = params.get("arguments", {})
        result = await execute_tool(tool_name, arguments)
        return {"content": [{"type": "text", "text": json.dumps(result, indent=2)}]}
    elif method == "ping":
        return {}
    return {"error": {"code": -32601, "message": f"Method not found: {method}"}}


async def main():
    reader = asyncio.StreamReader()
    protocol = asyncio.StreamReaderProtocol(reader)
    loop = asyncio.get_event_loop()
    await loop.connect_read_pipe(lambda: protocol, sys.stdin)

    logger.info(f"{TOOL_NAME} MCP server started")

    while True:
        line = await reader.readline()
        if not line:
            break

        line_str = line.decode("utf-8").strip()
        if not line_str:
            continue

        try:
            request = json.loads(line_str)
            response = await handle_request(request)
            response["jsonrpc"] = "2.0"
            response["id"] = request.get("id")
            sys.stdout.write(json.dumps(response) + "\n")
            sys.stdout.flush()
        except json.JSONDecodeError:
            error_resp = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {"code": -32700, "message": "Parse error"}
            }
            sys.stdout.write(json.dumps(error_resp) + "\n")
            sys.stdout.flush()
        except Exception as e:
            logger.exception("Error handling request")
            error_resp = {
                "jsonrpc": "2.0",
                "id": request.get("id") if "request" in dir() else None,
                "error": {"code": -32603, "message": f"Internal error: {str(e)}"}
            }
            sys.stdout.write(json.dumps(error_resp) + "\n")
            sys.stdout.flush()


if __name__ == "__main__":
    asyncio.run(main())
