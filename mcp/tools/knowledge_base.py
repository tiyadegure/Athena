#!/usr/bin/env python3
"""
MCP Server: Knowledge Base
ChromaDB-backed RAG knowledge base for vulnerability patterns and audit insights.
"""
import sys
import json
import asyncio
import logging
import os
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("knowledge_base")

TOOL_NAME = "knowledge_base"
TOOL_VERSION = "1.0.0"

# Default ChromaDB path
DEFAULT_CHROMA_PATH = os.environ.get(
    "CHROMA_DB_PATH",
    os.path.join(os.path.dirname(__file__), "..", "data", "chroma_db")
)

# Fallback knowledge base for when ChromaDB is unavailable
FALLBACK_KNOWLEDGE = [
    {
        "id": "reentrancy-1",
        "category": "reentrancy",
        "title": "Classic Reentrancy (DAO Attack Pattern)",
        "content": "A reentrancy vulnerability occurs when a contract makes an external call before updating its state. An attacker can recursively call the vulnerable function to drain funds. Fix: Use ReentrancyGuard from OpenZeppelin or follow Checks-Effects-Interactions pattern.",
        "severity": "high",
        "references": ["SWC-107", "CWE-841"]
    },
    {
        "id": "reentrancy-2",
        "category": "reentrancy",
        "title": "Cross-function Reentrancy",
        "content": "Cross-function reentrancy occurs when an attacker exploits shared state between two functions. Even if individual functions are protected, the shared state can be manipulated through reentrancy across function boundaries.",
        "severity": "high",
        "references": ["SWC-107"]
    },
    {
        "id": "overflow-1",
        "category": "integer_overflow",
        "title": "Integer Overflow/Underflow",
        "content": "In Solidity <0.8.0, arithmetic operations silently overflow/underflow. An attacker can exploit this to manipulate balances, token supplies, or other numeric values. Fix: Use SafeMath library or Solidity >=0.8.0 with built-in overflow checks.",
        "severity": "high",
        "references": ["SWC-101", "CWE-190"]
    },
    {
        "id": "access-1",
        "category": "access_control",
        "title": "Missing Access Control",
        "content": "Critical functions without proper access control can be called by any address. This includes owner-only operations like withdrawing funds, upgrading contracts, or modifying parameters. Fix: Implement onlyOwner modifier or role-based access control.",
        "severity": "high",
        "references": ["SWC-105", "CWE-284"]
    },
    {
        "id": "access-2",
        "category": "access_control",
        "title": "Unprotected Self-destruct",
        "content": "The selfdestruct opcode can permanently destroy a contract. If not properly protected, an attacker can destroy the contract and send its balance to an arbitrary address. Fix: Remove selfdestruct or add strict access control.",
        "severity": "high",
        "references": ["SWC-106"]
    },
    {
        "id": "flashloan-1",
        "category": "flash_loan",
        "title": "Flash Loan Price Manipulation",
        "content": "Flash loans allow borrowing large amounts without collateral within a single transaction. Attackers use them to manipulate oracle prices, drain liquidity pools, or exploit AMM pricing algorithms. Fix: Use TWAP oracles, implement slippage checks, and add reentrancy guards.",
        "severity": "high",
        "references": []
    },
    {
        "id": "frontend-1",
        "category": "front_running",
        "title": "Front-running / MEV",
        "content": "Transactions in the mempool are visible before confirmation. Miners or bots can front-run profitable transactions, sandwich attacks, or extract MEV. Fix: Use commit-reveal schemes, private mempools, or MEV-protection services.",
        "severity": "medium",
        "references": ["SWC-114"]
    },
    {
        "id": "oracle-1",
        "category": "oracle_manipulation",
        "title": "Oracle Manipulation",
        "content": "Smart contracts relying on on-chain price oracles (like spot DEX prices) can be manipulated through large trades or flash loans. Fix: Use decentralized oracles (Chainlink), TWAP, or multiple oracle sources.",
        "severity": "high",
        "references": []
    },
    {
        "id": "denial-1",
        "category": "denial_of_service",
        "title": "Denial of Service via Gas Limit",
        "content": "Functions that iterate over unbounded arrays can hit the block gas limit, making them unusable. This is especially critical for withdrawal or distribution functions. Fix: Use pull-over-push pattern, pagination, or limit array sizes.",
        "severity": "medium",
        "references": ["SWC-128"]
    },
    {
        "id": "logic-1",
        "category": "business_logic",
        "title": "Broken Business Logic",
        "content": "Flaws in the contract's business logic can allow attackers to exploit the system in unintended ways. This includes incorrect calculations, missing validations, or flawed state transitions. Fix: Comprehensive testing, formal verification, and multiple audit rounds.",
        "severity": "medium",
        "references": []
    },
    {
        "id": "tx-origin-1",
        "category": "authentication",
        "title": "tx.origin Authentication Bypass",
        "content": "Using tx.origin for authentication is vulnerable to phishing attacks. A malicious contract can call the victim's contract while the victim initiates the transaction, bypassing msg.sender checks. Fix: Always use msg.sender for authentication.",
        "severity": "medium",
        "references": ["SWC-115"]
    },
    {
        "id": "delegatecall-1",
        "category": "delegatecall",
        "title": "Delegatecall Vulnerabilities",
        "content": "Delegatecall executes code in the context of the calling contract. If the target address can be controlled by an attacker, they can execute arbitrary code with the contract's privileges. Fix: Only delegatecall to trusted, immutable contracts.",
        "severity": "high",
        "references": ["SWC-112"]
    }
]


class KnowledgeBase:
    """ChromaDB-backed knowledge base with fallback to static knowledge."""

    def __init__(self, chroma_path: str = None):
        self.chroma_path = chroma_path or DEFAULT_CHROMA_PATH
        self.chroma_client = None
        self.collection = None
        self._initialized = False

    async def initialize(self):
        """Initialize ChromaDB connection."""
        if self._initialized:
            return

        try:
            import chromadb
            self.chroma_client = chromadb.PersistentClient(path=self.chroma_path)
            self.collection = self.chroma_client.get_or_create_collection(
                name="vulnerability_knowledge",
                metadata={"hnsw:space": "cosine"}
            )
            self._initialized = True
            logger.info(f"ChromaDB initialized at {self.chroma_path}")

            # Seed with fallback knowledge if empty
            if self.collection.count() == 0:
                await self._seed_knowledge()
        except ImportError:
            logger.warning("chromadb not installed, using fallback knowledge base")
            self._initialized = True
        except Exception as e:
            logger.warning(f"ChromaDB initialization failed: {e}, using fallback")
            self._initialized = True

    async def _seed_knowledge(self):
        """Seed ChromaDB with fallback knowledge."""
        if not self.collection:
            return

        try:
            documents = []
            metadatas = []
            ids = []

            for item in FALLBACK_KNOWLEDGE:
                documents.append(item["content"])
                metadatas.append({
                    "category": item["category"],
                    "title": item["title"],
                    "severity": item["severity"],
                    "references": json.dumps(item.get("references", []))
                })
                ids.append(item["id"])

            self.collection.add(
                documents=documents,
                metadatas=metadatas,
                ids=ids
            )
            logger.info(f"Seeded {len(documents)} knowledge entries into ChromaDB")
        except Exception as e:
            logger.warning(f"Failed to seed ChromaDB: {e}")

    async def query(self, query_text: str, top_k: int = 5) -> dict:
        """Query the knowledge base."""
        await self.initialize()

        # Try ChromaDB first
        if self.collection:
            try:
                results = self.collection.query(
                    query_texts=[query_text],
                    n_results=min(top_k, self.collection.count() or 1),
                    include=["documents", "metadatas", "distances"]
                )

                entries = []
                if results and results["documents"] and results["documents"][0]:
                    for i, doc in enumerate(results["documents"][0]):
                        metadata = results["metadatas"][0][i] if results["metadatas"] else {}
                        distance = results["distances"][0][i] if results["distances"] else None
                        entries.append({
                            "content": doc,
                            "category": metadata.get("category", ""),
                            "title": metadata.get("title", ""),
                            "severity": metadata.get("severity", ""),
                            "references": json.loads(metadata.get("references", "[]")),
                            "relevance_score": round(1 - distance, 4) if distance is not None else None
                        })

                return {
                    "success": True,
                    "source": "chromadb",
                    "query": query_text,
                    "results_count": len(entries),
                    "results": entries
                }
            except Exception as e:
                logger.warning(f"ChromaDB query failed: {e}")

        # Fallback to keyword search
        return self._fallback_search(query_text, top_k)

    def _fallback_search(self, query_text: str, top_k: int) -> dict:
        """Keyword-based fallback search."""
        query_lower = query_text.lower()
        scored_results = []

        for item in FALLBACK_KNOWLEDGE:
            score = 0
            # Score based on keyword matches
            keywords = query_lower.split()
            for keyword in keywords:
                if keyword in item["title"].lower():
                    score += 3
                if keyword in item["content"].lower():
                    score += 1
                if keyword in item["category"].lower():
                    score += 2

            if score > 0:
                scored_results.append((score, item))

        scored_results.sort(key=lambda x: x[0], reverse=True)
        results = []

        for score, item in scored_results[:top_k]:
            results.append({
                "content": item["content"],
                "category": item["category"],
                "title": item["title"],
                "severity": item["severity"],
                "references": item.get("references", []),
                "relevance_score": min(score / 10.0, 1.0)
            })

        return {
            "success": True,
            "source": "fallback",
            "query": query_text,
            "results_count": len(results),
            "results": results
        }


# Global instance
kb = KnowledgeBase()


async def execute_tool(tool_name: str, arguments: dict) -> dict:
    if tool_name == "query_knowledge":
        query_text = arguments.get("query", "")
        top_k = arguments.get("top_k", 5)

        if not query_text:
            return {"success": False, "error": "query is required"}

        return await kb.query(query_text, top_k)

    return {"success": False, "error": f"Unknown tool: {tool_name}"}


def build_tool_definitions() -> list:
    return [
        {
            "name": "query_knowledge",
            "description": "Query the vulnerability knowledge base for relevant security patterns, attack vectors, and remediation advice. Uses ChromaDB vector search with keyword fallback.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Natural language query about a vulnerability or security concern (e.g., 'reentrancy in ERC-20 token', 'flash loan attack patterns')"
                    },
                    "top_k": {
                        "type": "integer",
                        "description": "Maximum number of results to return (default: 5)",
                        "default": 5
                    }
                },
                "required": ["query"]
            }
        }
    ]


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
