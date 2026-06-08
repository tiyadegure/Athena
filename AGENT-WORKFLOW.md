# GLM Audit Agent — Coding Agent Workflow

> 本文件是给 coding agent（Claude Code / Pi 等）的完整工作流指引。
> 读完本文件后，agent 应能独立推进项目，无需额外人工说明。

---

## 1. 项目目标

构建一个 **Web3 智能合约安全审计 Agent**，驱动模型为 GLM-5.1。

核心卖点：
- **Skill（方法论）**：pashov solidity-auditor — 业界最认可的审计方法论
- **MCP（工具链）**：从 AuditAI 拆解出的独立工具（slither, PoC, fuzz, RAG, EAS）
- **长程任务**：GLM-5.1 的 200K 上下文 + Interleaved Thinking，驱动 8 步审计闭环
- **链上认证**：EAS attestation + 雅典娜女神像素 NFT 证书

一句话描述：
> "在 20 个开源审计项目中，只有 AuditAI 同时拥有 RAG 知识库、PoC 生成、Foundry fuzz 验证和 EAS 链上认证。GLM-5.1 的长程能力驱动了从漏洞发现到链上证书的完整闭环。"

---

## 2. 技术架构总览

```
┌─────────────────────────────────────────────────┐
│              GLM-5.1 (驱动模型)                  │
│         200K context / Interleaved Thinking      │
├─────────────────────────────────────────────────┤
│              Skill 层 (方法论)                    │
│         pashov solidity-auditor                  │
│         10 轮检查：scope → access → math → ...   │
├─────────────────────────────────────────────────┤
│              MCP 层 (工具链)                      │
│  ┌─────┐ ┌──────┐ ┌─────┐ ┌──────┐ ┌────────┐  │
│  │Slither│ │Aderyn│ │PoC  │ │Fuzz  │ │EAS     │  │
│  │静态分析│ │Rust版│ │生成 │ │Foundry│ │链上认证│  │
│  └─────┘ └──────┘ └─────┘ └──────┘ └────────┘  │
│              + Knowledge Base (ChromaDB/RAG)     │
├─────────────────────────────────────────────────┤
│              链上层 (Sepolia 测试网)              │
│  EAS Attestation → ERC-1155 NFT 证书            │
└─────────────────────────────────────────────────┘
```

---

## 3. 审计工作流（8 步）

这是 Agent 执行审计时的完整流程。每一步都必须可执行、可验证。

### Step 1: 需求理解
- 输入：Solidity 合约文件
- 解析合约架构、依赖、关键函数
- 确定审计范围

### Step 2: 双引擎静态分析
- 运行 Slither：`slither <contract> --json output.json`
- 运行 Aderyn：`aderyn <contract_dir>`
- 合并结果，去重

### Step 3: RAG 知识增强
- 用静态分析结果作为查询
- 从 ChromaDB 知识库检索相关历史漏洞案例
- 知识库来源：已知 DeFi 漏洞、CVE、审计报告

### Step 4: PoC 生成
- 对每个高危漏洞生成 PoC（Proof of Concept）
- 使用 Foundry 测试框架
- PoC 必须能实际执行并触发漏洞

### Step 5: Foundry fuzz 验证
- 对 PoC 进行模糊测试：`forge test --fuzz-runs 1000`
- 确认漏洞可复现
- 记录触发条件

### Step 6: 修复建议
- 针对每个漏洞生成修复代码
- 提供 before/after 对比
- 引用最佳实践

### Step 7: EAS 链上认证
- 生成审计报告哈希
- 在 Sepolia 测试网提交 EAS attestation
- Attestation 内容：合约地址、审计者、发现摘要、严重性、时间戳

### Step 8: 铸造 NFT 证书
- 根据审计结果分级（A/B/C）
- 铸造 ERC-1155 NFT
- 图像为链上 SVG 像素雅典娜女神

---

## 4. 分阶段实施计划

### Phase 1: 集成 Skill 与工具 ⬅️ 当前阶段

#### 1.1 集成 pashov solidity-auditor skill

**来源**: https://github.com/pashov/skills

**操作**:
```bash
# 克隆 pashov 的 skills 仓库
git clone https://github.com/pashov/skills /tmp/pashov-skills

# 复制 solidity-auditor skill 到项目
cp -r /tmp/pashov-skills/skills/solidity-auditor ./skills/

# 阅读 skill 内容，理解 10 轮检查流程
cat ./skills/solidity-auditor/SKILL.md
```

**要点**:
- pashov 的 skill 是纯方法论文档（没有代码），定义了审计的 10 轮检查流程
- 需要将其转化为 Agent 的 system prompt 或 skill 配置
- Skill 内容包括：scope → architecture → access control → math → external calls → tokens → gas → centralization → economic → report

#### 1.2 从 AuditAI 拆解工具 MCP

**来源**: https://github.com/Sotatek/AuditAI

**问题**: AuditAI 的 `analyze_contract` 是一个完整的 Agent 流水线（内部调用 LLM），不是无状态工具。需要拆解。

**操作**:
```bash
# 克隆 AuditAI
git clone https://github.com/Sotatek/AuditAI /tmp/auditai

# 分析其工具结构
cat /tmp/auditai/src/tools/*.py

# 需要拆解出的独立工具：
# 1. slither_runner.py — 运行 Slither 静态分析
# 2. aderyn_runner.py — 运行 Aderyn 静态分析  
# 3. poc_generator.py — 生成 PoC 测试代码
# 4. fuzz_runner.py — 运行 Foundry fuzz 测试
# 5. knowledge_base.py — ChromaDB RAG 查询
# 6. eas_attest.py — EAS 链上认证
```

**每个工具的 MCP 封装格式**:
```typescript
// 以 slither_runner 为例
{
  "name": "slither_analyze",
  "description": "Run Slither static analysis on a Solidity contract",
  "inputSchema": {
    "type": "object",
    "properties": {
      "contract_path": { "type": "string", "description": "Path to .sol file" },
      "detectors": { "type": "array", "items": { "type": "string" }, "description": "Specific detectors to run (optional)" }
    },
    "required": ["contract_path"]
  }
}
```

#### 1.3 配置 MCP Server

创建 `mcp/servers.json`，注册所有工具：
```json
{
  "servers": [
    {
      "name": "slither",
      "command": "python3",
      "args": ["mcp/tools/slither_runner.py"],
      "description": "Slither static analysis"
    },
    {
      "name": "aderyn",
      "command": "python3",
      "args": ["mcp/tools/aderyn_runner.py"],
      "description": "Aderyn static analysis"
    },
    {
      "name": "poc-generator",
      "command": "python3",
      "args": ["mcp/tools/poc_generator.py"],
      "description": "Generate PoC exploit code"
    },
    {
      "name": "fuzz-runner",
      "command": "python3",
      "args": ["mcp/tools/fuzz_runner.py"],
      "description": "Run Foundry fuzz tests"
    },
    {
      "name": "knowledge-base",
      "command": "python3",
      "args": ["mcp/tools/knowledge_base.py"],
      "description": "Query vulnerability knowledge base"
    },
    {
      "name": "eas-attest",
      "command": "python3",
      "args": ["mcp/tools/eas_attest.py"],
      "description": "Submit EAS attestation on-chain"
    }
  ]
}
```

#### 1.4 集成到 Claude Code

在 Claude Code 中配置 MCP：
```bash
# 添加 MCP servers
claude mcp add slither -- python3 mcp/tools/slither_runner.py
claude mcp add aderyn -- python3 mcp/tools/aderyn_runner.py
claude mcp add poc-generator -- python3 mcp/tools/poc_generator.py
claude mcp add fuzz-runner -- python3 mcp/tools/fuzz_runner.py
claude mcp add knowledge-base -- python3 mcp/tools/knowledge_base.py
claude mcp add eas-attest -- python3 mcp/tools/eas_attest.py
```

### Phase 2: 搭建测试环境

#### 2.1 准备测试合约

在 `contracts/test-cases/` 下创建 5 个测试合约：

| 文件 | 漏洞类型 | 预期检测结果 |
|------|---------|-------------|
| `Reentrancy.sol` | 重入攻击 | 应检测到 + PoC 可触发 |
| `IntegerOverflow.sol` | 整数溢出 | 应检测到 + 建议修复 |
| `AccessControl.sol` | 权限控制缺陷 | 应检测到权限问题 |
| `FlashLoan.sol` | 闪电贷攻击 | 应生成完整攻击 PoC |
| `SafeContract.sol` | 无漏洞 | 不应误报 |

示例 `Reentrancy.sol`：
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VulnerableBank {
    mapping(address => uint256) public balances;
    
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function withdraw() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance");
        
        // 漏洞：先转账再更新余额（重入攻击）
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
        balances[msg.sender] = 0;
    }
}
```

#### 2.2 编写预期结果

创建 `contracts/test-cases/expected-results.json`：
```json
{
  "Reentrancy.sol": {
    "should_detect": true,
    "vulnerability_type": "reentrancy",
    "severity": "critical",
    "poc_should_pass": true
  },
  "IntegerOverflow.sol": {
    "should_detect": true,
    "vulnerability_type": "integer-overflow",
    "severity": "high",
    "poc_should_pass": true
  },
  "AccessControl.sol": {
    "should_detect": true,
    "vulnerability_type": "access-control",
    "severity": "high",
    "poc_should_pass": true
  },
  "FlashLoan.sol": {
    "should_detect": true,
    "vulnerability_type": "flash-loan",
    "severity": "critical",
    "poc_should_pass": true
  },
  "SafeContract.sol": {
    "should_detect": false,
    "vulnerability_type": null,
    "severity": null,
    "poc_should_pass": false
  }
}
```

#### 2.3 测试工具链

确保以下工具可用：
```bash
# Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Slither
pip install slither-analyzer

# Aderyn
curl -L https://raw.githubusercontent.com/Cyfrin/aderyn/dev/cyfrinup/install | bash
cyfrinup
```

### Phase 3: 开发与调试

#### 3.1 端到端审计测试

用 Claude 跑通完整链路：
```bash
# 对 Reentrancy.sol 进行完整审计
claude "请对 contracts/test-cases/Reentrancy.sol 进行安全审计"

# 预期：Agent 依次调用
# 1. slither_analyze → 发现 reentrancy
# 2. knowledge_base → 查询 reentrancy 历史案例
# 3. poc_generator → 生成 PoC
# 4. fuzz_runner → 验证 PoC
# 5. 生成修复建议
```

#### 3.2 NFT 合约开发

在 `contracts/` 下创建：

```solidity
// AuditCertificate.sol
// ERC-1155 分级 NFT 审计证书
// Token ID: 1=A级(金), 2=B级(银), 3=C级(铜)
// 图像：链上 SVG 像素雅典娜女神
```

**铸造逻辑**：
- 检查 EAS attestation 是否存在
- 根据 attestation 中的严重性等级决定 NFT 等级
- 调用 `mint(to, tokenId, amount, data)`

#### 3.3 EAS 配置

Sepolia 测试网 EAS 配置：
```
EAS 合约: 0xC2679fBD37d54388Ce493F1DB75320D236e1815e
Schema Registry: 0x0a7E2Ff54e76B8E6659aedc9103FB935A8DBB798
Schema UID: (需要创建)
```

**创建 Schema**：
```
string contractAddress,
address auditor,
string findingsHash,
uint8 severity,
uint256 timestamp
```

### Phase 4: 评测与 Demo

#### 4.1 GLM-5.1 评测

切换到 GLM-5.1 执行审计：
```bash
# 使用 Z.AI Coding Plan
export GLM_API_KEY="your_key"
export GLM_ENDPOINT="https://api.z.ai/api/coding/paas/v4"

# 对 5 个测试合约执行审计
# 记录结果并与 Claude 对比
```

#### 4.2 录屏 Demo

录制内容：
1. 展示项目架构（Skill + MCP + GLM-5.1）
2. 对一个合约执行完整审计流程
3. 展示 EAS attestation 在 Etherscan 上的结果
4. 展示铸造的 NFT 证书（OpenSea 测试网）

#### 4.3 评测指标

| 指标 | 目标 |
|------|------|
| 漏洞检测率 | ≥ 90%（4/5 测试合约正确检测） |
| 误报率 | 0%（SafeContract 不应误报） |
| PoC 可执行率 | ≥ 75%（3/4 PoC 能触发漏洞） |
| 完整闭环 | 能完成 Step 1-8 全流程 |

---

## 5. 关键技术细节

### GLM-5.1 接入

```python
# API 调用示例
import requests

response = requests.post(
    "https://api.z.ai/api/coding/paas/v4/chat/completions",
    headers={
        "Authorization": f"Bearer {GLM_API_KEY}",
        "Content-Type": "application/json"
    },
    json={
        "model": "glm-5.1",
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": "请审计以下合约..."}
        ],
        "tools": MCP_TOOLS,  # 注册的 MCP 工具
        "thinking": "interleaved"  # 启用 Interleaved Thinking
    }
)
```

### EAS Attestation 调用

```javascript
// 使用 ethers.js 在 Sepolia 上提交 attestation
const EASContractAddress = "0xC2679fBD37d54388Ce493F1DB75320D236e1815e";
const schemaUID = "0x..."; // 你的 schema UID

const tx = await eas.attest({
    schema: schemaUID,
    data: {
        recipient: "0x...",  // 审计者地址
        expirationTime: 0,
        revocable: true,
        data: encodeAbiParameters(
            ["string", "address", "string", "uint8", "uint256"],
            [contractAddress, auditor, findingsHash, severity, timestamp]
        ),
    },
});
```

### NFT 铸造逻辑

```solidity
// 基于 EAS attestation 铸造 NFT
function mintCertificate(
    address to,
    bytes32 attestationUID
) external {
    // 1. 验证 attestation 存在
    require(eas.isAttestationValid(attestationUID), "Invalid attestation");
    
    // 2. 读取 severity
    Attestation memory att = eas.getAttestation(attestationUID);
    uint8 severity = decodeSeverity(att.data);
    
    // 3. 映射到 NFT 等级
    uint256 tokenId;
    if (severity == 0) tokenId = 1;  // Critical → A级(金)
    else if (severity <= 2) tokenId = 2;  // High/Medium → B级(银)
    else tokenId = 3;  // Low → C级(铜)
    
    // 4. 铸造
    _mint(to, tokenId, 1, "");
}
```

---

## 6. 开发约束

1. **测试网 Only**：所有链上操作使用 Sepolia 测试网，不消耗真实 ETH
2. **先验证再报告**：每个漏洞必须有 PoC 或 fuzz 验证，不报告未验证的发现
3. **Skill 优先**：方法论用 pashov skill，不要自己发明审计流程
4. **工具独立**：每个 MCP 工具是独立的、无状态的，不要把 LLM 调用放进工具里
5. **阶段性提交**：每完成一个功能点就 git commit + push

---

## 7. 参考资源

| 资源 | 链接 | 用途 |
|------|------|------|
| pashov/skills | https://github.com/pashov/skills | 审计方法论 |
| AuditAI | https://github.com/Sotatek/AuditAI | 工具链参考 |
| Foundry Book | https://book.getfoundry.sh/ | 合约测试框架 |
| EAS Docs | https://docs.attest.sh/ | 链上认证 |
| OpenZeppelin | https://www.openzeppelin.com/contracts | ERC-1155 参考 |
| Damn Vulnerable DeFi | https://www.damnvulnerabledefi.xyz/ | 测试用例参考 |
| GLM-5.1 论文 | arxiv:2602.15763 | 模型技术细节 |
| Z.AI API | https://z.ai | API 接入 |

---

## 8. 当前状态

- [x] 竞品调研（20 个项目）
- [x] 项目规划与技术选型
- [x] GLM-5.1 技术特征调研
- [x] 测试方案设计
- [x] Phase 1：集成 pashov skill + AuditAI 工具 MCP
- [x] Phase 2：搭建测试环境（5 个测试合约）
- [x] Phase 3.1：安装工具链（slither, forge, aderyn）
- [x] Phase 3.2：验证 MCP 工具
- [x] Phase 3.3：端到端审计验证（Reentrancy.sol 完整闭环）
- [ ] Phase 3.4：NFT 合约开发 ⬅️ 当前
- [ ] Phase 4：GLM-5.1 评测 + Demo 录屏

---

## 9. Phase 3.4：NFT 审计证书合约

> 在 `contracts/` 下创建 `AuditCertificate.sol`，实现 ERC-1155 分级 NFT + 链上 SVG 雅典娜女神图像。

### 9.1 合约设计

**标准**: ERC-1155（可同时持有多种类型 token，比 ERC-721 更适合分级场景）

**Token ID 分级**:
| Token ID | 等级 | 图像主题 | 铸造条件 |
|----------|------|---------|---------|
| 1 | A 级（Gold） | 金色雅典娜 | 发现 Critical 漏洞 + PoC 验证通过 |
| 2 | B 级（Silver） | 银色雅典娜 | 发现 High/Medium 漏洞 + 修复建议 |
| 3 | C 级（Bronze） | 铜色雅典娜 | 完成基本扫描 + 报告 |

**铸造触发**: 基于 EAS attestation
- 检查 attestation 是否存在且有效
- 从 attestation 中读取 severity
- 映射到对应的 tokenId
- 铸造给指定地址

### 9.2 链上 SVG 图像

图像不存储 IPFS，直接在合约中生成 SVG，保证永久可用。

**设计风格**: uPEG 像素独角兽底图 + 雅典娜女神形象
- 像素风（16x16 或 32x32 网格）
- 三个等级用不同配色区分：金色 (#FFD700) / 银色 (#C0C0C0) / 铜色 (#CD7F32)
- 背景：深色 (#1a1a2e)
- 雅典娜元素：头盔、盾牌、长矛

**实现方式**: `tokenURI()` 返回 `data:application/json;base64,...`，JSON 中包含 SVG 图像的 base64 编码。

### 9.3 合约骨架

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title AuditCertificate - ERC-1155 NFT 审计证书
/// @notice 铸造条件：基于 EAS attestation 的审计结果分级
contract AuditCertificate is ERC1155, Ownable {
    // Token IDs
    uint256 public constant GOLD = 1;     // A级 - Critical
    uint256 public constant SILVER = 2;   // B级 - High/Medium
    uint256 public constant BRONZE = 3;   // C级 - Low/Info

    // EAS 合约地址 (Sepolia)
    address public constant EAS_CONTRACT = 0xC2679fBD37d54388Ce493F1DB75320D236e1815e;

    // 已使用的 attestation（防重复铸造）
    mapping(bytes32 => bool) public usedAttestations;

    constructor() ERC1155("") Ownable(msg.sender) {
        // 可选：设置 baseURI
    }

    /// @notice 根据 EAS attestation 铸造 NFT
    /// @param to 接收地址
    /// @param attestationUID EAS attestation UID
    function mintCertificate(
        address to,
        bytes32 attestationUID
    ) external {
        // TODO: 实现以下逻辑
        // 1. 验证 attestation 存在
        // 2. 检查未被使用过
        // 3. 读取 severity
        // 4. 映射到 tokenId
        // 5. 铸造
        // 6. 标记已使用
    }

    /// @notice 返回 NFT 元数据（包含链上 SVG）
    /// @param tokenId Token ID (1/2/3)
    function tokenURI(uint256 tokenId) public pure returns (string memory) {
        // TODO: 返回 JSON metadata
        // 包含 name, description, image (SVG base64)
        // 根据 tokenId 返回不同配色的雅典娜 SVG
    }

    /// @notice 生成雅典娜 SVG
    /// @param tokenId Token ID，决定配色
    function _generateAthenaSVG(uint256 tokenId) internal pure returns (string memory svg) {
        // TODO: 根据 tokenId 生成不同配色的像素雅典娜 SVG
        // 金色/银色/铜色
        // 像素风格，16x16 或 32x32 网格
    }
}
```

### 9.4 EAS 验证逻辑

```solidity
// EAS 接口（只需用到的部分）
interface IEAS {
    struct Attestation {
        bytes32 uid;
        bytes32 schema;
        uint64 time;
        uint64 expirationTime;
        uint64 revocable;
        bytes32 refUID;
        address recipient;
        address attester;
        bool revocable;
        bytes data;
    }

    function getAttestation(bytes32 uid) external view returns (Attestation memory);
    function isAttestationValid(bytes32 uid) external view returns (bool);
}

// 在 mintCertificate 中调用
IEAS eas = IEAS(EAS_CONTRACT);
require(eas.isAttestationValid(attestationUID), "Invalid attestation");
IEAS.Attestation memory att = eas.getAttestation(attestationUID);

// 从 att.data 中解码 severity
// 注意：需要用 abi.decode 解码你的 schema 定义的字段
// schema: string contractAddress, address auditor, string findingsHash, uint8 severity, uint256 timestamp
(uint8 severity) = abi.decode(att.data, (uint8));
```

### 9.5 铸造脚本

创建 `scripts/mint-certificate.js`（或用 Foundry script）：

```javascript
// 使用 ethers.js 铸造 NFT
// 1. 连接 Sepolia
// 2. 调用 mintCertificate(userAddress, attestationUID)
// 3. 返回 tx hash
```

### 9.6 测试

创建 `contracts/test/AuditCertificate.t.sol`：

```solidity
// 测试用例：
// 1. test_mint_gold — 模拟 Critical attestation，铸造 A 级 NFT
// 2. test_mint_silver — 模拟 High attestation，铸造 B 级 NFT
// 3. test_mint_bronze — 模拟 Low attestation，铸造 C 级 NFT
// 4. test_cannot_double_mint — 同一 attestation 不能铸造两次
// 5. test_tokenuri_contains_svg — tokenURI 返回包含 SVG 的 JSON
// 6. test_svg_colors_differ — 三个等级的 SVG 配色不同
```

### 9.7 依赖安装

```bash
# OpenZeppelin
forge install OpenZeppelin/openzeppelin-contracts --no-commit

# remappings.txt
echo '@openzeppelin/=lib/openzeppelin-contracts/' > remappings.txt
```

### 9.8 部署到 Sepolia

```bash
# 1. 设置环境变量
export SEPOLIA_RPC_URL="https://sepolia.drpc.org"
export PRIVATE_KEY="your...n# 2. 部署
forge script script/DeployCertificate.s.sol \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify
```

### 9.9 完成标准

- [ ] 合约编译通过（`forge build`）
- [ ] 所有测试通过（`forge test`）
- [ ] 三个等级的 SVG 图像各不相同且可辨识
- [ ] EAS 验证逻辑正确（能拒绝无效 attestation）
- [ ] 防重复铸造生效
- [ ] 部署到 Sepolia 并可交互
- [ ] Phase 4：GLM-5.1 评测 + Demo 录屏
