#!/usr/bin/env python3
"""
MCP Server: Slither Runner
Wraps Slither static analysis tool for Solidity smart contracts.
"""
import sys
import json
import asyncio
import tempfile
import subprocess
import logging
import os
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("slither_runner")

TOOL_NAME = "slither_runner"
TOOL_VERSION = "1.0.0"


def build_tool_definitions() -> list:
    return [
        {
            "name": "slither_analyze",
            "description": "Run Slither static analysis on a Solidity smart contract. Returns detected vulnerabilities with impact, confidence, and location details.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "contract_path": {
                        "type": "string",
                        "description": "Path to the Solidity contract file to analyze"
                    },
                    "detectors": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Optional list of specific Slither detector names to run (e.g., ['reentrancy-eth', 'unchecked-transfer']). If omitted, all detectors run."
                    }
                },
                "required": ["contract_path"]
            }
        }
    ]


async def run_slither(contract_path: str, detectors: list = None) -> dict:
    """Execute Slither and parse JSON output."""
    contract_path = os.path.abspath(contract_path)

    if not os.path.isfile(contract_path):
        return {"success": False, "error": f"Contract file not found: {contract_path}"}

    with tempfile.NamedTemporaryFile(suffix=".json", delete=False, mode="w") as tmp:
        json_output_path = tmp.name

    try:
        cmd = ["slither", contract_path, "--json", json_output_path]

        # Add specific detectors if provided
        if detectors:
            for detector in detectors:
                cmd.extend(["--detect", detector])

        logger.info(f"Running slither: {' '.join(cmd)}")

        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await proc.communicate()

        # Slither returns non-zero when it finds issues, which is expected
        if proc.returncode not in (0, 1, 2):
            return {
                "success": False,
                "error": f"Slither exited with code {proc.returncode}",
                "stderr": stderr.decode("utf-8", errors="replace").strip()
            }

        # Parse JSON output
        if not os.path.isfile(json_output_path):
            return {
                "success": False,
                "error": "Slither did not produce JSON output",
                "stderr": stderr.decode("utf-8", errors="replace").strip()
            }

        with open(json_output_path, "r") as f:
            raw_output = json.load(f)

        # Extract and normalize findings
        findings = []
        for detector_result in raw_output.get("results", {}).get("detectors", []):
            finding = {
                "check": detector_result.get("check", "unknown"),
                "impact": detector_result.get("impact", "Unknown"),
                "confidence": detector_result.get("confidence", "Unknown"),
                "description": detector_result.get("description", ""),
                "elements": []
            }

            # Extract source locations
            for element in detector_result.get("elements", []):
                source = element.get("source_mapping", {})
                elem_info = {
                    "type": element.get("type", ""),
                    "name": element.get("name", ""),
                    "file": source.get("filename_relative", ""),
                    "lines": source.get("lines", []),
                    "start": source.get("start", 0),
                    "length": source.get("length", 0)
                }
                finding["elements"].append(elem_info)

            findings.append(finding)

        return {
            "success": True,
            "contract": contract_path,
            "findings_count": len(findings),
            "findings": findings,
            "slither_version": raw_output.get("meta", {}).get("slither_version", "unknown"),
            "compiler": raw_output.get("meta", {}).get("solc_version", "unknown")
        }

    except FileNotFoundError:
        return {"success": False, "error": "Slither not found. Install with: pip3 install slither-analyzer"}
    except json.JSONDecodeError as e:
        return {"success": False, "error": f"Failed to parse Slither JSON output: {str(e)}"}
    except Exception as e:
        logger.exception("Unexpected error in slither_runner")
        return {"success": False, "error": f"Unexpected error: {str(e)}"}
    finally:
        if os.path.exists(json_output_path):
            os.unlink(json_output_path)


async def execute_tool(tool_name: str, arguments: dict) -> dict:
    if tool_name == "slither_analyze":
        contract_path = arguments.get("contract_path", "")
        detectors = arguments.get("detectors", None)
        return await run_slither(contract_path, detectors)
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
