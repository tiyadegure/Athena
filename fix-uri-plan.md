# Fix: AuditCertificate uri() 返回空字符串

## 问题

`contracts/AuditCertificate.sol` 第 201 行的 `uri()` 函数硬编码返回空字符串，导致：
- OpenSea testnet 看不到 NFT 图像
- Etherscan tokenURI 为空
- 无法在浏览器中展示链上 SVG

当前代码：
```solidity
function uri(uint256 tokenId) public pure override returns (string memory) {
    require(tokenId >= GOLD && tokenId <= BRONZE, "Invalid token ID");
    return "";
}
```

`generateMetadata()` 函数已经能正确生成 SVG + JSON metadata，但 `uri()` 没有调用它。

## 修复方案

### 方案 A：uri() 直接调用 generateMetadata()（推荐）

修改 `uri()` 函数，让它接受一个 `bytes32 attestationUID` 参数，或者从链上存储中读取 tokenId 对应的 attestationUID。

**问题**：ERC-1155 标准的 `uri(uint256 tokenId)` 只接受一个参数，不能加 attestationUID。

### 方案 B：链上存储 attestationUID → tokenId 映射

1. 在合约中添加 `mapping(uint256 => bytes32) public tokenAttestation`
2. `mintCertificate()` 铸造时写入 `tokenAttestation[tokenId] = attestationUID`
3. `uri()` 从存储中读取 attestationUID，调用 `generateMetadata()`
4. `mintTest()` 也需要写入一个默认 attestationUID

### 方案 C：用 view 函数 + 前端调用

保持 `uri()` 不变（ERC-1155 标准兼容），前端通过 `generateMetadata(attestationUID, tokenId)` 获取 SVG。

**问题**：OpenSea/Etherscan 只读取 `uri()`，不读自定义函数，所以链上展示还是不行。

## 推荐方案：方案 B

### 改动点

1. **contracts/AuditCertificate.sol**
   - 添加 `mapping(uint256 => bytes32) public tokenAttestation`
   - 修改 `mintCertificate()`：铸造后写入 `tokenAttestation[tokenId] = attestationUID`
   - 修改 `mintTest()`：铸造后写入 `tokenAttestation[tokenId] = bytes32(0)`（测试用）
   - 修改 `uri()`：读取 `tokenAttestation[tokenId]`，如果非零则调用 `generateMetadata()`

2. **contracts/test/AuditCertificate.t.sol**
   - 更新测试，验证 `uri()` 返回非空字符串

3. **重新部署**
   - 部署新合约到 Sepolia
   - 更新 `frontend/app.js` 的 `NFT_CONTRACT` 地址
   - 更新 `demo/report.json` 的合约地址

4. **铸造测试 NFT**
   - 铸造 Gold NFT
   - 验证 `uri()` 返回完整 SVG metadata

## 注意事项

- `uri()` 是 pure 函数，改后需要变为 view 函数（读取存储）
- ERC-1155 标准允许 `uri()` 是 view 函数
- OpenSea 支持 `data:application/json;base64,...` 格式的 metadata
- metadata 中的 image 是 `data:image/svg+xml;base64,...`，OpenSea 支持
