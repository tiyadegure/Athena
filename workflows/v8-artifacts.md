# v8 — 项目产物生成（PPT 素材）

## 目标
基于项目当前状态（v7 完成），生成所有用于 PPT 和提交的产物。
**不含 demo 录屏**（用户手动做）。

---

## 产物清单

### 1. 合约产物
| 产物 | 路径 | 说明 |
|------|------|------|
| 合约 ABI | `out/AuditCertificate.sol/AuditCertificate.json` | 编译产物 |
| 测试结果 | `ppt-assets/test-results.txt` | 23/23 通过 |
| 审计报告 | `demo/report.json` | 完整审计报告 |

### 2. 前端产物
| 产物 | 路径 | 说明 |
|------|------|------|
| Landing Page | `frontend/landing.html` | 极简黑底白字 |
| 前端应用 | `frontend/index.html` + `app.js` + `style.css` | 审计报告展示 |
| NFT 预览 | `demo/nft-preview.html` | S/A/B/C 四级预览 |

### 3. 文档产物
| 产物 | 路径 | 说明 |
|------|------|------|
| 产品定位 | `docs/PRODUCT.md` | ToB/B2B 定位 |
| ZK 启发 | `docs/ZK-INSPIRATION.md` | 零知识证明启发 |
| PPT 大纲 | `ppt-assets/ppt-outline.md` | 10 页 slides |
| X 内容 | `docs/x-content.md` | 推文素材 |

### 4. SVG 图表
| 产物 | 路径 | 说明 |
|------|------|------|
| 架构图 | `ppt-assets/architecture.svg` | 系统架构 |
| MCP 工具图 | `ppt-assets/mcp-tools.svg` | 13 个工具 |
| Skill 图 | `ppt-assets/skill-agents.svg` | 12 个 agents |
| 审计报告图 | `ppt-assets/audit-report.svg` | 报告结构 |
| 链上验证图 | `ppt-assets/onchain-verification.svg` | 验证流程 |

### 5. NFT 图片
| 产物 | 路径 | 说明 |
|------|------|------|
| NFT 预览 | `ppt-assets/nft-preview.png` | 3 等级预览 |
| 金级 NFT | `ppt-assets/nft-gold.png` | 金级特写 |
| 银级 NFT | `ppt-assets/nft-silver.png` | 银级特写 |
| 前端截图 | `ppt-assets/frontend-screenshot.png` | 前端展示 |

---

## 执行步骤

### Step 1: 编译合约 + 跑测试
```bash
cd /root/projects/glm-code
forge build
forge test 2>&1 | tee /tmp/test-results.txt
```
产物: `out/AuditCertificate.sol/AuditCertificate.json`, 测试结果

### Step 2: 跑审计脚本生成报告
```bash
cd /root/projects/glm-code
./scripts/real-audit-v6.sh 2>&1 | tee /tmp/audit-output.txt
```
产物: `demo/report.json`

### Step 3: 收集测试结果
```bash
cd /root/projects/glm-code
cat /tmp/test-results.txt | grep -E "PASS|FAIL|Suite" > ppt-assets/test-results.txt
```
产物: `ppt-assets/test-results.txt`

### Step 4: 复制产物到 ppt-assets
```bash
cd /root/projects/glm-code
cp demo/report.json ppt-assets/report.json
cp frontend/landing.html ppt-assets/landing.html
```
产物: `ppt-assets/report.json`, `ppt-assets/landing.html`

### Step 5: 验证所有产物
```bash
cd /root/projects/glm-code
echo "=== 合约产物 ==="
ls -la out/AuditCertificate.sol/*.json

echo "=== 前端产物 ==="
ls -la frontend/*.html frontend/*.js frontend/*.css

echo "=== 文档产物 ==="
ls -la docs/*.md ppt-assets/*.md

echo "=== SVG 图表 ==="
ls -la ppt-assets/*.svg

echo "=== NFT 图片 ==="
ls -la ppt-assets/*.png demo/*.png

echo "=== 测试结果 ==="
cat ppt-assets/test-results.txt
```

---

## 产物汇总表

| 类别 | 文件数 | 说明 |
|------|--------|------|
| 合约 | 3 | ABI + 测试 + 审计报告 |
| 前端 | 5 | Landing + 应用 + NFT 预览 |
| 文档 | 4 | PRODUCT + ZK + PPT 大纲 + X 内容 |
| SVG | 5 | 架构图 + 工具图 + Skill 图 + 报告图 + 验证图 |
| NFT | 4 | 预览 + 金级 + 银级 + 前端截图 |
| **总计** | **21** | |

---

## 验证清单

- [ ] 合约编译成功
- [ ] 23/23 测试通过
- [ ] 审计报告生成
- [ ] Landing Page 可访问 (`athena.degure.me`)
- [ ] NFT 预览页可打开 (`demo/nft-preview.html`)
- [ ] 所有 SVG 图表生成
- [ ] 所有 NFT 图片生成
- [ ] PPT 大纲完整
- [ ] 产物收集到 `ppt-assets/`

---

## 后续步骤

产物生成后，用户手动：
1. 录制 Demo 视频（终端 + 浏览器 + 链上验证）
2. 制作 PPT（使用 `ppt-assets/` 素材）
3. 提交黑客松（GitHub + Demo + PPT + 描述）
