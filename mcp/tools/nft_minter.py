#!/usr/bin/env python3
"""
Athena NFT Certificate Minter — MCP Tool
Mints ERC-1155 audit certificate NFTs on Sepolia/Base Sepolia.
"""

import json
import os
import subprocess
import sys
from typing import Optional

# Contract addresses
CONTRACTS = {
    "sepolia": "0x3247d57d37bd1878479f03a077aba807649dbaf5",
    "base-sepolia": "0xb8f167a84816b5b9373997337119a2186c6e3708",
}

# Severity tiers: 1=S, 2=A, 3=B, 4=C
TIER_MAP = {"S": 1, "A": 2, "B": 3, "C": 4}


def build_tool_definitions() -> list:
    return [
        {
            "name": "mint_audit_nft",
            "description": "Mint an ERC-1155 audit certificate NFT. Requires a valid EAS attestation UID from a prior eas_attest step. The NFT tier (S/A/B/C) is determined by the audit severity.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "eas_uid": {
                        "type": "string",
                        "description": "The EAS attestation UID (0x..., 66 chars) from the eas_attest step"
                    },
                    "tier": {
                        "type": "string",
                        "enum": ["S", "A", "B", "C"],
                        "description": "Audit certificate tier: S=critical findings, A=high, B=medium, C=low",
                        "default": "S"
                    },
                    "chain": {
                        "type": "string",
                        "enum": ["sepolia", "base-sepolia"],
                        "description": "Target chain (default: sepolia)",
                        "default": "sepolia"
                    },
                    "recipient": {
                        "type": "string",
                        "description": "Recipient address (0x...). Defaults to the deployer wallet."
                    }
                },
                "required": ["eas_uid"]
            }
        }
    ]


def mint_nft(eas_uid: str, tier: str = "S", chain: str = "sepolia", recipient: Optional[str] = None) -> dict:
    """Mint an audit certificate NFT."""
    private_key = os.environ.get("SEPOLIA_PRIVATE_KEY") or os.environ.get("PRIVATE_KEY")
    rpc_url = os.environ.get("SEPOLIA_RPC_URL") or os.environ.get("RPC_URL")

    if not private_key:
        return {"error": "SEPOLIA_PRIVATE_KEY not set"}
    if not rpc_url:
        return {"error": "SEPOLIA_RPC_URL not set"}

    contract = CONTRACTS.get(chain)
    if not contract:
        return {"error": f"Unsupported chain: {chain}"}

    # Validate UID format
    if not eas_uid.startswith("0x") or len(eas_uid) != 66:
        return {"error": f"Invalid EAS UID format: {eas_uid} (expected 0x + 64 hex chars)"}

    tier_num = TIER_MAP.get(tier.upper(), 1)

    # Get recipient address
    if not recipient:
        try:
            result = subprocess.run(
                ["cast", "wallet", "address", private_key],
                capture_output=True, text=True, timeout=10
            )
            recipient = result.stdout.strip()
        except Exception as e:
            return {"error": f"Failed to get wallet address: {e}"}

    # Build cast command
    # mintCertificate(address to, bytes32 uid, uint8 tier)
    cmd = [
        "cast", "send", contract,
        "mintCertificate(address,bytes32,uint8)",
        recipient, eas_uid, str(tier_num),
        "--rpc-url", rpc_url,
        "--private-key", private_key
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)

        if result.returncode != 0:
            return {"error": f"cast send failed: {result.stderr}"}

        # Extract tx hash from output
        output = result.stdout + result.stderr
        tx_hash = None
        for line in output.split("\n"):
            if "transactionHash" in line or "0x" in line:
                import re
                match = re.search(r'0x[0-9a-fA-F]{64}', line)
                if match:
                    tx_hash = match.group(0)
                    break

        # Get receipt
        if tx_hash:
            receipt_cmd = ["cast", "receipt", tx_hash, "--rpc-url", rpc_url]
            receipt_result = subprocess.run(receipt_cmd, capture_output=True, text=True, timeout=30)
            status = "success" if "status: 1" in receipt_result.stdout or "status: 0x1" in receipt_result.stdout else "failed"

            explorer_base = "https://sepolia.etherscan.io" if chain == "sepolia" else "https://sepolia.basescan.org"

            return {
                "success": True,
                "tx_hash": tx_hash,
                "tx_url": f"{explorer_base}/tx/{tx_hash}",
                "contract": contract,
                "contract_url": f"{explorer_base}/address/{contract}",
                "recipient": recipient,
                "eas_uid": eas_uid,
                "tier": tier.upper(),
                "chain": chain,
                "status": status,
                "verify_command": f"cast call {contract} \"balanceOf(address,uint256)\" {recipient} 1 --rpc-url {rpc_url}"
            }
        else:
            return {"error": f"Could not extract tx hash from output: {output}"}

    except subprocess.TimeoutExpired:
        return {"error": "Transaction timed out (120s)"}
    except Exception as e:
        return {"error": str(e)}


def handle_request(request: dict) -> dict:
    """Handle JSON-RPC request."""
    method = request.get("method")
    params = request.get("params", {})
    req_id = request.get("id", 1)

    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {"name": "athena-nft-minter", "version": "1.0.0"}
            }
        }

    elif method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {"tools": build_tool_definitions()}
        }

    elif method == "tools/call":
        tool_name = params.get("name")
        args = params.get("arguments", {})

        if tool_name == "mint_audit_nft":
            result = mint_nft(**args)
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {
                    "content": [{"type": "text", "text": json.dumps(result, indent=2)}],
                    "isError": not result.get("success", False)
                }
            }
        else:
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "error": {"code": -32601, "message": f"Unknown tool: {tool_name}"}
            }

    elif method == "notifications/initialized":
        return None  # No response needed for notifications

    else:
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "error": {"code": -32601, "message": f"Unknown method: {method}"}
        }


def main():
    """Main entry point — reads JSON-RPC from stdin, writes to stdout."""
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        try:
            request = json.loads(line)
            response = handle_request(request)
            if response is not None:
                print(json.dumps(response), flush=True)
        except json.JSONDecodeError:
            error_response = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {"code": -32700, "message": "Parse error"}
            }
            print(json.dumps(error_response), flush=True)


if __name__ == "__main__":
    main()
