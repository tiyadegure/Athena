# v7 — uPEG 技术升级

## 目标
借鉴 uPEG (Unipeg) 的技术特点，升级 Athena 审计 NFT 合约，实现：
- ERC-404 混合代币标准（可分割声誉 + 不可分割证书）
- 动态稀有度算法（OpenRarity 风格）
- 链上 SVG 生成优化

---

## Phase 1: ERC-404 混合代币标准

### 1.1 技术背景
uPEG 使用 Uniswap v4 Hooks 实现 ERC-20 + ERC-721 混合。Athena 可以使用 ERC-404 标准达到类似效果。

### 1.2 核心特性
| 功能 | 说明 |
|------|------|
| **可分割声誉** | 审计声誉代币 (ART) 可以分割、交易、组合 |
| **不可分割证书** | 审计 NFT 保持唯一性，不可分割 |
| **自动转换** | 持有足够 ART 自动铸造 NFT，销毁 NFT 自动释放 ART |

### 1.3 实现步骤
1. **集成 ERC-404 标准库**
   - 使用 `dn-404` 或 `ERC404` 开源实现
   - 修改 `AuditCertificate.sol` 继承 ERC-404

2. **定义声誉代币 (ART)**
   - 名称: Athena Reputation Token
   - 符号: ART
   - 精度: 18 位
   - 总供应量: 动态（基于审计数量）

3. **定义审计 NFT**
   - 名称: Athena Audit Certificate
   - 符号: AAC
   - 唯一性: 每次审计生成唯一 NFT
   - 关联: 与声誉代币绑定

4. **实现自动转换逻辑**
   - 当用户持有 >= 1000 ART 时，自动铸造 1 个 AAC NFT
   - 当用户销毁 1 个 AAC NFT 时，自动释放 1000 ART

### 1.4 合约修改
```solidity
// 新增文件: contracts/AuditReputationToken.sol
// 继承 ERC-404，实现声誉代币逻辑

// 修改文件: contracts/AuditCertificate.sol
// 继承 AuditReputationToken，实现审计 NFT 逻辑
```

---

## Phase 2: 动态稀有度算法

### 2.1 技术背景
uPEG 使用 OpenRarity Information Content 算法计算稀有度。Athena 可以借鉴这个方法，动态计算 S/A/B/C 四级稀有度。

### 2.2 算法设计
```python
# 稀有度计算公式 (OpenRarity Information Content)
rarity_score = -log2(trait_probability)

# 其中 trait_probability = trait_count / total_supply
# rarity_score 越高，稀有度越高
```

### 2.3 实现步骤
1. **定义 9 个 trait 维度**
   - Background (深蓝/紫/绿/红)
   - Body (金色/银/铜/铁)
   - Eyes (蓝/绿/红/金)
   - Crown (皇冠/角/羽毛/无)
   - Wings (龙翼/天使翼/蝙蝠翼/无)
   - Aura (光晕/火焰/冰霜/无)
   - Badge (盾牌/徽章/纹章/无)
   - Texture (条纹/点阵/渐变/纯色)
   - Accessory (项链/戒指/披风/无)

2. **计算每个 trait 的概率**
   - 每个 trait 有 4 种可能值
   - 总组合数: 4^9 = 262,144 种
   - 每种组合的初始概率: 1/262,144

3. **计算稀有度分数**
   - 使用 Information Content 公式
   - 分数越高，稀有度越高

4. **定义稀有度等级**
   | 等级 | 分数范围 | 比例 |
   |------|---------|------|
   | **S** | > 20 | ~1% |
   | **A** | 15-20 | ~9% |
   | **B** | 10-15 | ~30% |
   | **C** | < 10 | ~60% |

### 2.4 合约修改
```solidity
// 新增文件: contracts/RarityCalculator.sol
// 实现稀有度计算逻辑

// 修改文件: contracts/AuditCertificate.sol
// 在 mint 时调用 RarityCalculator 计算稀有度
// 将稀有度等级存储在 tokenURI 中
```

---

## Phase 3: 链上 SVG 生成优化

### 3.1 技术背景
uPEG 通过 `getSeedData(seed)` 解码 traits，然后生成 SVG。Athena 可以优化这个流程，提高生成效率。

### 3.2 优化方向
1. **种子数据结构优化**
   - 将 9 个 trait 压缩到 1 个 uint256 种子
   - 每个 trait 使用 2 位（4 种可能值）
   - 总共使用 18 位，剩余位可用于扩展

2. **SVG 模板优化**
   - 预定义 SVG 模板（S/A/B/C 四个等级）
   - 根据 trait 值动态组合 SVG 片段
   - 使用内联 CSS 减少 SVG 体积

3. **缓存机制**
   - 首次生成后缓存 SVG 结果
   - 使用 mapping 存储已生成的 SVG
   - 减少重复计算

### 3.3 实现步骤
1. **定义种子数据结构**
   ```solidity
   struct SeedData {
       uint8 background;  // 0-3
       uint8 body;        // 0-3
       uint8 eyes;        // 0-3
       uint8 crown;       // 0-3
       uint8 wings;       // 0-3
       uint8 aura;        // 0-3
       uint8 badge;       // 0-3
       uint8 texture;     // 0-3
       uint8 accessory;   // 0-3
   }
   ```

2. **实现种子解码函数**
   ```solidity
   function decodeSeed(uint256 seed) public pure returns (SeedData memory) {
       return SeedData({
           background: uint8(seed & 0x3),
           body: uint8((seed >> 2) & 0x3),
           eyes: uint8((seed >> 4) & 0x3),
           crown: uint8((seed >> 6) & 0x3),
           wings: uint8((seed >> 8) & 0x3),
           aura: uint8((seed >> 10) & 0x3),
           badge: uint8((seed >> 12) & 0x3),
           texture: uint8((seed >> 14) & 0x3),
           accessory: uint8((seed >> 16) & 0x3)
       });
   }
   ```

3. **实现 SVG 生成函数**
   ```solidity
   function generateSVG(uint256 seed) public view returns (string memory) {
       SeedData memory data = decodeSeed(seed);
       
       // 根据 data 生成 SVG
       // 使用模板 + 动态数据
       // 返回完整的 SVG 字符串
   }
   ```

4. **实现缓存机制**
   ```solidity
   mapping(uint256 => string) private svgCache;
   
   function getSVG(uint256 seed) public view returns (string memory) {
       if (bytes(svgCache[seed]).length == 0) {
           svgCache[seed] = generateSVG(seed);
       }
       return svgCache[seed];
   }
   ```

---

## Phase 4: 测试与验证

### 4.1 单元测试
1. **ERC-404 功能测试**
   - 测试声誉代币的铸造、销毁、转账
   - 测试审计 NFT 的自动铸造、销毁
   - 测试自动转换逻辑

2. **稀有度算法测试**
   - 测试稀有度计算准确性
   - 测试 S/A/B/C 四级分布
   - 测试边界条件

3. **SVG 生成测试**
   - 测试种子解码准确性
   - 测试 SVG 生成正确性
   - 测试缓存机制有效性

### 4.2 集成测试
1. **端到端审计流程**
   - 模拟完整审计流程
   - 测试从审计到 NFT 铸造的完整流程
   - 验证稀有度计算正确性

2. **性能测试**
   - 测试 SVG 生成 gas 消耗
   - 测试稀有度计算 gas 消耗
   - 优化 gas 效率

### 4.3 测试文件
```
contracts/test/
├── AuditReputationToken.test.js
├── AuditCertificate.test.js
├── RarityCalculator.test.js
└── SvgGenerator.test.js
```

---

## Phase 5: 部署与验证

### 5.1 部署步骤
1. **编译合约**
   ```bash
   npx hardhat compile
   ```

2. **运行测试**
   ```bash
   npx hardhat test
   ```

3. **部署到 Sepolia**
   ```bash
   npx hardhat run scripts/deploy-v7.js --network sepolia
   ```

4. **验证合约**
   ```bash
   npx hardhat verify --network sepolia <contract-address>
   ```

### 5.2 部署脚本
```javascript
// scripts/deploy-v7.js
async function main() {
  // 1. 部署 AuditReputationToken
  // 2. 部署 AuditCertificate (继承 AuditReputationToken)
  // 3. 部署 RarityCalculator
  // 4. 部署 SvgGenerator
  // 5. 配置合约关系
  // 6. 验证合约
}
```

### 5.3 验证清单
- [ ] 合约编译成功
- [ ] 所有测试通过
- [ ] 合约部署到 Sepolia
- [ ] 合约验证通过
- [ ] 前端集成测试通过
- [ ] 稀有度计算正确
- [ ] SVG 生成正常
- [ ] 缓存机制有效

---

## Phase 6: 文档与演示

### 6.1 技术文档
1. **ERC-404 集成文档**
   - 架构设计
   - 实现细节
   - 使用示例

2. **稀有度算法文档**
   - 算法原理
   - 计算公式
   - 优化策略

3. **SVG 生成文档**
   - 种子数据结构
   - SVG 模板设计
   - 缓存机制

### 6.2 演示视频
1. **Demo 脚本更新**
   - 新增 ERC-404 功能演示
   - 新增稀有度计算演示
   - 新增 SVG 生成演示

2. **视频录制**
   - 终端演示：合约交互
   - 浏览器演示：NFT 展示
   - 链上验证：Etherscan 查看

### 6.3 更新文件
- `README.md` — 更新技术特性
- `docs/PRODUCT.md` — 更新产品定位
- `AGENT-WORKFLOW.md` — 更新工作流
- `demo/nft-preview.html` — 更新 NFT 预览

---

## 技术要点

### ERC-404 vs uPEG Uniswap v4 Hook
| 特性 | ERC-404 | uPEG Hook |
|------|---------|-----------|
| **标准** | ERC-404 (实验性) | Uniswap v4 Hook |
| **兼容性** | 高（标准 ERC-20/721） | 低（需要 Uniswap v4） |
| **复杂度** | 中 | 高 |
| **Gas 效率** | 中 | 高 |
| **适用性** | 通用 | DeFi 专用 |

**选择 ERC-404 的原因：**
- 兼容性更好，不需要依赖 Uniswap v4
- 实现更简单，有成熟开源库
- 更适合审计 NFT 场景（非 DeFi 专用）

### 稀有度算法选择
| 算法 | 优点 | 缺点 |
|------|------|------|
| **OpenRarity IC** | 学术严谨，社区认可 | 计算复杂 |
| **简单概率** | 计算简单 | 不够精确 |
| **加权分数** | 灵活可调 | 需要手动调参 |

**选择 OpenRarity IC 的原因：**
- 与 uPEG 保持一致
- 学术严谨，稀有度分布合理
- 社区认可度高

---

## 预期成果

1. **技术升级**
   - ERC-404 混合代币标准
   - 动态稀有度算法
   - 链上 SVG 生成优化

2. **产品增强**
   - 可分割声誉代币
   - 动态稀有度等级
   - 优化的 NFT 生成

3. **竞争优势**
   - 技术先进性（借鉴 uPEG）
   - 功能完整性（审计+声誉+NFT）
   - 用户体验（动态稀有度+缓存优化）

---

## 风险与应对

| 风险 | 影响 | 应对措施 |
|------|------|---------|
| ERC-404 标准不稳定 | 合约兼容性问题 | 使用成熟开源库，充分测试 |
| 稀有度计算 gas 过高 | 用户体验差 | 优化算法，使用缓存 |
| SVG 生成 gas 过高 | 铸造成本高 | 使用模板+缓存，优化 SVG 体积 |
| 测试覆盖不足 | 合约漏洞 | 充分测试，代码审计 |

---

## 时间安排

| 阶段 | 任务 | 时间 |
|------|------|------|
| Phase 1 | ERC-404 集成 | 2 天 |
| Phase 2 | 稀有度算法 | 1 天 |
| Phase 3 | SVG 优化 | 1 天 |
| Phase 4 | 测试验证 | 1 天 |
| Phase 5 | 部署验证 | 0.5 天 |
| Phase 6 | 文档演示 | 0.5 天 |
| **总计** | | **6 天** |

---

## 参考资源

- [uPEG Rarity Explorer](https://upegrarity.com)
- [uPEG 合约](https://etherscan.io/address/0x44b28991b167582f18ba0259e0173176ca125505)
- [ERC-404 标准](https://erc404.fun/)
- [OpenRarity 算法](https://github.com/ProjectOpenSea/open-rarity)
- [dn-404 实现](https://github.com/Vectorized/dn-404)
