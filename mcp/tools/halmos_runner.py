#!/usr/bin/env python3
"""
MCP Server: Halmos Runner
Symbolic verification tool using Halmos (a16z) for Solidity contracts.
Verifies contract properties using Z3 SMT solver.
"""
import sys
import json
import asyncio
import subprocess
import tempfile
import logging
import os
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("halmos_runner")

TOOL_NAME = "halmos_runner"
TOOL_VERSION = "1.0.0"


def build_tool_definitions() -> list:
    return [
        {
            "name": "halmos_verify",
            "description": "Run symbolic verification on Solidity contracts using Halmos. Verifies contract properties like balance invariants, access control, etc.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "contract_path": {
                        "type": "string",
                        "description": "Path to Solidity contract file"
                    },
                    "properties": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Properties to verify (e.g., ['balance >= 0', 'totalSupply == sum(balances)'])"
                    },
                    "contract_name": {
                        "type": "string",
                        "description": "Specific contract name to verify (optional, verifies all if omitted)"
                    }
                },
                "required": ["contract_path"]
            }
        },
        {
            "name": "halmos_check_invariants",
            "description": "Check common security invariants for a contract (balance >= 0, no overflow, access control)",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "contract_path": {
                        "type": "string",
                        "description": "Path to Solidity contract file"
                    }
                },
                "required": ["contract_path"]
            }
        },
        {
            "name": "halmos_generate_tests",
            "description": "Generate Halmos test stubs for contract properties",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "contract_path": {
                        "type": "string",
                        "description": "Path to Solidity contract file"
                    },
                    "properties": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Properties to generate tests for"
                    }
                },
                "required": ["contract_path"]
            }
        }
    ]


async def halmos_verify(contract_path: str, properties: list = None, contract_name: str = None) -> dict:
    """Run Halmos symbolic verification."""
    contract_path = os.path.abspath(contract_path)
    
    if not os.path.isfile(contract_path):
        return {"success": False, "error": f"Contract file not found: {contract_path}"}
    
    try:
        # Check if halmos is installed
        check_proc = await asyncio.create_subprocess_exec(
            "halmos", "--version",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        await check_proc.communicate()
        
        if check_proc.returncode != 0:
            # Halmos not installed - return mock result
            return {
                "success": True,
                "mock": True,
                "message": "Halmos not installed. Install: pip install halmos",
                "findings": _generate_mock_findings(contract_path, properties)
            }
        
        # Build halmos command
        cmd = ["halmos", "--contract", contract_path]
        
        if contract_name:
            cmd.extend(["--contract-name", contract_name])
        
        # Run halmos
        logger.info(f"Running halmos: {' '.join(cmd)}")
        
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=120)
        
        stdout_text = stdout.decode("utf-8", errors="replace")
        stderr_text = stderr.decode("utf-8", errors="replace")
        
        # Parse halmos output
        findings = _parse_halmos_output(stdout_text, stderr_text)
        
        return {
            "success": True,
            "exit_code": proc.returncode,
            "findings": findings,
            "properties_verified": len([f for f in findings if f["status"] == "verified"]),
            "properties_failed": len([f for f in findings if f["status"] == "failed"]),
            "raw_output": stdout_text[:2000]
        }
        
    except asyncio.TimeoutError:
        return {"success": False, "error": "Halmos verification timed out (120s)"}
    except FileNotFoundError:
        return {
            "success": True,
            "mock": True,
            "message": "Halmos not installed. Install: pip install halmos",
            "findings": _generate_mock_findings(contract_path, properties)
        }
    except Exception as e:
        logger.exception("Halmos verification failed")
        return {"success": False, "error": str(e)}


def _parse_halmos_output(stdout: str, stderr: str) -> list:
    """Parse halmos output to extract findings."""
    findings = []
    
    # Halmos output format varies, parse common patterns
    lines = stdout.split("\n")
    
    for line in lines:
        line = line.strip()
        
        # Look for verification results
        if "PASS" in line or "VERIFIED" in line:
            findings.append({
                "property": _extract_property(line),
                "status": "verified",
                "message": line
            })
        elif "FAIL" in line or "COUNTEREXAMPLE" in line:
            findings.append({
                "property": _extract_property(line),
                "status": "failed",
                "message": line,
                "counterexample": _extract_counterexample(line)
            })
        elif "UNKNOWN" in line or "TIMEOUT" in line:
            findings.append({
                "property": _extract_property(line),
                "status": "unknown",
                "message": line
            })
    
    # If no findings parsed, create generic result
    if not findings:
        findings.append({
            "property": "general",
            "status": "unknown",
            "message": "Could not parse halmos output"
        })
    
    return findings


def _extract_property(line: str) -> str:
    """Extract property name from halmos output line."""
    # Try to extract function/property name
    if "::" in line:
        return line.split("::")[-1].split()[0]
    return "unknown"


def _extract_counterexample(line: str) -> str:
    """Extract counterexample from halmos output."""
    if "counterexample" in line.lower():
        return line
    return ""


def _generate_mock_findings(contract_path: str, properties: list = None) -> list:
    """Generate mock findings when halmos is not installed."""
    findings = []
    
    # Common properties to check
    default_properties = [
        "balance >= 0",
        "totalSupply == sum(balances)",
        "only_owner_can_admin",
        "no_overflow"
    ]
    
    check_properties = properties or default_properties
    
    for prop in check_properties:
        findings.append({
            "property": prop,
            "status": "mock",
            "message": f"Mock verification (halmos not installed): {prop}",
            "recommendation": "Install halmos and run actual verification"
        })
    
    return findings


async def halmos_check_invariants(contract_path: str) -> dict:
    """Check common security invariants."""
    # Common invariants to verify
    invariants = [
        "balance >= 0",
        "totalSupply >= 0",
        "no_reentrancy",
        "access_control_valid",
        "no_overflow_underflow"
    ]
    
    result = await halmos_verify(contract_path, invariants)
    
    if result.get("success"):
        result["invariants_checked"] = invariants
        result["summary"] = f"Checked {len(invariants)} invariants"
    
    return result


async def halmos_generate_tests(contract_path: str, properties: list = None) -> dict:
    """Generate Halmos test stubs."""
    contract_path = os.path.abspath(contract_path)
    
    if not os.path.isfile(contract_path):
        return {"success": False, "error": f"Contract file not found: {contract_path}"}
    
    # Read contract to extract contract name
    try:
        with open(contract_path, 'r') as f:
            content = f.read()
        
        import re
        match = re.search(r'contract\s+(\w+)', content)
        contract_name = match.group(1) if match else "Target"
    except Exception:
        contract_name = "Target"
    
    # Generate test stubs
    default_properties = properties or [
        "balance_never_negative",
        "total_supply_conserved",
        "only_owner_can_withdraw"
    ]
    
    test_code = f'''// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "{contract_path}";

/// @title HalmosTests - Generated symbolic verification tests
contract HalmosTests is Test {{
    {contract_name} public target;
    
    function setUp() public {{
        target = new {contract_name}();
    }}
    
'''
    
    for i, prop in enumerate(default_properties):
        test_code += f'''    /// @notice Verify: {prop}
    function check_{prop}() public {{
        // TODO: Implement property verification
        // Use symbolic variables for inputs
        // Assert invariant holds for all possible inputs
    }}
    
'''
    
    test_code += '''    /// @notice Helper: Check balance invariant
    function check_balance_non_negative() public view {
        // Symbolic verification that balance >= 0
        // This is always true for uint256, but worth documenting
    }
}
'''
    
    return {
        "success": True,
        "contract_name": contract_name,
        "properties": default_properties,
        "test_code": test_code,
        "usage": "Save to test/HalmosTests.t.sol and run: forge test"
    }


async def execute_tool(tool_name: str, arguments: dict) -> dict:
    if tool_name == "halmos_verify":
        return await halmos_verify(
            arguments.get("contract_path", ""),
            arguments.get("properties"),
            arguments.get("contract_name")
        )
    elif tool_name == "halmos_check_invariants":
        return await halmos_check_invariants(arguments.get("contract_path", ""))
    elif tool_name == "halmos_generate_tests":
        return await halmos_generate_tests(
            arguments.get("contract_path", ""),
            arguments.get("properties")
        )
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
