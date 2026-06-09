#!/usr/bin/env python3
"""
MCP Server: Audit Evidence Chain
Manages Merkle-based audit evidence chain for verifiable audit steps.
"""
import sys
import json
import asyncio
import hashlib
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("evidence_chain")

TOOL_NAME = "evidence_chain"
TOOL_VERSION = "1.0.0"


def build_tool_definitions() -> list:
    return [
        {
            "name": "create_audit_chain",
            "description": "Create a new audit evidence chain for tracking audit steps",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "audit_id": {"type": "string", "description": "Unique audit identifier"},
                    "contract_name": {"type": "string", "description": "Name of contract being audited"},
                    "auditor": {"type": "string", "description": "Auditor address or identifier"}
                },
                "required": ["audit_id", "contract_name"]
            }
        },
        {
            "name": "record_audit_step",
            "description": "Record a step in the audit evidence chain",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "audit_id": {"type": "string", "description": "Audit identifier"},
                    "step_number": {"type": "integer", "enum": [1,2,3,4,5,6,7,8], "description": "Step number (1-8)"},
                    "step_name": {"type": "string", "description": "Step name (scope, slither, aderyn, poc, fuzz, fix, report, certificate)"},
                    "input_data": {"type": "string", "description": "Input data (will be hashed)"},
                    "output_data": {"type": "string", "description": "Output data (will be hashed)"}
                },
                "required": ["audit_id", "step_number", "step_name", "input_data", "output_data"]
            }
        },
        {
            "name": "calculate_merkle_root",
            "description": "Calculate Merkle root from all recorded steps",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "audit_id": {"type": "string", "description": "Audit identifier"}
                },
                "required": ["audit_id"]
            }
        },
        {
            "name": "verify_step",
            "description": "Verify a step is in the audit evidence chain",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "audit_id": {"type": "string", "description": "Audit identifier"},
                    "step_number": {"type": "integer", "description": "Step number to verify"},
                    "proof": {"type": "array", "items": {"type": "string"}, "description": "Merkle proof (hex strings)"}
                },
                "required": ["audit_id", "step_number", "proof"]
            }
        },
        {
            "name": "get_audit_summary",
            "description": "Get summary of all steps in an audit chain",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "audit_id": {"type": "string", "description": "Audit identifier"}
                },
                "required": ["audit_id"]
            }
        }
    ]


# In-memory storage (in production, use database or on-chain)
audit_chains = {}


async def create_audit_chain(audit_id: str, contract_name: str, auditor: str = None) -> dict:
    """Create a new audit evidence chain."""
    if audit_id in audit_chains:
        return {"success": False, "error": "Audit ID already exists"}
    
    audit_chains[audit_id] = {
        "audit_id": audit_id,
        "contract_name": contract_name,
        "auditor": auditor or "unknown",
        "steps": {},
        "merkle_root": None,
        "created_at": asyncio.get_event_loop().time()
    }
    
    return {
        "success": True,
        "audit_id": audit_id,
        "contract_name": contract_name,
        "message": "Audit chain created"
    }


async def record_audit_step(audit_id: str, step_number: int, step_name: str, input_data: str, output_data: str) -> dict:
    """Record a step in the audit evidence chain."""
    if audit_id not in audit_chains:
        return {"success": False, "error": "Audit ID not found"}
    
    if step_number < 1 or step_number > 8:
        return {"success": False, "error": "Step number must be 1-8"}
    
    # Calculate hashes
    input_hash = hashlib.sha256(input_data.encode()).hexdigest()
    output_hash = hashlib.sha256(output_data.encode()).hexdigest()
    
    # Store step
    audit_chains[audit_id]["steps"][step_number] = {
        "step_number": step_number,
        "step_name": step_name,
        "input_hash": input_hash,
        "output_hash": output_hash,
        "timestamp": asyncio.get_event_loop().time()
    }
    
    return {
        "success": True,
        "audit_id": audit_id,
        "step_number": step_number,
        "step_name": step_name,
        "input_hash": input_hash,
        "output_hash": output_hash,
        "total_steps": len(audit_chains[audit_id]["steps"])
    }


async def calculate_merkle_root(audit_id: str) -> dict:
    """Calculate Merkle root from all recorded steps."""
    if audit_id not in audit_chains:
        return {"success": False, "error": "Audit ID not found"}
    
    chain = audit_chains[audit_id]
    steps = chain["steps"]
    
    if not steps:
        return {"success": False, "error": "No steps recorded"}
    
    # Create leaf hashes
    leaves = []
    for step_num in sorted(steps.keys()):
        step = steps[step_num]
        leaf_data = f"{audit_id}:{step['step_number']}:{step['step_name']}:{step['input_hash']}:{step['output_hash']}:{step['timestamp']}"
        leaf_hash = hashlib.sha256(leaf_data.encode()).hexdigest()
        leaves.append(leaf_hash)
    
    # Calculate Merkle root
    merkle_root = _calculate_merkle_root(leaves)
    chain["merkle_root"] = merkle_root
    
    return {
        "success": True,
        "audit_id": audit_id,
        "merkle_root": merkle_root,
        "step_count": len(leaves),
        "leaves": leaves
    }


def _calculate_merkle_root(leaves: list) -> str:
    """Calculate Merkle root from list of leaf hashes."""
    if not leaves:
        return None
    if len(leaves) == 1:
        return leaves[0]
    
    # Build tree
    current_level = leaves
    while len(current_level) > 1:
        next_level = []
        for i in range(0, len(current_level), 2):
            if i + 1 < len(current_level):
                # Hash pair
                pair = current_level[i] + current_level[i + 1]
                next_level.append(hashlib.sha256(pair.encode()).hexdigest())
            else:
                # Odd leaf, promote
                next_level.append(current_level[i])
        current_level = next_level
    
    return current_level[0]


async def verify_step(audit_id: str, step_number: int, proof: list) -> dict:
    """Verify a step is in the audit evidence chain."""
    if audit_id not in audit_chains:
        return {"success": False, "error": "Audit ID not found"}
    
    chain = audit_chains[audit_id]
    
    if step_number not in chain["steps"]:
        return {"success": False, "error": "Step not found"}
    
    if not chain["merkle_root"]:
        return {"success": False, "error": "Merkle root not calculated"}
    
    # Calculate leaf hash
    step = chain["steps"][step_number]
    leaf_data = f"{audit_id}:{step['step_number']}:{step['step_name']}:{step['input_hash']}:{step['output_hash']}:{step['timestamp']}"
    leaf_hash = hashlib.sha256(leaf_data.encode()).hexdigest()
    
    # Verify proof
    computed_hash = leaf_hash
    for proof_element in proof:
        # Sort hashes for consistent ordering
        if computed_hash < proof_element:
            combined = computed_hash + proof_element
        else:
            combined = proof_element + computed_hash
        computed_hash = hashlib.sha256(combined.encode()).hexdigest()
    
    is_valid = computed_hash == chain["merkle_root"]
    
    return {
        "success": True,
        "audit_id": audit_id,
        "step_number": step_number,
        "is_valid": is_valid,
        "computed_root": computed_hash,
        "expected_root": chain["merkle_root"]
    }


async def get_audit_summary(audit_id: str) -> dict:
    """Get summary of all steps in an audit chain."""
    if audit_id not in audit_chains:
        return {"success": False, "error": "Audit ID not found"}
    
    chain = audit_chains[audit_id]
    
    steps_summary = []
    for step_num in sorted(chain["steps"].keys()):
        step = chain["steps"][step_num]
        steps_summary.append({
            "step_number": step["step_number"],
            "step_name": step["step_name"],
            "input_hash": step["input_hash"][:16] + "...",
            "output_hash": step["output_hash"][:16] + "..."
        })
    
    return {
        "success": True,
        "audit_id": audit_id,
        "contract_name": chain["contract_name"],
        "auditor": chain["auditor"],
        "total_steps": len(steps_summary),
        "merkle_root": chain["merkle_root"],
        "steps": steps_summary
    }


async def execute_tool(tool_name: str, arguments: dict) -> dict:
    if tool_name == "create_audit_chain":
        return await create_audit_chain(
            arguments.get("audit_id", ""),
            arguments.get("contract_name", ""),
            arguments.get("auditor")
        )
    elif tool_name == "record_audit_step":
        return await record_audit_step(
            arguments.get("audit_id", ""),
            arguments.get("step_number", 0),
            arguments.get("step_name", ""),
            arguments.get("input_data", ""),
            arguments.get("output_data", "")
        )
    elif tool_name == "calculate_merkle_root":
        return await calculate_merkle_root(arguments.get("audit_id", ""))
    elif tool_name == "verify_step":
        return await verify_step(
            arguments.get("audit_id", ""),
            arguments.get("step_number", 0),
            arguments.get("proof", [])
        )
    elif tool_name == "get_audit_summary":
        return await get_audit_summary(arguments.get("audit_id", ""))
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
