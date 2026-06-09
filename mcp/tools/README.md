# MCP Tools

Standalone MCP (Model Context Protocol) tool servers for Athena. Each tool runs as an independent process communicating via JSON-RPC over stdio.

## Tools (13)

| Tool | Script | Description |
|------|--------|-------------|
| Slither | `slither_runner.py` | Static analysis via Slither (Trail of Bits) |
| Aderyn | `aderyn_runner.py` | Static analysis via Aderyn (Rust-based, Cyfrin) |
| PoC Generator | `poc_generator.py` | Generates Foundry exploit test contracts |
| Fuzz Runner | `fuzz_runner.py` | Runs Foundry fuzz tests with A1 signal extraction |
| Knowledge Base | `knowledge_base.py` | ChromaDB RAG queries for vulnerability patterns |
| EAS Attestation | `eas_attest.py` | On-chain audit attestation via EAS on Sepolia |
| Exploit Simulator | `exploit_simulator.py` | Simulates attack scenarios against contracts |
| Evidence Chain | `evidence_chain.py` | Merkle-based audit evidence chain |
| Halmos | `halmos_runner.py` | Symbolic execution / formal verification via Halmos |
| Protocol Scanner | `protocol_scanner.py` | Protocol-level dependency and interaction scanning |
| Repair Validator | `repair_validator.py` | Validates that vulnerability fixes are correct |
| Incremental Auditor | `incremental_auditor.py` | Incremental audit for contract updates |
| GEV Analyzer | `gev_analyzer.py` | Governance/Economic/Value analysis |

## Protocol

Each tool implements MCP JSON-RPC over stdio:

```json
{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "slither_analyze", "arguments": {"contract_path": "./src/Token.sol"}}}
```

## Environment Variables

| Variable | Tool | Description |
|----------|------|-------------|
| `OPENAI_API_BASE` | poc_generator | LLM API endpoint for PoC generation |
| `OPENAI_API_KEY` | poc_generator | LLM API key |
| `LLM_MODEL` | poc_generator | Model name (default: gpt-4) |
| `CHROMA_DB_PATH` | knowledge_base | ChromaDB storage path |
| `SEPOLIA_PRIVATE_KEY` | eas_attest | Private key for on-chain attestation |
| `SEPOLIA_RPC_URL` | eas_attest | Sepolia RPC endpoint |

## Running

Each tool can be run standalone:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | python3 slither_runner.py
```

## Dependencies

- **slither_runner.py**: `pip install slither-analyzer`
- **aderyn_runner.py**: `cargo install aderyn`
- **poc_generator.py**: `pip install aiohttp` (optional, for LLM mode)
- **fuzz_runner.py**: `forge` (Foundry)
- **knowledge_base.py**: `pip install chromadb sentence-transformers` (optional, has fallback)
- **eas_attest.py**: `pip install web3 eth-account` (optional, has mock mode)
- **exploit_simulator.py**: `pip install web3 aiohttp`
- **evidence_chain.py**: `pip install web3`
- **halmos_runner.py**: `pip install halmos` (requires Foundry)
- **protocol_scanner.py**: `pip install web3 aiohttp`
- **repair_validator.py**: `pip install slither-analyzer`
- **incremental_auditor.py**: `pip install chromadb`
- **gev_analyzer.py**: `pip install web3 aiohttp`
