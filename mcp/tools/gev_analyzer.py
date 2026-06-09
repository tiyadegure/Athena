#!/usr/bin/env python3
"""
MCP Server: GEV Analyzer
Generalized Extractable Value (GEV) analysis tool.
Based on "Extraction Is Conserved: From MEV to GEV" (2026-05-25)
"""
import sys
import json
import asyncio
import logging

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("gev_analyzer")

TOOL_NAME = "gev_analyzer"
TOOL_VERSION = "1.0.0"

# GEV extraction layers
EXTRACTION_LAYERS = {
    "l1_consensus": {
        "name": "L1 Consensus Layer",
        "description": "Block proposer extraction (traditional MEV)",
        "examples": ["sandwich attacks", "front-running", "back-running", "liquidation MEV"]
    },
    "l2_execution": {
        "name": "L2 Execution Layer",
        "description": "L2 sequencer extraction",
        "examples": ["sequencer MEV", "cross-domain MEV", "L2 priority gas"]
    },
    "application": {
        "name": "Application Layer",
        "description": "Protocol-level extraction",
        "examples": ["oracle manipulation", "governance attacks", "liquidity provision MEV"]
    },
    "user": {
        "name": "User Layer",
        "description": "User-initiated extraction",
        "examples": ["arbitrage", "liquidation bots", "JIT liquidity"]
    }
}

# GEV attack patterns
ATTACK_PATTERNS = {
    "oracle_manipulation": {
        "name": "Oracle Manipulation",
        "severity": "critical",
        "layers": ["application"],
        "description": "Manipulate price oracle to extract value",
        "indicators": ["spot_price_dependency", "single_source_oracle", "no_twap"]
    },
    "cross_domain_mev": {
        "name": "Cross-Domain MEV",
        "severity": "high",
        "layers": ["l1_consensus", "l2_execution"],
        "description": "Extract value across L1/L2 boundaries",
        "indicators": ["bridge_dependency", "async_finality", "cross_layer_calls"]
    },
    "governance_extraction": {
        "name": "Governance Extraction",
        "severity": "high",
        "layers": ["application"],
        "description": "Manipulate governance for value extraction",
        "indicators": ["flash_loan_voting", "timelock_manipulation", "proposal_front_running"]
    },
    "liquidity_mev": {
        "name": "Liquidity MEV",
        "severity": "medium",
        "layers": ["application", "user"],
        "description": "Extract value from liquidity provision/removal",
        "indicators": ["jit_liquidity", "sandwich_lp", "impermanent_loss_exploitation"]
    },
    "sequencer_mev": {
        "name": "Sequencer MEV",
        "severity": "high",
        "layers": ["l2_execution"],
        "description": "L2 sequencer extracting value from transaction ordering",
        "indicators": ["centralized_sequencer", "no_fair_ordering", "soft_commitments"]
    }
}


def build_tool_definitions() -> list:
    return [
        {
            "name": "analyze_gev_surface",
            "description": "Analyze a contract's Generalized Extractable Value (GEV) surface",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "contract_code": {
                        "type": "string",
                        "description": "Solidity source code to analyze"
                    },
                    "network": {
                        "type": "string",
                        "enum": ["ethereum_l1", "optimism", "arbitrum", "base", "polygon"],
                        "description": "Target network"
                    }
                },
                "required": ["contract_code"]
            }
        },
        {
            "name": "list_gev_patterns",
            "description": "List all known GEV attack patterns with descriptions",
            "inputSchema": {
                "type": "object",
                "properties": {}
            }
        },
        {
            "name": "calculate_gev_risk",
            "description": "Calculate GEV risk score for a contract based on its features",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "features": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Contract features (e.g., 'oracle_dependency', 'flash_loan', 'governance')"
                    }
                },
                "required": ["features"]
            }
        }
    ]


async def analyze_gev_surface(contract_code: str, network: str = "ethereum_l1") -> dict:
    """Analyze contract's GEV surface."""
    code_lower = contract_code.lower()
    vulnerabilities = []
    risk_factors = []
    
    # Check for oracle dependency
    if "price" in code_lower or "oracle" in code_lower or "getprice" in code_lower:
        vulnerabilities.append({
            "pattern": "oracle_manipulation",
            "risk": "high",
            "description": "Contract depends on price oracle - vulnerable to manipulation",
            "mitigation": "Use TWAP oracle, multiple sources, or Chainlink"
        })
        risk_factors.append("oracle_dependency")
    
    # Check for flash loan vectors
    if "flashloan" in code_lower or "flash_loan" in code_lower or "borrow(" in code_lower:
        vulnerabilities.append({
            "pattern": "flash_loan_attack",
            "risk": "high",
            "description": "Flash loan can be used for governance/price manipulation",
            "mitigation": "Add timelock, use snapshot voting, or limit flash loan impact"
        })
        risk_factors.append("flash_loan")
    
    # Check for governance
    if "governance" in code_lower or "voting" in code_lower or "proposal" in code_lower:
        vulnerabilities.append({
            "pattern": "governance_extraction",
            "risk": "medium",
            "description": "Governance can be manipulated for value extraction",
            "mitigation": "Use time-weighted voting, quorum requirements, timelocks"
        })
        risk_factors.append("governance")
    
    # Check for cross-layer calls (L2 specific)
    if network != "ethereum_l1":
        if "l1" in code_lower or "bridge" in code_lower or "cross" in code_lower:
            vulnerabilities.append({
                "pattern": "cross_domain_mev",
                "risk": "high",
                "description": "Cross-layer calls enable cross-domain MEV",
                "mitigation": "Use atomic cross-layer calls or delay finality"
            })
            risk_factors.append("cross_layer")
    
    # Check for liquidity manipulation
    if "liquidity" in code_lower or "swap" in code_lower or "pool" in code_lower:
        vulnerabilities.append({
            "pattern": "liquidity_mev",
            "risk": "medium",
            "description": "Liquidity operations can be front-run",
            "mitigation": "Use commit-reveal, private mempool, or MEV-Share"
        })
        risk_factors.append("liquidity")
    
    # Calculate overall risk score
    risk_score = _calculate_risk_score(risk_factors)
    
    return {
        "success": True,
        "network": network,
        "vulnerabilities": vulnerabilities,
        "risk_factors": risk_factors,
        "risk_score": risk_score,
        "risk_level": _risk_level(risk_score),
        "recommendations": _generate_recommendations(risk_factors)
    }


def list_gev_patterns() -> dict:
    """List all known GEV attack patterns."""
    return {
        "success": True,
        "patterns": ATTACK_PATTERNS,
        "layers": EXTRACTION_LAYERS,
        "total_patterns": len(ATTACK_PATTERNS)
    }


async def calculate_gev_risk(features: list) -> dict:
    """Calculate GEV risk score based on features."""
    risk_score = _calculate_risk_score(features)
    
    return {
        "success": True,
        "features": features,
        "risk_score": risk_score,
        "risk_level": _risk_level(risk_score),
        "recommendations": _generate_recommendations(features)
    }


def _calculate_risk_score(features: list) -> int:
    """Calculate risk score (0-100) based on features."""
    base_score = 20  # Base risk for any contract
    
    feature_weights = {
        "oracle_dependency": 25,
        "flash_loan": 20,
        "governance": 15,
        "cross_layer": 20,
        "liquidity": 15,
        "reentrancy": 25,
        "unchecked_calls": 20,
        "centralized_control": 15
    }
    
    for feature in features:
        if feature in feature_weights:
            base_score += feature_weights[feature]
    
    return min(base_score, 100)


def _risk_level(score: int) -> str:
    """Convert risk score to level."""
    if score >= 80:
        return "critical"
    elif score >= 60:
        return "high"
    elif score >= 40:
        return "medium"
    elif score >= 20:
        return "low"
    return "minimal"


def _generate_recommendations(features: list) -> list:
    """Generate recommendations based on risk factors."""
    recommendations = []
    
    if "oracle_dependency" in features:
        recommendations.append("Use TWAP oracle with multiple sources (Chainlink, Uniswap TWAP)")
    
    if "flash_loan" in features:
        recommendations.append("Add timelock for governance actions, use snapshot voting")
    
    if "governance" in features:
        recommendations.append("Implement time-weighted voting and quorum requirements")
    
    if "cross_layer" in features:
        recommendations.append("Use atomic cross-layer calls or add finality delay")
    
    if "liquidity" in features:
        recommendations.append("Use commit-reveal scheme or private mempool (Flashbots)")
    
    if not recommendations:
        recommendations.append("No specific GEV risks identified - standard security practices apply")
    
    return recommendations


async def execute_tool(tool_name: str, arguments: dict) -> dict:
    if tool_name == "analyze_gev_surface":
        return await analyze_gev_surface(
            arguments.get("contract_code", ""),
            arguments.get("network", "ethereum_l1")
        )
    elif tool_name == "list_gev_patterns":
        return list_gev_patterns()
    elif tool_name == "calculate_gev_risk":
        return await calculate_gev_risk(arguments.get("features", []))
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
