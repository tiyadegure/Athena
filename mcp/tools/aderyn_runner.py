#!/usr/bin/env python3
"""
MCP Server: Aderyn Runner
Wraps Aderyn (Rust-based) static analysis for Solidity smart contracts.
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
logger = logging.getLogger("aderyn_runner")

TOOL_NAME = "aderyn_runner"
TOOL_VERSION = "1.0.0"


def build_tool_definitions() -> list:
    return [
        {
            "name": "aderyn_analyze",
            "description": "Run Aderyn static analysis on a Solidity project. Returns findings grouped by severity (high, low, informational, optimization).",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "project_path": {
                        "type": "string",
                        "description": "Path to the Solidity project root directory (must contain foundry.toml or hardhat.config)"
                    }
                },
                "required": ["project_path"]
            }
        }
    ]


async def run_aderyn(project_path: str) -> dict:
    """Execute Aderyn and parse JSON output."""
    project_path = os.path.abspath(project_path)

    if not os.path.isdir(project_path):
        return {"success": False, "error": f"Project directory not found: {project_path}"}

    tmp_dir = tempfile.mkdtemp()
    json_output_path = os.path.join(tmp_dir, "report.json")

    try:
        cmd = ["aderyn", project_path, "--output", json_output_path]

        logger.info(f"Running aderyn: {' '.join(cmd)}")

        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await proc.communicate()

        if proc.returncode != 0:
            return {
                "success": False,
                "error": f"Aderyn exited with code {proc.returncode}",
                "stderr": stderr.decode("utf-8", errors="replace").strip()
            }

        # Parse JSON output
        if not os.path.isfile(json_output_path):
            # Aderyn may output with a different name
            possible_names = ["report.json", "aderyn-report.json", "output.json"]
            for name in possible_names:
                alt_path = os.path.join(tmp_dir, name)
                if os.path.isfile(alt_path):
                    json_output_path = alt_path
                    break
            else:
                return {
                    "success": False,
                    "error": "Aderyn did not produce JSON output",
                    "stderr": stderr.decode("utf-8", errors="replace").strip(),
                    "stdout": stdout.decode("utf-8", errors="replace").strip()
                }

        with open(json_output_path, "r") as f:
            raw_output = json.load(f)

        # Normalize Aderyn output structure
        # Aderyn groups issues by severity
        def extract_issues(issue_list):
            issues = []
            for issue in (issue_list or []):
                issues.append({
                    "title": issue.get("title", ""),
                    "description": issue.get("description", ""),
                    "detector_name": issue.get("detector_name", ""),
                    "severity": issue.get("severity", ""),
                    "instances": [
                        {
                            "contract_path": inst.get("contract_path", ""),
                            "line_no": inst.get("line_no", 0),
                            "src": inst.get("src", ""),
                            "code_snippet": inst.get("code_snippet", "")
                        }
                        for inst in issue.get("instances", [])
                    ],
                    "instance_count": len(issue.get("instances", []))
                })
            return issues

        high_issues = extract_issues(raw_output.get("high_issues", {}).get("issues", []))
        low_issues = extract_issues(raw_output.get("low_issues", {}).get("issues", []))
        informational_issues = extract_issues(raw_output.get("informational_issues", {}).get("issues", []))
        optimization_issues = extract_issues(raw_output.get("optimization_issues", {}).get("issues", []))

        total_issues = (
            len(high_issues) + len(low_issues) +
            len(informational_issues) + len(optimization_issues)
        )

        return {
            "success": True,
            "project": project_path,
            "summary": {
                "total_issues": total_issues,
                "high_severity": len(high_issues),
                "low_severity": len(low_issues),
                "informational": len(informational_issues),
                "optimization": len(optimization_issues)
            },
            "high_issues": high_issues,
            "low_issues": low_issues,
            "informational_issues": informational_issues,
            "optimization_issues": optimization_issues
        }

    except FileNotFoundError:
        return {"success": False, "error": "Aderyn not found. Install with: cargo install aderyn"}
    except json.JSONDecodeError as e:
        return {"success": False, "error": f"Failed to parse Aderyn JSON output: {str(e)}"}
    except Exception as e:
        logger.exception("Unexpected error in aderyn_runner")
        return {"success": False, "error": f"Unexpected error: {str(e)}"}
    finally:
        # Cleanup temp dir
        import shutil
        if os.path.exists(tmp_dir):
            shutil.rmtree(tmp_dir, ignore_errors=True)


async def execute_tool(tool_name: str, arguments: dict) -> dict:
    if tool_name == "aderyn_analyze":
        project_path = arguments.get("project_path", "")
        return await run_aderyn(project_path)
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
