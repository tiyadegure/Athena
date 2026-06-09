#!/usr/bin/env python3
"""
MCP Server: Repair Validator
Multi-round repair verification: audit → fix → re-audit → compare.
"""
import sys
import json
import asyncio
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("repair_validator")

TOOL_NAME = "repair_validator"
TOOL_VERSION = "1.0.0"


def build_tool_definitions() -> list:
    return [
        {
            "name": "compare_audit_results",
            "description": "Compare before/after audit results to measure repair effectiveness",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "before_findings": {
                        "type": "array",
                        "items": {"type": "object"},
                        "description": "Findings from initial audit"
                    },
                    "after_findings": {
                        "type": "array",
                        "items": {"type": "object"},
                        "description": "Findings from re-audit after fix"
                    }
                },
                "required": ["before_findings", "after_findings"]
            }
        },
        {
            "name": "generate_repair_report",
            "description": "Generate a repair verification report",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "contract_name": {"type": "string"},
                    "before_findings": {
                        "type": "array",
                        "items": {"type": "object"}
                    },
                    "after_findings": {
                        "type": "array",
                        "items": {"type": "object"}
                    },
                    "fixes_applied": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "List of fixes applied"
                    }
                },
                "required": ["contract_name", "before_findings", "after_findings"]
            }
        },
        {
            "name": "suggest_fixes",
            "description": "Suggest fixes for audit findings",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "findings": {
                        "type": "array",
                        "items": {"type": "object"},
                        "description": "Audit findings to fix"
                    },
                    "contract_code": {
                        "type": "string",
                        "description": "Original contract code"
                    }
                },
                "required": ["findings"]
            }
        }
    ]


async def compare_audit_results(before_findings: list, after_findings: list) -> dict:
    """Compare before/after audit results."""
    
    # Categorize findings
    before_by_severity = _categorize_by_severity(before_findings)
    after_by_severity = _categorize_by_severity(after_findings)
    
    # Find fixed findings
    fixed = []
    for bf in before_findings:
        found_in_after = False
        for af in after_findings:
            if _findings_match(bf, af):
                found_in_after = True
                break
        if not found_in_after:
            fixed.append(bf)
    
    # Find new findings
    new = []
    for af in after_findings:
        found_in_before = False
        for bf in before_findings:
            if _findings_match(bf, af):
                found_in_before = True
                break
        if not found_in_before:
            new.append(af)
    
    # Find remaining findings
    remaining = []
    for af in after_findings:
        for bf in before_findings:
            if _findings_match(bf, af):
                remaining.append(af)
                break
    
    # Calculate metrics
    total_before = len(before_findings)
    total_after = len(after_findings)
    fixed_count = len(fixed)
    new_count = len(new)
    remaining_count = len(remaining)
    
    # Calculate severity reduction
    severity_reduction = {}
    for sev in ["critical", "high", "medium", "low"]:
        before_count = before_by_severity.get(sev, 0)
        after_count = after_by_severity.get(sev, 0)
        severity_reduction[sev] = {
            "before": before_count,
            "after": after_count,
            "reduced": before_count - after_count
        }
    
    # Calculate effectiveness score (0-100)
    if total_before == 0:
        effectiveness = 100
    else:
        effectiveness = int((fixed_count / total_before) * 100)
    
    return {
        "success": True,
        "summary": {
            "total_before": total_before,
            "total_after": total_after,
            "fixed": fixed_count,
            "new": new_count,
            "remaining": remaining_count,
            "effectiveness": effectiveness
        },
        "severity_reduction": severity_reduction,
        "fixed_findings": fixed,
        "new_findings": new,
        "remaining_findings": remaining,
        "verdict": _get_verdict(effectiveness, new_count)
    }


def _categorize_by_severity(findings: list) -> dict:
    """Categorize findings by severity."""
    categories = {}
    for f in findings:
        sev = f.get("severity", "unknown").lower()
        categories[sev] = categories.get(sev, 0) + 1
    return categories


def _findings_match(f1: dict, f2: dict) -> bool:
    """Check if two findings match (same vulnerability)."""
    # Match by contract + function + type
    return (
        f1.get("contract") == f2.get("contract") and
        f1.get("function") == f2.get("function") and
        f1.get("type") == f2.get("type")
    )


def _get_verdict(effectiveness: int, new_findings: int) -> str:
    """Get overall verdict."""
    if effectiveness >= 90 and new_findings == 0:
        return "EXCELLENT - Nearly all issues fixed, no new issues"
    elif effectiveness >= 70 and new_findings == 0:
        return "GOOD - Most issues fixed, no new issues"
    elif effectiveness >= 50:
        return "FAIR - Some issues fixed"
    elif new_findings > 0:
        return "CONCERNING - New issues introduced"
    else:
        return "POOR - Few issues fixed"


async def generate_repair_report(contract_name: str, before_findings: list, after_findings: list, fixes_applied: list = None) -> dict:
    """Generate a repair verification report."""
    
    comparison = await compare_audit_results(before_findings, after_findings)
    
    report = f"""# Repair Verification Report

## Contract: {contract_name}

---

## Summary

| Metric | Value |
|--------|-------|
| Findings Before | {comparison['summary']['total_before']} |
| Findings After | {comparison['summary']['total_after']} |
| Fixed | {comparison['summary']['fixed']} |
| New | {comparison['summary']['new']} |
| Remaining | {comparison['summary']['remaining']} |
| Effectiveness | {comparison['summary']['effectiveness']}% |
| Verdict | {comparison['verdict']} |

---

## Severity Reduction

| Severity | Before | After | Reduced |
|----------|--------|-------|---------|
"""
    
    for sev, data in comparison['severity_reduction'].items():
        report += f"| {sev.capitalize()} | {data['before']} | {data['after']} | {data['reduced']} |\n"
    
    if fixes_applied:
        report += "\n---\n\n## Fixes Applied\n\n"
        for i, fix in enumerate(fixes_applied, 1):
            report += f"{i}. {fix}\n"
    
    if comparison['fixed_findings']:
        report += "\n---\n\n## Fixed Findings\n\n"
        for f in comparison['fixed_findings']:
            report += f"- **{f.get('type', 'unknown')}** in {f.get('contract', '?')}.{f.get('function', '?')}\n"
    
    if comparison['new_findings']:
        report += "\n---\n\n## New Findings (Introduced by Fix)\n\n"
        for f in comparison['new_findings']:
            report += f"- **{f.get('type', 'unknown')}** in {f.get('contract', '?')}.{f.get('function', '?')}\n"
    
    if comparison['remaining_findings']:
        report += "\n---\n\n## Remaining Findings\n\n"
        for f in comparison['remaining_findings']:
            report += f"- **{f.get('type', 'unknown')}** in {f.get('contract', '?')}.{f.get('function', '?')}\n"
    
    return {
        "success": True,
        "report": report,
        "comparison": comparison
    }


async def suggest_fixes(findings: list, contract_code: str = None) -> dict:
    """Suggest fixes for audit findings."""
    suggestions = []
    
    for finding in findings:
        finding_type = finding.get("type", "").lower()
        severity = finding.get("severity", "unknown")
        
        suggestion = {
            "finding": finding,
            "fixes": []
        }
        
        # Reentrancy fix
        if "reentrancy" in finding_type:
            suggestion["fixes"].append({
                "approach": "checks-effects-interactions",
                "description": "Update state before external call",
                "diff": "- (bool success, ) = msg.sender.call{value: balance}(\"\");\n- balances[msg.sender] = 0;\n+ balances[msg.sender] = 0;\n+ (bool success, ) = msg.sender.call{value: balance}(\"\");"
            })
            suggestion["fixes"].append({
                "approach": "reentrancy-guard",
                "description": "Use OpenZeppelin ReentrancyGuard",
                "diff": "+ import \"@openzeppelin/contracts/security/ReentrancyGuard.sol\";\n+ contract Vault is ReentrancyGuard {\n  function withdraw() public nonReentrant {"
            })
        
        # Access control fix
        elif "access_control" in finding_type or "missing_access" in finding_type:
            suggestion["fixes"].append({
                "approach": "onlyOwner-modifier",
                "description": "Add onlyOwner modifier",
                "diff": "+ modifier onlyOwner() {\n+     require(msg.sender == owner, \"Not owner\");\n+     _;\n+ }\n  function adminFunction() public onlyOwner {"
            })
        
        # Oracle manipulation fix
        elif "oracle" in finding_type:
            suggestion["fixes"].append({
                "approach": "twap-oracle",
                "description": "Use TWAP instead of spot price",
                "diff": "- uint256 price = oracle.getPrice(token);\n+ uint256 price = oracle.getTWAPPrice(token, 3600); // 1 hour TWAP"
            })
        
        # Flash loan fix
        elif "flash_loan" in finding_type:
            suggestion["fixes"].append({
                "approach": "timelock",
                "description": "Add timelock for governance actions",
                "diff": "+ require(block.timestamp >= proposal.timestamp + TIMELOCK_DELAY, \"Timelock not expired\");"
            })
        
        # Overflow fix
        elif "overflow" in finding_type:
            suggestion["fixes"].append({
                "approach": "checked-arithmetic",
                "description": "Use Solidity 0.8+ checked arithmetic",
                "diff": "- unchecked { total += amount; }\n+ total += amount; // Solidity 0.8+ checks automatically"
            })
        
        # Generic fix
        else:
            suggestion["fixes"].append({
                "approach": "review-and-fix",
                "description": "Manual review required",
                "diff": "See finding details for specific fix recommendations"
            })
        
        suggestions.append(suggestion)
    
    return {
        "success": True,
        "suggestions": suggestions,
        "total_suggestions": len(suggestions)
    }


async def execute_tool(tool_name: str, arguments: dict) -> dict:
    if tool_name == "compare_audit_results":
        return await compare_audit_results(
            arguments.get("before_findings", []),
            arguments.get("after_findings", [])
        )
    elif tool_name == "generate_repair_report":
        return await generate_repair_report(
            arguments.get("contract_name", ""),
            arguments.get("before_findings", []),
            arguments.get("after_findings", []),
            arguments.get("fixes_applied")
        )
    elif tool_name == "suggest_fixes":
        return await suggest_fixes(
            arguments.get("findings", []),
            arguments.get("contract_code")
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
