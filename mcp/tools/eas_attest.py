#!/usr/bin/env python3
"""
MCP Server: EAS Attestation
Handles on-chain attestation via Ethereum Attestation Service (EAS) on Sepolia testnet.
"""
import sys
import json
import asyncio
import logging
import os
import hashlib
from datetime import datetime

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("eas_attest")

TOOL_NAME = "eas_attest"
TOOL_VERSION = "1.0.0"

# EAS Sepolia configuration
EAS_CONTRACT_ADDRESS = "0xC2679fBD37d54388Ce493F1DB75320D236e1815e"
EAS_SCHEMA_REGISTRY = "0x0a7E2Ff94F05A4a6dCa5eF0D47c1e39e8F8e5fC0"
SEPOLIA_CHAIN_ID = 11155111

# Audit result schema UID (example - replace with actual registered schema)
AUDIT_RESULT_SCHEMA_UID = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"

# Common vulnerability severities
SEVERITY_MAP = {
    "critical": 4,
    "high": 3,
    "medium": 2,
    "low": 1,
    "informational": 0
}


def build_tool_definitions() -> list:
    return [
        {
            "name": "submit_attestation",
            "description": "Submit an audit attestation to the Ethereum Attestation Service (EAS) on Sepolia testnet. Creates an on-chain record of the audit results including found vulnerabilities and their severities.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "contract_address": {
                        "type": "string",
                        "description": "The Ethereum address of the audited smart contract"
                    },
                    "vulnerabilities": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "type": {"type": "string", "description": "Vulnerability type (e.g., 'reentrancy', 'overflow')"},
                                "severity": {"type": "string", "enum": ["critical", "high", "medium", "low", "informational"]},
                                "description": {"type": "string"},
                                "location": {"type": "string", "description": "File and line number"},
                                "remediation": {"type": "string", "description": "Suggested fix"}
                            },
                            "required": ["type", "severity"]
                        },
                        "description": "List of vulnerabilities found during the audit"
                    },
                    "audit_mode": {
                        "type": "string",
                        "enum": ["full", "quick", "targeted"],
                        "description": "Type of audit performed (default: full)",
                        "default": "full"
                    }
                },
                "required": ["contract_address", "vulnerabilities"]
            }
        }
    ]


def compute_audit_hash(contract_address: str, vulnerabilities: list) -> str:
    """Compute deterministic hash of audit results for verification."""
    audit_data = {
        "contract": contract_address.lower(),
        "vulnerabilities": sorted(
            [
                {
                    "type": v.get("type", ""),
                    "severity": v.get("severity", ""),
                    "description": v.get("description", "")
                }
                for v in vulnerabilities
            ],
            key=lambda x: x["type"]
        ),
        "timestamp": datetime.utcnow().strftime("%Y-%m-%d")
    }
    data_str = json.dumps(audit_data, sort_keys=True)
    return "0x" + hashlib.sha256(data_str.encode()).hexdigest()


def compute_audit_grade(vulnerabilities: list) -> str:
    """Compute audit grade based on vulnerability severities."""
    if not vulnerabilities:
        return "A+"

    max_severity = 0
    for vuln in vulnerabilities:
        severity = vuln.get("severity", "informational").lower()
        sev_value = SEVERITY_MAP.get(severity, 0)
        max_severity = max(max_severity, sev_value)

    # Count by severity
    counts = {}
    for vuln in vulnerabilities:
        severity = vuln.get("severity", "informational").lower()
        counts[severity] = counts.get(severity, 0) + 1

    # Grade calculation
    if max_severity >= 4:  # critical
        return "F"
    elif max_severity >= 3:  # high
        if counts.get("high", 0) >= 3:
            return "D"
        return "C"
    elif max_severity >= 2:  # medium
        if counts.get("medium", 0) >= 3:
            return "C"
        return "B"
    elif max_severity >= 1:  # low
        return "B+"
    else:  # informational only
        return "A"


async def submit_eas_attestation(
    contract_address: str,
    vulnerabilities: list,
    audit_mode: str = "full"
) -> dict:
    """Submit attestation to EAS on Sepolia."""

    # Validate contract address
    if not contract_address.startswith("0x") or len(contract_address) != 42:
        return {"success": False, "error": "Invalid contract address format"}

    # Compute audit hash and grade
    audit_hash = compute_audit_hash(contract_address, vulnerabilities)
    grade = compute_audit_grade(vulnerabilities)

    # Build attestation data
    attestation_data = {
        "schema": AUDIT_RESULT_SCHEMA_UID,
        "recipient": contract_address,
        "expirationTime": 0,
        "revocable": True,
        "refUID": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "data": {
            "contract_address": contract_address,
            "audit_hash": audit_hash,
            "grade": grade,
            "audit_mode": audit_mode,
            "vulnerability_count": len(vulnerabilities),
            "vulnerabilities": vulnerabilities,
            "timestamp": datetime.utcnow().isoformat(),
            "auditor": "GLM-Audit-Agent-v1"
        }
    }

    # Check for private key in environment
    private_key = os.environ.get("SEPOLIA_PRIVATE_KEY", "")
    rpc_url = os.environ.get("SEPOLIA_RPC_URL", "https://rpc.sepolia.org")

    if private_key:
        # Real on-chain attestation
        try:
            return await _send_onchain_attestation(attestation_data, private_key, rpc_url)
        except Exception as e:
            logger.error(f"On-chain attestation failed: {e}")
            return {
                "success": False,
                "error": f"On-chain attestation failed: {str(e)}",
                "attestation_data": attestation_data
            }
    else:
        # Mock mode - generate attestation without sending to chain
        logger.info("No private key configured, generating mock attestation")
        return _generate_mock_attestation(attestation_data)


async def _send_onchain_attestation(attestation_data: dict, private_key: str, rpc_url: str) -> dict:
    """Send real attestation to EAS on Sepolia."""
    try:
        from web3 import Web3
        from eth_account import Account

        w3 = Web3(Web3.HTTPProvider(rpc_url))
        if not w3.is_connected():
            return {"success": False, "error": f"Cannot connect to {rpc_url}"}

        account = Account.from_key(private_key)
        balance = w3.eth.get_balance(account.address)
        if balance < w3.to_wei(0.001, "ether"):
            return {
                "success": False,
                "error": f"Insufficient balance: {w3.from_wei(balance, 'ether')} ETH. Need at least 0.001 ETH for gas."
            }

        # EAS contract ABI (minimal for attest)
        eas_abi = [
            {
                "inputs": [
                    {
                        "components": [
                            {"name": "schema", "type": "bytes32"},
                            {"name": "recipient", "type": "address"},
                            {"name": "expirationTime", "type": "uint64"},
                            {"name": "revocable", "type": "bool"},
                            {"name": "refUID", "type": "bytes32"},
                            {"name": "data", "type": "bytes"},
                            {"name": "value", "type": "uint256"}
                        ],
                        "name": "request",
                        "type": "tuple"
                    }
                ],
                "name": "attest",
                "outputs": [{"name": "", "type": "bytes32"}],
                "stateMutability": "payable",
                "type": "function"
            }
        ]

        eas_contract = w3.eth.contract(
            address=Web3.to_checksum_address(EAS_CONTRACT_ADDRESS),
            abi=eas_abi
        )

        # Encode attestation data
        data_bytes = json.dumps(attestation_data["data"]).encode("utf-8")

        # Build transaction
        attestation_request = (
            bytes.fromhex(attestation_data["schema"][2:]),
            Web3.to_checksum_address(attestation_data["recipient"]),
            attestation_data["expirationTime"],
            attestation_data["revocable"],
            bytes.fromhex(attestation_data["refUID"][2:]),
            data_bytes,
            0
        )

        tx = eas_contract.functions.attest(attestation_request).build_transaction({
            "from": account.address,
            "nonce": w3.eth.get_transaction_count(account.address),
            "gas": 200000,
            "gasPrice": w3.eth.gas_price,
            "value": 0
        })

        signed_tx = w3.eth.account.sign_transaction(tx, private_key)
        tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)

        # Wait for receipt
        receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=120)

        return {
            "success": True,
            "mode": "onchain",
            "tx_hash": receipt.transactionHash.hex(),
            "block_number": receipt.blockNumber,
            "gas_used": receipt.gasUsed,
            "contract_address": contract_address,
            "grade": attestation_data["data"]["grade"],
            "audit_hash": attestation_data["data"]["audit_hash"],
            "eas_contract": EAS_CONTRACT_ADDRESS,
            "network": "sepolia",
            "explorer_url": f"https://sepolia.etherscan.io/tx/{receipt.transactionHash.hex()}"
        }

    except ImportError:
        return {
            "success": False,
            "error": "web3 and eth-account packages required for on-chain attestation. Install with: pip install web3 eth-account"
        }


def _generate_mock_attestation(attestation_data: dict) -> dict:
    """Generate mock attestation for testing."""
    mock_tx_hash = hashlib.sha256(
        json.dumps(attestation_data, sort_keys=True).encode()
    ).hexdigest()

    data = attestation_data["data"]

    return {
        "success": True,
        "mode": "mock",
        "note": "This is a mock attestation. Set SEPOLIA_PRIVATE_KEY and SEPOLIA_RPC_URL for on-chain attestation.",
        "tx_hash": f"0x{mock_tx_hash}",
        "contract_address": data["contract_address"],
        "grade": data["grade"],
        "audit_hash": data["audit_hash"],
        "audit_mode": data["audit_mode"],
        "vulnerability_summary": {
            "total": data["vulnerability_count"],
            "by_severity": _count_by_severity(data["vulnerabilities"])
        },
        "eas_contract": EAS_CONTRACT_ADDRESS,
        "network": "sepolia",
        "timestamp": data["timestamp"]
    }


def _count_by_severity(vulnerabilities: list) -> dict:
    """Count vulnerabilities by severity level."""
    counts = {"critical": 0, "high": 0, "medium": 0, "low": 0, "informational": 0}
    for vuln in vulnerabilities:
        severity = vuln.get("severity", "informational").lower()
        if severity in counts:
            counts[severity] += 1
    return counts


async def execute_tool(tool_name: str, arguments: dict) -> dict:
    if tool_name == "submit_attestation":
        contract_address = arguments.get("contract_address", "")
        vulnerabilities = arguments.get("vulnerabilities", [])
        audit_mode = arguments.get("audit_mode", "full")

        if not contract_address:
            return {"success": False, "error": "contract_address is required"}
        if not vulnerabilities:
            return {"success": False, "error": "vulnerabilities array is required"}

        return await submit_eas_attestation(contract_address, vulnerabilities, audit_mode)

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
