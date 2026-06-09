#!/usr/bin/env python3
"""
MCP Server: Incremental Auditor
Detects code changes and audits only the diff, reusing previous audit context.
Demonstrates GLM-5.1's 200K context window for long-horizon tasks.
"""
import sys
import json
import asyncio
import hashlib
import logging
import difflib

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("incremental_auditor")

TOOL_NAME = "incremental_auditor"
TOOL_VERSION = "1.0.0"


def build_tool_definitions() -> list:
    return [
        {
            "name": "detect_changes",
            "description": "Detect changes between old and new contract versions",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "old_code": {"type": "string", "description": "Original contract code"},
                    "new_code": {"type": "string", "description": "Updated contract code"},
                    "contract_name": {"type": "string", "description": "Contract name"}
                },
                "required": ["old_code", "new_code"]
            }
        },
        {
            "name": "generate_incremental_report",
            "description": "Generate incremental audit report based on changes",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "contract_name": {"type": "string"},
                    "old_code": {"type": "string"},
                    "new_code": {"type": "string"},
                    "previous_findings": {
                        "type": "array",
                        "items": {"type": "object"},
                        "description": "Findings from previous audit"
                    }
                },
                "required": ["contract_name", "old_code", "new_code"]
            }
        },
        {
            "name": "build_audit_context",
            "description": "Build audit context for 200K context window utilization",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "contracts": {
                        "type": "array",
                        "items": {"type": "object"},
                        "description": "All contracts in the protocol"
                    },
                    "previous_audits": {
                        "type": "array",
                        "items": {"type": "object"},
                        "description": "Previous audit results"
                    }
                },
                "required": ["contracts"]
            }
        }
    ]


async def detect_changes(old_code: str, new_code: str, contract_name: str = None) -> dict:
    """Detect changes between old and new contract versions."""
    
    old_lines = old_code.splitlines()
    new_lines = new_code.splitlines()
    
    # Generate diff
    diff = list(difflib.unified_diff(old_lines, new_lines, lineterm='', n=3))
    
    # Analyze changes
    added_lines = []
    removed_lines = []
    changed_functions = []
    
    for line in diff:
        if line.startswith('+') and not line.startswith('+++'):
            added_lines.append(line[1:])
        elif line.startswith('-') and not line.startswith('---'):
            removed_lines.append(line[1:])
    
    # Detect changed functions
    old_functions = _extract_functions(old_code)
    new_functions = _extract_functions(new_code)
    
    for func_name in set(old_functions.keys()) | set(new_functions.keys()):
        old_func = old_functions.get(func_name)
        new_func = new_functions.get(func_name)
        
        if old_func and new_func:
            if old_func != new_func:
                changed_functions.append({
                    "name": func_name,
                    "change_type": "modified",
                    "old_hash": hashlib.sha256(old_func.encode()).hexdigest()[:16],
                    "new_hash": hashlib.sha256(new_func.encode()).hexdigest()[:16]
                })
        elif new_func and not old_func:
            changed_functions.append({
                "name": func_name,
                "change_type": "added"
            })
        elif old_func and not new_func:
            changed_functions.append({
                "name": func_name,
                "change_type": "removed"
            })
    
    # Calculate change magnitude
    total_lines = max(len(old_lines), len(new_lines))
    changed_lines = len(added_lines) + len(removed_lines)
    change_percentage = (changed_lines / total_lines * 100) if total_lines > 0 else 0
    
    return {
        "success": True,
        "contract_name": contract_name,
        "summary": {
            "old_lines": len(old_lines),
            "new_lines": len(new_lines),
            "added_lines": len(added_lines),
            "removed_lines": len(removed_lines),
            "change_percentage": round(change_percentage, 2)
        },
        "changed_functions": changed_functions,
        "diff": diff[:100],  # First 100 lines of diff
        "affected_areas": _identify_affected_areas(changed_functions)
    }


def _extract_functions(code: str) -> dict:
    """Extract function bodies from code."""
    functions = {}
    
    import re
    pattern = r'function\s+(\w+)\s*\([^)]*\)[^{]*\{'
    
    for match in re.finditer(pattern, code):
        func_name = match.group(1)
        start_pos = match.end()
        
        # Find function end (simplified)
        brace_count = 1
        pos = start_pos
        while pos < len(code) and brace_count > 0:
            if code[pos] == '{':
                brace_count += 1
            elif code[pos] == '}':
                brace_count -= 1
            pos += 1
        
        functions[func_name] = code[match.start():pos]
    
    return functions


def _identify_affected_areas(changed_functions: list) -> list:
    """Identify which areas of the contract are affected."""
    areas = set()
    
    for func in changed_functions:
        name = func["name"].lower()
        
        if "deposit" in name or "withdraw" in name or "transfer" in name:
            areas.add("token_operations")
        if "borrow" in name or "repay" in name or "liquidat" in name:
            areas.add("lending")
        if "swap" in name or "addliquidity" in name or "removeliquidity" in name:
            areas.add("amm")
        if "vote" in name or "propose" in name or "execute" in name:
            areas.add("governance")
        if "oracle" in name or "price" in name:
            areas.add("oracle")
        if "admin" in name or "owner" in name or "set" in name:
            areas.add("admin")
    
    return list(areas)


async def generate_incremental_report(contract_name: str, old_code: str, new_code: str, previous_findings: list = None) -> dict:
    """Generate incremental audit report."""
    
    changes = await detect_changes(old_code, new_code, contract_name)
    
    if previous_findings is None:
        previous_findings = []
    
    # Determine what needs re-auditing
    affected_areas = changes.get("affected_areas", [])
    changed_functions = changes.get("changed_functions", [])
    
    # Filter previous findings that might be affected
    potentially_affected = []
    for finding in previous_findings:
        finding_func = finding.get("function", "").lower()
        for func in changed_functions:
            if func["name"].lower() in finding_func or finding_func in func["name"].lower():
                potentially_affected.append(finding)
                break
    
    # Generate report
    report = f"""# Incremental Audit Report

## Contract: {contract_name}

---

## Change Summary

| Metric | Value |
|--------|-------|
| Old Lines | {changes['summary']['old_lines']} |
| New Lines | {changes['summary']['new_lines']} |
| Added Lines | {changes['summary']['added_lines']} |
| Removed Lines | {changes['summary']['removed_lines']} |
| Change % | {changes['summary']['change_percentage']}% |

---

## Changed Functions

| Function | Change Type |
|----------|-------------|
"""
    
    for func in changed_functions:
        report += f"| {func['name']} | {func['change_type']} |\n"
    
    report += f"""
---

## Affected Areas

{', '.join(affected_areas) if affected_areas else 'None identified'}

---

## Previous Findings Affected

{len(potentially_affected)} findings may be affected by changes:
"""
    
    for finding in potentially_affected:
        report += f"- {finding.get('type', 'unknown')} in {finding.get('function', '?')}\n"
    
    report += """
---

## Recommended Actions

1. Re-audit changed functions
2. Verify fixes don't introduce new issues
3. Run fuzz tests on affected areas
4. Update audit report with incremental findings
"""
    
    return {
        "success": True,
        "report": report,
        "changes": changes,
        "affected_findings": potentially_affected,
        "requires_reaudit": len(changed_functions) > 0
    }


async def build_audit_context(contracts: list, previous_audits: list = None) -> dict:
    """Build audit context for 200K context window."""
    
    if previous_audits is None:
        previous_audits = []
    
    # Build context structure
    context = {
        "protocol_overview": {
            "total_contracts": len(contracts),
            "contract_names": [c.get("name", "unknown") for c in contracts]
        },
        "contract_details": [],
        "audit_history": previous_audits,
        "known_vulnerabilities": [],
        "architecture_notes": []
    }
    
    # Add contract details
    total_lines = 0
    for contract in contracts:
        code = contract.get("code", "")
        lines = code.count('\n') + 1
        total_lines += lines
        
        context["contract_details"].append({
            "name": contract.get("name", "unknown"),
            "lines": lines,
            "functions": len(contract.get("functions", [])),
            "imports": contract.get("imports", [])
        })
    
    # Estimate context usage
    # Rough estimate: 1 token ≈ 4 characters
    total_chars = sum(len(c.get("code", "")) for c in contracts)
    estimated_tokens = total_chars // 4
    
    context["context_stats"] = {
        "total_lines": total_lines,
        "estimated_tokens": estimated_tokens,
        "context_window": 200000,
        "utilization": f"{(estimated_tokens / 200000 * 100):.1f}%"
    }
    
    # Add known vulnerabilities from previous audits
    for audit in previous_audits:
        for finding in audit.get("findings", []):
            context["known_vulnerabilities"].append({
                "contract": finding.get("contract"),
                "type": finding.get("type"),
                "severity": finding.get("severity"),
                "status": finding.get("status", "open")
            })
    
    return {
        "success": True,
        "context": context,
        "recommendation": _get_context_recommendation(estimated_tokens)
    }


def _get_context_recommendation(estimated_tokens: int) -> str:
    """Get recommendation based on context utilization."""
    if estimated_tokens < 50000:
        return "Full protocol audit in single context - ideal"
    elif estimated_tokens < 100000:
        return "Protocol fits in context with room for analysis"
    elif estimated_tokens < 150000:
        return "Protocol requires most of context - prioritize critical contracts"
    else:
        return "Protocol exceeds comfortable context - use incremental auditing"


async def execute_tool(tool_name: str, arguments: dict) -> dict:
    if tool_name == "detect_changes":
        return await detect_changes(
            arguments.get("old_code", ""),
            arguments.get("new_code", ""),
            arguments.get("contract_name")
        )
    elif tool_name == "generate_incremental_report":
        return await generate_incremental_report(
            arguments.get("contract_name", ""),
            arguments.get("old_code", ""),
            arguments.get("new_code", ""),
            arguments.get("previous_findings")
        )
    elif tool_name == "build_audit_context":
        return await build_audit_context(
            arguments.get("contracts", []),
            arguments.get("previous_audits")
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
