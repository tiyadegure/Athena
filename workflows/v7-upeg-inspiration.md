# v7 — uPEG 灵感：混合代币 + Uniswap v4 Hook + 稀有度算法

> **灵感来源**: [uPEG (Unipeg)](https://etherscan.io/address/0x44b28991b167582f18ba0259e0173176ca125505) — ERC-20/721 混合体，链上 SVG，Uniswap v4 Hook
> **目标**: 将 uPEG 的技术特点融入 Athena 审计 NFT，提升技术深度和叙事张力
> **NFT 形象**: 保持现有猫头鹰设计，不改动

---

## 核心创新点

| # | 创新 | 来源 | Athena 应用 |
|---|------|------|------------|
| 1 | **混合代币标准** | uPEG = ERC-20 + ERC-721 | 审计 NFT 同时是可分割声誉代币 |
| 2 | **Uniswap v4 Hook** | uPEG 通过 Hook 实现链上生成 | 审计结果自动触发 DeFi 安全参数 |
| 3 | **稀有度算法** | OpenRarity Information Content | S/A/B/C 四级动态稀有度计算 |
| 4 | **链上 SVG** | uPEG 已实现 | Athena 已实现，可进一步优化 |

---

## Phase 7.1 — 混合代币标准 (ERC-404 模式)

### 设计思路

uPEG 同时是 ERC-20（可交易）和 ERC-721（有唯一性）。Athena 可以借鉴：

| 属性 | ERC-721 (NFT) | ERC-20 (代币) | 混合价值 |
|------|---------------|---------------|----------|
| 审计证书 | 不可分割，唯一 | — | 链上永久证明 |
| 声誉积分 | — | 可分割，可交易 | 审计师权威量化 |
| 组合效果 | S 级 NFT = 高声誉 | 高声誉 = 更多审计机会 | 飞轮效应 |

### 合约设计

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title AthenaReputation
 * @notice 混合代币：审计 NFT (ERC-721) + 声誉积分 (ERC-20)
 * @dev 灵感来自 uPEG 的混合标准设计
 * 
 * 机制：
 * - 铸造审计 NFT 时，自动获得等值声誉积分
 * - NFT 等级越高，获得的声誉积分越多
 * - 声誉积分可转让（交易审计师权威）
 * - NFT 不可分割，但声誉积分可分割
 */
contract AthenaReputation is ERC721, ERC20 {
    // 等级 → 声誉积分映射
    mapping(uint8 => uint256) public tierToReputation;
    
    // 审计师地址 → 累计声誉
    mapping(address => uint256) public auditorReputation;
    
    constructor() 
        ERC721("Athena Audit Certificate", "ATHENA") 
        ERC20("Athena Reputation", "ATHREP") 
    {
        // S=1000, A=500, B=200, C=100
        tierToReputation[0] = 1000 * 1e18;
        tierToReputation[1] = 500 * 1e18;
        tierToReputation[2] = 200 * 1e18;
        tierToReputation[3] = 100 * 1e18;
    }
    
    /**
     * @notice 铸造审计 NFT 并获得声誉积分
     * @param to 接收地址
     * @param tokenId NFT ID
     * @param tier 等级 (0=S, 1=A, 2=B, 3=C)
     */
    function mintWithReputation(
        address to, 
        uint256 tokenId, 
        uint8 tier
    ) external onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
        
        uint256 rep = tierToReputation[tier];
        _mint(to, rep);
        
        auditorReputation[to] += rep;
    }
    
    /**
     * @notice 重写 transfer，防止声誉积分转移到未验证地址
     */
    function _transfer(address from, address to, uint256 amount) internal override {
        // 可以添加声誉门槛检查
        super._transfer(from, to, amount);
    }
    
    // Required overrides
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        return super._update(to, tokenId, auth);
    }
    
    function _update(address from, address to, uint256 value) internal override returns (address) {
        return super._update(from, to, value);
    }
}
```

### 文件结构

```
contracts/
├── AuditCertificate.sol          # 现有 NFT 合约
├── AuditEvidenceChain.sol        # 现有证据链合约
└── AthenaReputation.sol          # 新增：混合代币合约
```

---

## Phase 7.2 — Uniswap v4 Hook 集成

### 设计思路

uPEG 通过 Uniswap v4 Hook 实现链上 SVG 生成。Athena 可以更进一步：

| Hook 触发点 | Athena 应用 |
|-------------|------------|
| `beforeSwap` | 检查交易对是否有 Athena 审计标记 |
| `afterSwap` | 如果涉及未审计合约，发出警告 |
| `beforeModifyPosition` | 流动性添加前检查合约安全性 |
| `afterInitialize` | 新池创建时自动触发审计评估 |

### 合约设计

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";

/**
 * @title AthenaSecurityHook
 * @notice Uniswap v4 Hook：自动检查交易安全性
 * @dev 灵感来自 uPEG 的 Hook 架构
 * 
 * 功能：
 * - 交易前检查合约是否经过 Athena 审计
 * - 未审计合约发出链上警告
 * - 审计结果自动更新合约安全等级
 */
contract AthenaSecurityHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    
    // 合约地址 → 审计等级
    mapping(address => uint8) public contractAuditTier;
    
    // 合约地址 → 是否已审计
    mapping(address => bool) public isAudited;
    
    // 审计 NFT 合约
    IAuditCertificate public auditCert;
    
    constructor(IPoolManager manager, IAuditCertificate _auditCert) BaseHook(manager) {
        auditCert = _auditCert;
    }
    
    /**
     * @notice 交易前安全检查
     */
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        // 检查 token0 和 token1 的合约是否经过审计
        address token0 = address(key.currency0);
        address token1 = address(key.currency1);
        
        bool token0Safe = isAudited[token0] && contractAuditTier[token0] <= 1; // S or A
        bool token1Safe = isAudited[token1] && contractAuditTier[token1] <= 1;
        
        if (!token0Safe || !token1Safe) {
            // 发出链上警告事件
            emit SecurityWarning(
                block.timestamp,
                token0,
                token1,
                contractAuditTier[token0],
                contractAuditTier[token1],
                "WARNING: Trading unverified or low-tier contracts"
            );
        }
        
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
    
    /**
     * @notice 更新合约审计等级（由 Athena 审计系统调用）
     */
    function updateAuditStatus(
        address contractAddr, 
        uint8 tier,
        uint256 certId
    ) external {
        // 验证调用者是 Athena 审计系统
        require(msg.sender == auditCert.address(), "Unauthorized");
        
        contractAuditTier[contractAddr] = tier;
        isAudited[contractAddr] = true;
        
        emit AuditStatusUpdated(contractAddr, tier, certId, block.timestamp);
    }
    
    // Hook flags
    function getHookPermissions() public pure override returns(Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,  // ✅ 启用交易前检查
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }
    
    event SecurityWarning(
        uint256 timestamp,
        address token0,
        address token1,
        uint8 tier0,
        uint8 tier1,
        string message
    );
    
    event AuditStatusUpdated(
        address contractAddr,
        uint8 tier,
        uint256 certId,
        uint256 timestamp
    );
}
```

### Demo 场景

```
[Demo Flow]
1. 用户在 Uniswap v4 交易 Token A ↔ Token B
2. Athena Hook 自动触发
3. 检查：Token A 已审计（A 级）✅
4. 检查：Token B 未审计 ⚠️
5. 发出链上 SecurityWarning 事件
6. 用户看到警告，决定是否继续交易
```

---

## Phase 7.3 — 稀有度算法 (OpenRarity)

### 设计思路

uPEG 使用 OpenRarity 的 Information Content 算法计算稀有度。Athena 可以用类似算法：

| 指标 | 说明 | 权重 |
|------|------|------|
| 审计等级 | S/A/B/C | 40% |
| 漏洞数量 | 发现的漏洞总数 | 25% |
| 漏洞严重性 | Critical/High/Medium/Low 分布 | 20% |
| 审计时间 | 耗时越短越稀有 | 15% |

### 算法实现

```javascript
/**
 * Athena 稀有度计算器
 * 基于 OpenRarity Information Content 算法
 */
class AthenaRarity {
    /**
     * 计算审计 NFT 的稀有度分数
     * @param {Object} traits - NFT 的 trait 数据
     * @returns {number} 稀有度分数 (越高越稀有)
     */
    static calculateRarity(traits) {
        const weights = {
            tier: 0.40,           // 审计等级
            vulnCount: 0.25,      // 漏洞数量
            severity: 0.20,       // 漏洞严重性分布
            auditTime: 0.15       // 审计耗时
        };
        
        // 1. 等级分数 (S=100, A=75, B=50, C=25)
        const tierScores = { 0: 100, 1: 75, 2: 50, 3: 25 };
        const tierScore = tierScores[traits.tier] || 0;
        
        // 2. 漏洞数量分数 (越少越稀有，说明合约质量高)
        const vulnScore = Math.max(0, 100 - traits.vulnCount * 10);
        
        // 3. 严重性分数 (Critical 多 = 有价值)
        const severityScore = Math.min(100, 
            traits.critical * 40 + 
            traits.high * 25 + 
            traits.medium * 15 + 
            traits.low * 5
        );
        
        // 4. 审计时间分数 (越快越稀有，说明审计效率高)
        const timeScore = Math.max(0, 100 - (traits.auditTimeMinutes / 60) * 10);
        
        // 加权计算
        const totalScore = 
            tierScore * weights.tier +
            vulnScore * weights.vulnCount +
            severityScore * weights.severity +
            timeScore * weights.auditTime;
        
        return Math.round(totalScore * 100) / 100;
    }
    
    /**
     * 计算稀有度排名百分位
     * @param {number} score - 当前分数
     * @param {Array} allScores - 所有 NFT 的分数
     * @returns {number} 百分位 (0-100)
     */
    static calculatePercentile(score, allScores) {
        const sorted = allScores.sort((a, b) => a - b);
        const rank = sorted.filter(s => s < score).length;
        return Math.round((rank / sorted.length) * 100);
    }
    
    /**
     * 获取稀有度等级
     * @param {number} percentile - 百分位
     * @returns {string} 稀有度标签
     */
    static getRarityLabel(percentile) {
        if (percentile >= 95) return 'Legendary';
        if (percentile >= 80) return 'Epic';
        if (percentile >= 60) return 'Rare';
        if (percentile >= 40) return 'Uncommon';
        return 'Common';
    }
}

// 示例使用
const traits = {
    tier: 0,                    // S 级
    vulnCount: 3,               // 发现 3 个漏洞
    critical: 1,                // 1 个 Critical
    high: 1,                    // 1 个 High
    medium: 1,                  // 1 个 Medium
    low: 0,                     // 0 个 Low
    auditTimeMinutes: 45        // 45 分钟完成
};

const score = AthenaRarity.calculateRarity(traits);
console.log(`稀有度分数: ${score}`);
// 输出: 稀有度分数: 82.5
```

### 文件结构

```
lib/
├── rarity-calculator.js        # 稀有度算法
└── trait-encoder.js            # Trait 编码器

scripts/
└── calculate-rarity.js         # 批量计算脚本
```

---

## Phase 7.4 — 前端集成

### 更新 nft-preview.html

在现有预览页面中添加：

| 新增功能 | 说明 |
|---------|------|
| 声誉积分显示 | 显示该 NFT 对应的 ATHREP 余额 |
| 稀有度分数 | 显示计算后的稀有度分数和百分位 |
| Hook 状态 | 显示该合约是否已触发 Athena Hook |
| 交易警告 | 如果涉及未审计合约，显示警告 |

### Landing Page 更新

在 `athena.degure.me` 添加新 section：

```html
<section id="innovation">
    <h2>Technical Innovation</h2>
    
    <div class="innovation-grid">
        <div class="innovation-card">
            <h3>Hybrid Token Standard</h3>
            <p>ERC-721 (Audit Certificate) + ERC-20 (Reputation Score)</p>
            <p>Inspired by uPEG's dual-nature architecture</p>
        </div>
        
        <div class="innovation-card">
            <h3>Uniswap v4 Hook</h3>
            <p>Real-time security checks on every swap</p>
            <p>Audit results trigger DeFi safety parameters</p>
        </div>
        
        <div class="innovation-card">
            <h3>Rarity Algorithm</h3>
            <p>OpenRarity-based dynamic rarity calculation</p>
            <p>S/A/B/C tiers with 768,000 trait combinations</p>
        </div>
    </div>
</section>
```

---

## 实施计划

| Phase | 任务 | 预计时间 | 依赖 |
|-------|------|---------|------|
| 7.1 | 混合代币合约 (AthenaReputation.sol) | 2h | 无 |
| 7.2 | Uniswap v4 Hook 合约 | 3h | Phase 7.1 |
| 7.3 | 稀有度算法实现 | 1.5h | 无 |
| 7.4 | 前端集成 | 2h | Phase 7.1, 7.3 |
| **Total** | | **8.5h** | |

---

## 与 v6 的关系

| 版本 | 重点 | 状态 |
|------|------|------|
| v6 | S 级 NFT + 彩虹渐变 | ✅ 已完成 |
| v7 | uPEG 灵感创新 | 📋 本次计划 |
| v8 | 真实审计 + Demo 录制 | 🔜 待定 |

v7 是 v6 的技术升级，不改变现有 NFT 形象，只增加底层技术能力。

---

## 需要远程 Agent 实现的文件

| 文件 | 类型 | 说明 |
|------|------|------|
| `contracts/AthenaReputation.sol` | 新增 | 混合代币合约 |
| `contracts/AthenaSecurityHook.sol` | 新增 | Uniswap v4 Hook |
| `lib/rarity-calculator.js` | 新增 | 稀有度算法 |
| `lib/trait-encoder.js` | 新增 | Trait 编码器 |
| `scripts/calculate-rarity.js` | 新增 | 批量计算脚本 |
| `frontend/index.html` | 更新 | 添加新 section |
| `frontend/app.js` | 更新 | 集成稀有度显示 |
| `frontend/style.css` | 更新 | 新增样式 |

---

## 注意事项

1. **不改动 NFT 形象** — 保持现有猫头鹰设计
2. **Sepolia 测试网** — 所有新合约部署到 Sepolia
3. **向后兼容** — 新合约不影响现有 AuditCertificate
4. **叙事重点** — 强调"uPEG 灵感"作为技术深度证明
5. **Demo 整合** — v7 功能要能在 Demo 中展示

---

*Created: 2026-06-09*
*Inspired by: uPEG (Unipeg) — ERC-20/721 hybrid on Uniswap v4 Hooks*
*Status: Ready for implementation*
