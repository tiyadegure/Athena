#!/usr/bin/env python3
"""
MCP Server: Protocol Scanner
Auto-discovers all Solidity files in a directory, analyzes call graphs,
and identifies cross-contract attack surfaces.
"""
import sys
import json
import asyncio
import os
import re
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("protocol_scanner")

TOOL_NAME = "protocol_scanner"
TOOL_VERSION = "1.0.0"


def build_tool_definitions() -> list:
    return [
        {
            "name": "scan_protocol",
            "description": "Scan a directory of Solidity files to discover contracts and analyze their relationships",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "directory": {
                        "type": "string",
                        "description": "Path to directory containing .sol files"
                    },
                    "exclude_patterns": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Patterns to exclude (e.g., ['test/', 'mock/'])",
                        "default": ["test/", "mock/", "node_modules/"]
                    }
                },
                "required": ["directory"]
            }
        },
        {
            "name": "analyze_call_graph",
            "description": "Analyze contract call relationships and identify attack surfaces",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "contracts": {
                        "type": "array",
                        "items": {"type": "object"},
                        "description": "Contract data from scan_protocol"
                    }
                },
                "required": ["contracts"]
            }
        },
        {
            "name": "find_cross_contract_vulnerabilities",
            "description": "Identify potential cross-contract vulnerabilities",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "contracts": {
                        "type": "array",
                        "items": {"type": "object"},
                        "description": "Contract data from scan_protocol"
                    },
                    "call_graph": {
                        "type": "object",
                        "description": "Call graph from analyze_call_graph"
                    }
                },
                "required": ["contracts"]
            }
        }
    ]


async def scan_protocol(directory: str, exclude_patterns: list = None) -> dict:
    """Scan directory for Solidity files and analyze contracts."""
    if exclude_patterns is None:
        exclude_patterns = ["test/", "mock/", "node_modules/", ".git/"]
    
    directory = os.path.abspath(directory)
    
    if not os.path.isdir(directory):
        return {"success": False, "error": f"Directory not found: {directory}"}
    
    # Find all .sol files
    sol_files = []
    for root, dirs, files in os.walk(directory):
        # Skip excluded directories
        skip = False
        for pattern in exclude_patterns:
            if pattern in root:
                skip = True
                break
        if skip:
            continue
        
        for file in files:
            if file.endswith(".sol"):
                sol_files.append(os.path.join(root, file))
    
    # Analyze each file
    contracts = []
    for sol_file in sol_files:
        try:
            with open(sol_file, 'r') as f:
                content = f.read()
            
            # Extract contract info
            file_contracts = _extract_contracts(content, sol_file)
            contracts.extend(file_contracts)
        except Exception as e:
            logger.warning(f"Failed to read {sol_file}: {e}")
    
    return {
        "success": True,
        "directory": directory,
        "total_files": len(sol_files),
        "total_contracts": len(contracts),
        "contracts": contracts,
        "files": [os.path.relpath(f, directory) for f in sol_files]
    }


def _extract_contracts(content: str, filepath: str) -> list:
    """Extract contract information from Solidity source."""
    contracts = []
    
    # Find contract declarations
    contract_pattern = r'contract\s+(\w+)(?:\s+is\s+([^{]+))?\s*\{'
    for match in re.finditer(contract_pattern, content):
        name = match.group(1)
        inherits = match.group(2).strip() if match.group(2) else ""
        inherit_list = [i.strip() for i in inherits.split(",")] if inherits else []
        
        # Find contract body (simplified - doesn't handle nested braces perfectly)
        start_pos = match.end()
        brace_count = 1
        pos = start_pos
        while pos < len(content) and brace_count > 0:
            if content[pos] == '{':
                brace_count += 1
            elif content[pos] == '}':
                brace_count -= 1
            pos += 1
        body = content[start_pos:pos-1]
        
        # Extract functions
        functions = _extract_functions(body)
        
        # Extract imports
        imports = re.findall(r'import\s+.*?from\s+["\'](.+?)["\']', content)
        import_pattern = r'import\s+["\'](.+?)["\']'
        imports.extend(re.findall(import_pattern, content))
        
        # Extract state variables
        state_vars = _extract_state_variables(body)
        
        # Check for external calls
        external_calls = re.findall(r'\.call\{|\.call\.value\(|\.delegatecall\(|\.staticcall\(', body)
        
        # Check for modifiers
        modifiers = re.findall(r'modifier\s+(\w+)', body)
        
        contracts.append({
            "name": name,
            "file": filepath,
            "inherits": inherit_list,
            "functions": functions,
            "state_variables": state_vars,
            "external_calls": len(external_calls),
            "modifiers": modifiers,
            "imports": imports
        })
    
    return contracts


def _extract_functions(body: str) -> list:
    """Extract function information from contract body."""
    functions = []
    
    # Function pattern
    func_pattern = r'function\s+(\w+)\s*\(([^)]*)\)(?:\s+(?:public|private|internal|external|view|pure|payable|nonpayable|virtual|override))*\s*(?:returns\s*\(([^)]*)\))?\s*\{?'
    
    for match in re.finditer(func_pattern, body):
        name = match.group(1)
        params = match.group(2)
        returns = match.group(3) or ""
        
        # Determine visibility
        func_text = match.group(0)
        visibility = "internal"
        if "public" in func_text:
            visibility = "public"
        elif "external" in func_text:
            visibility = "external"
        elif "private" in func_text:
            visibility = "private"
        
        # Check for payable
        payable = "payable" in func_text
        
        # Check for modifiers (simplified)
        modifiers = []
        
        functions.append({
            "name": name,
            "visibility": visibility,
            "payable": payable,
            "params": params.strip(),
            "returns": returns.strip(),
            "modifiers": modifiers
        })
    
    return functions


def _extract_state_variables(body: str) -> list:
    """Extract state variable declarations."""
    variables = []
    
    # Simple pattern for state variables
    var_pattern = r'(?:uint256|uint|address|bool|string|bytes32|mapping)\s+(?:public|private|internal)?\s*(\w+)'
    
    for match in re.finditer(var_pattern, body):
        variables.append(match.group(1))
    
    return variables


async def analyze_call_graph(contracts: list) -> dict:
    """Analyze call relationships between contracts."""
    # Build contract name to info mapping
    contract_map = {c["name"]: c for c in contracts}
    
    # Build call graph
    call_graph = {}
    cross_calls = []
    
    for contract in contracts:
        contract_calls = []
        
        # Check for calls to other contracts
        for func in contract.get("functions", []):
            # Look for external contract calls in function params/returns
            params = func.get("params", "")
            for other_name in contract_map:
                if other_name != contract["name"]:
                    if other_name.lower() in params.lower():
                        contract_calls.append({
                            "caller": contract["name"],
                            "callee": other_name,
                            "function": func["name"],
                            "type": "parameter"
                        })
        
        # Check imports for dependencies
        for imp in contract.get("imports", []):
            for other in contracts:
                if other["name"] in imp or other["file"] in imp:
                    contract_calls.append({
                        "caller": contract["name"],
                        "callee": other["name"],
                        "function": "import",
                        "type": "dependency"
                    })
        
        if contract_calls:
            call_graph[contract["name"]] = contract_calls
            cross_calls.extend(contract_calls)
    
    # Identify attack surface
    attack_surface = []
    for contract in contracts:
        if contract.get("external_calls", 0) > 0:
            attack_surface.append({
                "contract": contract["name"],
                "external_calls": contract["external_calls"],
                "risk": "high" if contract["external_calls"] > 2 else "medium"
            })
    
    return {
        "success": True,
        "call_graph": call_graph,
        "cross_calls": cross_calls,
        "attack_surface": attack_surface,
        "total_cross_calls": len(cross_calls)
    }


async def find_cross_contract_vulnerabilities(contracts: list, call_graph: dict = None) -> dict:
    """Identify potential cross-contract vulnerabilities."""
    vulnerabilities = []
    
    # Check for oracle dependency
    for contract in contracts:
        for func in contract.get("functions", []):
            if "price" in func["name"].lower() or "oracle" in func["name"].lower():
                vulnerabilities.append({
                    "type": "oracle_dependency",
                    "contract": contract["name"],
                    "function": func["name"],
                    "risk": "high",
                    "description": f"{contract['name']}.{func['name']} depends on external oracle"
                })
    
    # Check for reentrancy vectors
    for contract in contracts:
        if contract.get("external_calls", 0) > 0:
            # Check if state is updated after external call
            has_state_update = False
            for var in contract.get("state_variables", []):
                if "balance" in var.lower() or "amount" in var.lower():
                    has_state_update = True
                    break
            
            if has_state_update:
                vulnerabilities.append({
                    "type": "potential_reentrancy",
                    "contract": contract["name"],
                    "risk": "high",
                    "description": f"{contract['name']} has external calls and state variables"
                })
    
    # Check for access control issues
    for contract in contracts:
        public_funcs = [f for f in contract.get("functions", []) if f["visibility"] == "public"]
        admin_funcs = [f for f in public_funcs if "admin" in f["name"].lower() or "owner" in f["name"].lower()]
        
        if admin_funcs:
            # Check for onlyOwner modifier
            has_modifier = any("onlyOwner" in str(f.get("modifiers", [])) or "onlyAdmin" in str(f.get("modifiers", [])) for f in admin_funcs)
            if not has_modifier:
                vulnerabilities.append({
                    "type": "missing_access_control",
                    "contract": contract["name"],
                    "functions": [f["name"] for f in admin_funcs],
                    "risk": "critical",
                    "description": f"Admin functions without access control in {contract['name']}"
                })
    
    # Check for cross-contract call chains
    if call_graph:
        for caller, calls in call_graph.items():
            for call in calls:
                if call.get("type") == "parameter":
                    vulnerabilities.append({
                        "type": "cross_contract_call",
                        "caller": caller,
                        "callee": call.get("callee"),
                        "function": call.get("function"),
                        "risk": "medium",
                        "description": f"Cross-contract call from {caller} to {call.get('callee')}"
                    })
    
    return {
        "success": True,
        "vulnerabilities": vulnerabilities,
        "total_vulnerabilities": len(vulnerabilities),
        "by_risk": {
            "critical": len([v for v in vulnerabilities if v["risk"] == "critical"]),
            "high": len([v for v in vulnerabilities if v["risk"] == "high"]),
            "medium": len([v for v in vulnerabilities if v["risk"] == "medium"]),
            "low": len([v for v in vulnerabilities if v["risk"] == "low"])
        }
    }


async def execute_tool(tool_name: str, arguments: dict) -> dict:
    if tool_name == "scan_protocol":
        return await scan_protocol(
            arguments.get("directory", ""),
            arguments.get("exclude_patterns")
        )
    elif tool_name == "analyze_call_graph":
        return await analyze_call_graph(arguments.get("contracts", []))
    elif tool_name == "find_cross_contract_vulnerabilities":
        return await find_cross_contract_vulnerabilities(
            arguments.get("contracts", []),
            arguments.get("call_graph")
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
