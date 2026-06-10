# v6 Workflow: S 级炫彩 NFT

## 概述

在现有 NFT 系统（Gold/Silver/Bronze）基础上，新增 **S 级（炫彩）** 等级，用于奖励最高质量的审计成果。

## 设计目标

1. **稀有度最高**：S 级是最稀有的等级
2. **视觉炫彩**：彩虹渐变色、动态效果
3. **触发条件严格**：只有最高质量审计才能获得

## S 级设计

### 触发条件

**方案 A：基于审计得分**
- 审计得分 100 分（满分）
- 所有漏洞都是 Critical 级别
- PoC 验证 100% 通过

**方案 B：基于漏洞组合**
- 发现 ≥3 个 Critical 漏洞
- 攻击模拟预计损失 ≥$10M
- 所有 PoC 都通过

**方案 C：基于链上验证**
- EAS attestation 被多个验证者确认
- 审计结果被协议方采纳
- 修复后无新漏洞

**推荐：方案 A**（最简单，最客观）

### 视觉设计

**S 级特殊效果：**
1. **彩虹渐变色**：背景颜色在 7 种颜色间循环
2. **动态光晕**：角色周围有呼吸灯效果
3. **稀有度标识**：S 级专属边框（金色 + 彩虹）
4. **特殊 trait**：S 级专属 trait 维度

**新增 trait 维度：**
- `aura`: 光晕类型（彩虹/星空/火焰/闪电）
- `crown`: 头饰类型（皇冠/光环/王冠/无）
- `wings`: 翅膀类型（天使/恶魔/龙/无）

**组合数量：**
- 现有：5×5×8×3×5×4 = 12,000
- 新增：4×4×4 = 64 种 S 级组合
- 总计：12,064 种组合

### 稀有度

**S 级稀有度计算：**
- 基础稀有度：1/12,064 ≈ 0.0083%
- 实际稀有度：取决于触发条件
- 预期：每 1000 次审计中约 1-5 次获得 S 级

## 技术实现

### 1. 合约修改

**文件：** `contracts/AuditCertificate.sol`

```solidity
// 新增 Token ID
uint256 public constant S_TIER = 4;

// 新增 trait 维度
uint8 constant AURA_VARIANTS = 4;      // 彩虹/星空/火焰/闪电
uint8 constant CROWN_VARIANTS = 4;     // 皇冠/光环/王冠/无
uint8 constant WINGS_VARIANTS = 4;     // 天使/恶魔/龙/无

// 更新 TraitData 结构
struct TraitData {
    uint8 helmet;
    uint8 shield;
    uint8 color;
    uint8 weapon;
    uint8 background;
    uint8 eyes;
    uint8 aura;      // 新增
    uint8 crown;     // 新增
    uint8 wings;     // 新增
    uint256 rarityScore;
}

// 新增 S 级判断逻辑
function _isSTier(uint8 severity, uint256 auditScore) internal pure returns (bool) {
    return auditScore == 100 && severity == 1; // 100 分 + Critical 漏洞
}

// 更新 _selectTraits 函数
function _selectTraits(bytes32 uid) internal view returns (TraitData memory) {
    bytes32 hash = keccak256(abi.encodePacked(uid));
    
    uint8 helmet = uint8(hash[0]) % HELMET_VARIANTS;
    uint8 shield = uint8(hash[1]) % SHIELD_VARIANTS;
    uint8 color = uint8(hash[2]) % COLOR_VARIANTS;
    uint8 weapon = uint8(hash[3]) % WEAPON_VARIANTS;
    uint8 bg = uint8(hash[4]) % BG_VARIANTS;
    uint8 eyes = uint8(hash[5]) % EYES_VARIANTS;
    uint8 aura = uint8(hash[6]) % AURA_VARIANTS;      // 新增
    uint8 crown = uint8(hash[7]) % CROWN_VARIANTS;    // 新增
    uint8 wings = uint8(hash[8]) % WINGS_VARIANTS;    // 新增
    
    uint256 rarity = _calculateRarity(helmet, shield, color, weapon, bg, eyes, aura, crown, wings);
    
    return TraitData({
        helmet: helmet,
        shield: shield,
        color: color,
        weapon: weapon,
        background: bg,
        eyes: eyes,
        aura: aura,
        crown: crown,
        wings: wings,
        rarityScore: rarity
    });
}
```

### 2. SVG 生成

**S 级 SVG 特效：**

```solidity
function _generateSTierSVG(TraitData memory traits) internal pure returns (string memory) {
    // 彩虹渐变背景
    string memory rainbowBg = `
        <defs>
            <linearGradient id="rainbow" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:#ff0000"/>
                <stop offset="16%" style="stop-color:#ff8800"/>
                <stop offset="33%" style="stop-color:#ffff00"/>
                <stop offset="50%" style="stop-color:#00ff00"/>
                <stop offset="66%" style="stop-color:#0088ff"/>
                <stop offset="83%" style="stop-color:#8800ff"/>
                <stop offset="100%" style="stop-color:#ff0088"/>
            </linearGradient>
        </defs>
        <rect width="400" height="400" fill="url(#rainbow)"/>
    `;
    
    // 动态光晕效果
    string memory auraEffect = `
        <circle cx="200" cy="200" r="150" fill="none" stroke="#ffffff" stroke-width="2" opacity="0.5">
            <animate attributeName="r" values="150;160;150" dur="2s" repeatCount="indefinite"/>
            <animate attributeName="opacity" values="0.5;0.8;0.5" dur="2s" repeatCount="indefinite"/>
        </circle>
    `;
    
    // 组装 SVG
    return string(abi.encodePacked(
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 400 400'>",
        rainbowBg,
        auraEffect,
        // ... 其他 SVG 元素
        "</svg>"
    ));
}
```

### 3. 测试用例

**文件：** `contracts/test/AuditCertificate.t.sol`

```solidity
// 测试 S 级铸造
function test_mint_s_tier() public {
    // 创建 100 分 + Critical 漏洞的 attestation
    bytes32 fakeUID = keccak256(abi.encodePacked("s-tier-test"));
    
    // 铸造 S 级 NFT
    certificate.mintCertificate(user, fakeUID, 100, 1); // 100 分, severity=1(Critical)
    
    // 验证 Token ID
    assertEq(certificate.balanceOf(user, 4), 1); // S_TIER = 4
    
    // 验证 trait 数据
    AuditCertificate.TraitData memory traits = certificate.traitData(fakeUID);
    assertTrue(traits.aura < 4);
    assertTrue(traits.crown < 4);
    assertTrue(traits.wings < 4);
}

// 测试 S 级 SVG 生成
function test_s_tier_svg_contains_rainbow() public {
    bytes32 fakeUID = keccak256(abi.encodePacked("s-tier-svg-test"));
    certificate.mintCertificate(user, fakeUID, 100, 1);
    
    string memory svg = certificate.uri(4);
    assertTrue(bytes(svg).length > 0);
    // 验证包含彩虹渐变
    assertTrue(keccak256(bytes(svg)) != keccak256(bytes("")));
}
```

### 4. 前端更新

**文件：** `frontend/app.js`

```javascript
// 更新等级显示
function getTierLabel(tokenId) {
    switch(tokenId) {
        case 1: return 'S';
        case 2: return 'A';
        case 3: return 'B';
        case 4: return 'C';
        default: return '?';
    }
}

// 更新等级颜色
function getTierColor(tokenId) {
    switch(tokenId) {
        case 1: return '#ff0000'; // S 红色（炫彩）
        case 2: return '#ffd700'; // A 金色
        case 3: return '#c0c0c0'; // B 银色
        case 4: return '#cd7f32'; // C 铜色
        default: return '#666666';
    }
}
```

## 实施步骤

### Phase 1: 合约修改
1. 更新 `AuditCertificate.sol`
   - 新增 S_TIER 常量
   - 新增 3 个 trait 维度
   - 更新 TraitData 结构
   - 新增 S 级判断逻辑
   - 更新 SVG 生成函数
2. 更新测试用例
3. 运行测试

### Phase 2: 前端更新
1. 更新 `frontend/app.js`
   - 新增 S 级等级显示
   - 更新 SVG 渲染逻辑
2. 更新 NFT 预览页面
   - 新增 S 级预览
   - 展示炫彩效果

### Phase 3: 重新部署
1. 编译合约
2. 部署到 Sepolia
3. 验证 S 级铸造
4. 更新 PPT 素材

### Phase 4: 文档更新
1. 更新 README.md
2. 更新 PPT 大纲
3. 更新 Demo 脚本

## 时间估算

- Phase 1: 2-3 小时（合约 + 测试）
- Phase 2: 1-2 小时（前端）
- Phase 3: 30 分钟（部署）
- Phase 4: 30 分钟（文档）

**总计：4-6 小时**

## 风险评估

1. **合约复杂度增加**：新增 3 个 trait 维度，SVG 生成更复杂
2. **Gas 成本增加**：S 级铸造 gas 成本可能更高
3. **测试覆盖**：需要充分测试 S 级逻辑
4. **前端兼容**：需要确保前端能正确渲染 S 级

