const pptxgen = require("pptxgenjs");
const sharp = require("sharp");
const path = require("path");

// Image paths
const IMAGES = {
  avatar: "/root/projects/glm-code/frontend/images/avatar.png",
  nftSTier: "/root/projects/glm-code/frontend/images/nft-s-tier.png",
  auditReportSvg: "/root/projects/glm-code/ppt-assets/audit-report.svg",
  onchainVerificationSvg: "/root/projects/glm-code/ppt-assets/onchain-verification.svg",
  architectureSvg: "/root/projects/glm-code/ppt-assets/architecture.svg",
  skillAgentsSvg: "/root/projects/glm-code/ppt-assets/skill-agents.svg",
  mcpToolsSvg: "/root/projects/glm-code/ppt-assets/mcp-tools.svg",
};

// Pre-convert SVGs to PNG
async function convertSvgToPng(svgPath, pngPath, width) {
  try {
    await sharp(svgPath)
      .resize(width)
      .png()
      .toFile(pngPath);
    console.log(`Converted: ${svgPath} -> ${pngPath}`);
    return pngPath;
  } catch (err) {
    console.error(`Failed to convert ${svgPath}:`, err.message);
    return null;
  }
}

const pres = new pptxgen();
pres.layout = 'LAYOUT_16x9';
pres.author = 'Tiya Degurechaff';
pres.title = 'Athena — Web3 Security Audit Agent';

// Color palette - Landing Page (monochrome)
const COLORS = {
  bg: '000000',      // pure black (matches landing page)
  bgLight: '0A0A0A', // very dark (slight contrast)
  primary: 'FFFFFF',  // white
  secondary: '666666', // gray (matches landing page #666)
  accent: '333333',   // dark gray (thin borders, not blue)
  gold: 'D4A535',     // gold (keep for NFT)
  green: '888888',    // muted gray (not bright green)
  red: '888888',      // muted gray (not bright red)
  orange: '888888',   // muted
  yellow: '888888',   // muted
  blue: '888888',     // muted
};

// Helper: add footer
function addFooter(slide) {
  slide.addText('Athena · Z.AI Hackathon · GLM-5.1', {
    x: 0.5, y: 5.2, w: 9, h: 0.3,
    fontSize: 10, color: COLORS.secondary, align: 'center'
  });
}

(async () => {
  // Convert SVGs to PNGs first
  const auditReportPng = path.join(__dirname, 'audit-report.png');
  const onchainVerificationPng = path.join(__dirname, 'onchain-verification.png');
  const architecturePng = path.join(__dirname, 'architecture.png');
  const skillAgentsPng = path.join(__dirname, 'skill-agents.png');
  const mcpToolsPng = path.join(__dirname, 'mcp-tools.png');
  
  await Promise.all([
    convertSvgToPng(IMAGES.auditReportSvg, auditReportPng, 400),
    convertSvgToPng(IMAGES.onchainVerificationSvg, onchainVerificationPng, 400),
    convertSvgToPng(IMAGES.architectureSvg, architecturePng, 1600),
    convertSvgToPng(IMAGES.skillAgentsSvg, skillAgentsPng, 1600),
    convertSvgToPng(IMAGES.mcpToolsSvg, mcpToolsPng, 1600),
  ]);
  
  // Update image paths if conversion succeeded
  if (require('fs').existsSync(auditReportPng)) {
    IMAGES.auditReport = auditReportPng;
  }
  if (require('fs').existsSync(onchainVerificationPng)) {
    IMAGES.onchainVerification = onchainVerificationPng;
  }
  if (require('fs').existsSync(architecturePng)) {
    IMAGES.architecture = architecturePng;
  }
  if (require('fs').existsSync(skillAgentsPng)) {
    IMAGES.skillAgents = skillAgentsPng;
  }
  if (require('fs').existsSync(mcpToolsPng)) {
    IMAGES.mcpTools = mcpToolsPng;
  }

  // --- Slides (created AFTER SVG→PNG conversion) ---

  // Slide 1 — Cover
  let slide1 = pres.addSlide();
slide1.background = { color: COLORS.bg };
// Slide 1 — Avatar image (centered above title)
slide1.addImage({
  path: IMAGES.avatar,
  x: 4.25, y: 0.3, w: 1.5, h: 1.5,
  rounding: true,
});
slide1.addText('ATHENA', {
  x: 0.5, y: 1.5, w: 9, h: 1.5,
  fontSize: 72, fontFace: 'Courier New', color: COLORS.primary,
  bold: true, align: 'center', charSpacing: 8
});
slide1.addText('Web3 Security Audit Agent', {
  x: 0.5, y: 2.5, w: 9, h: 0.8,
  fontSize: 28, fontFace: 'Courier New', color: COLORS.accent,
  align: 'center'
});
slide1.addText('基于 GLM-5.1 长程任务能力的 Web3 安全审计闭环', {
  x: 0.5, y: 3.2, w: 9, h: 0.6,
  fontSize: 16, fontFace: 'Courier New', color: COLORS.secondary,
  align: 'center'
});
slide1.addText('Z.AI 赛道 · Tiya Degurechaff', {
  x: 0.5, y: 3.8, w: 9, h: 0.5,
  fontSize: 14, fontFace: 'Courier New', color: COLORS.secondary,
  align: 'center'
});
addFooter(slide1);

// Slide 2 — Problem
let slide2 = pres.addSlide();
slide2.background = { color: COLORS.bg };
slide2.addText('Web3 安全审计的现状', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Courier New', color: COLORS.primary,
  bold: true, align: 'left'
});
slide2.addText([
  { text: '人工审计', options: { bold: true, breakLine: true } },
  { text: '慢（2-4周）、贵（$5万+）、易遗漏', options: { breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: 'AI 审计', options: { bold: true, breakLine: true } },
  { text: '单步推理、无链上验证、无证据链', options: { breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: 'Agent 经济雏形', options: { bold: true, breakLine: true } },
  { text: 'AI Agent 可以自主完成审计，但缺乏闭环', options: {} },
], {
  x: 0.5, y: 1.3, w: 9, h: 3.0,
  fontSize: 16, fontFace: 'Courier New', color: COLORS.secondary,
  align: 'left', valign: 'top'
});
slide2.addShape(pres.shapes.RECTANGLE, {
  x: 0.5, y: 4.3, w: 9, h: 0.8,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.accent, width: 1 }
});
slide2.addText('核心问题：如何让 AI Agent 完成从漏洞发现到链上认证的完整闭环？', {
  x: 0.7, y: 4.4, w: 8.6, h: 0.6,
  fontSize: 14, fontFace: 'Courier New', color: COLORS.accent,
  bold: true, align: 'center'
});
addFooter(slide2);

// Slide 3 — GLM-5.1
let slide3 = pres.addSlide();
slide3.background = { color: COLORS.bg };
slide3.addText('为什么是 GLM-5.1？', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Courier New', color: COLORS.primary,
  bold: true, align: 'left'
});
// Left column - normal LLM
slide3.addShape(pres.shapes.RECTANGLE, {
  x: 0.5, y: 1.3, w: 4.2, h: 3.5,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.secondary, width: 1 }
});
slide3.addText('普通 LLM（单步推理）', {
  x: 0.7, y: 1.4, w: 3.8, h: 0.5,
  fontSize: 16, fontFace: 'Courier New', color: COLORS.secondary,
  bold: true, align: 'center'
});
slide3.addText([
  { text: '× 需要多次人工介入', options: { breakLine: true } },
  { text: '× 无法跨步骤传递上下文', options: { breakLine: true } },
  { text: '× 无法协调多个工具', options: {} },
], {
  x: 0.7, y: 2.0, w: 3.8, h: 2.5,
  fontSize: 14, fontFace: 'Courier New', color: COLORS.red,
  align: 'left', valign: 'top'
});
// Right column - GLM-5.1
slide3.addShape(pres.shapes.RECTANGLE, {
  x: 5.3, y: 1.3, w: 4.2, h: 3.5,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.accent, width: 2 }
});
slide3.addText('GLM-5.1（长程推理）', {
  x: 5.5, y: 1.4, w: 3.8, h: 0.5,
  fontSize: 16, fontFace: 'Courier New', color: COLORS.accent,
  bold: true, align: 'center'
});
slide3.addText([
  { text: '✓ 单次会话完成 8 步审计闭环', options: { breakLine: true } },
  { text: '✓ 200K 上下文，跨步骤记忆', options: { breakLine: true } },
  { text: '✓ 协调 13 个 MCP 工具', options: { breakLine: true } },
  { text: '✓ 驱动 12 个并行 Agent', options: {} },
], {
  x: 5.5, y: 2.0, w: 3.8, h: 2.5,
  fontSize: 14, fontFace: 'Courier New', color: COLORS.green,
  align: 'left', valign: 'top'
});
addFooter(slide3);

// Slide 4 — Architecture
let slide4 = pres.addSlide();
slide4.background = { color: COLORS.bg };
slide4.addText('8 步审计闭环架构', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Courier New', color: COLORS.primary,
  bold: true, align: 'left'
});
// Architecture diagram image
slide4.addImage({
  path: IMAGES.architecture,
  x: 0.5, y: 1.2, w: 9, h: 3.8,
});
addFooter(slide4);

// Slide 5 — 12 Agents
let slide5 = pres.addSlide();
slide5.background = { color: COLORS.bg };
slide5.addText('12 Agent 审计 Skill', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Courier New', color: COLORS.primary,
  bold: true, align: 'left'
});
// 12 Agents diagram image
slide5.addImage({
  path: IMAGES.skillAgents,
  x: 0.5, y: 1.2, w: 9, h: 3.8,
});
addFooter(slide5);

// Slide 6 — 13 MCP Tools
let slide6 = pres.addSlide();
slide6.background = { color: COLORS.bg };
slide6.addText('13 MCP 工具', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Courier New', color: COLORS.primary,
  bold: true, align: 'left'
});
// 13 MCP Tools diagram image
slide6.addImage({
  path: IMAGES.mcpTools,
  x: 0.5, y: 1.2, w: 9, h: 3.8,
});
addFooter(slide6);

// Slide 7 — Audit Report (real data)
let slide7 = pres.addSlide();
slide7.background = { color: COLORS.bg };
slide7.addText('审计报告 + 链上验证', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 28, fontFace: 'Courier New', color: COLORS.primary,
  bold: true, align: 'left'
});
// Report summary (left side)
slide7.addShape(pres.shapes.RECTANGLE, {
  x: 0.5, y: 1.2, w: 4.2, h: 4.0,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.accent, width: 1 }
});
slide7.addText('审计报告：DeFi Protocol', {
  x: 0.7, y: 1.3, w: 3.8, h: 0.5,
  fontSize: 14, fontFace: 'Courier New', color: COLORS.accent,
  bold: true, align: 'center'
});
slide7.addText([
  { text: '安全评分：2/10', options: { bold: true, color: COLORS.red, breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: '漏洞发现（5 个）：', options: { bold: true, breakLine: true } },
  { text: '● Critical: Reentrancy (Vault.withdraw) 95%', options: { color: COLORS.red, breakLine: true } },
  { text: '● High: Oracle 价格操纵 90%', options: { color: COLORS.orange, breakLine: true } },
  { text: '● High: 缺少访问控制 88%', options: { color: COLORS.orange, breakLine: true } },
  { text: '● Medium: 整数溢出 80%', options: { color: COLORS.yellow, breakLine: true } },
  { text: '● Low: 未初始化存储 70%', options: { color: COLORS.blue, breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: '攻击模拟：$2.3M 预计损失', options: { breakLine: true } },
  { text: 'PoC 验证：Foundry 256 runs ✓', options: {} },
], {
  x: 0.7, y: 1.8, w: 3.8, h: 3.2,
  fontSize: 10, fontFace: 'Courier New', color: COLORS.secondary,
  align: 'left', valign: 'top'
});
// On-chain verification (right side)
slide7.addShape(pres.shapes.RECTANGLE, {
  x: 5.3, y: 1.2, w: 4.2, h: 4.0,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.gold, width: 2 }
});
slide7.addText('链上认证（EAS）', {
  x: 5.5, y: 1.3, w: 3.8, h: 0.5,
  fontSize: 14, fontFace: 'Courier New', color: COLORS.gold,
  bold: true, align: 'center'
});
slide7.addText([
  { text: '✓ 不可篡改 · 可验证 · 可追溯', options: { breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: 'EAS Attestation UID:', options: { bold: true, breakLine: true } },
  { text: '0xd02800c960f18f...', options: { breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: '合约：0x3247d57d...', options: { breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: 'Sepolia 测试网', options: { breakLine: true } },
  { text: '零成本验证', options: { breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: '查看验证 →', options: { color: COLORS.accent, breakLine: true } },
  { text: 'sepolia.easscan.org', options: { color: COLORS.accent, fontSize: 8 } },
], {
  x: 5.5, y: 1.8, w: 3.8, h: 3.2,
  fontSize: 11, fontFace: 'Courier New', color: COLORS.green,
  align: 'left', valign: 'top'
});
addFooter(slide7);

// Slide 8 — NFT (real data)
let slide8 = pres.addSlide();
slide8.background = { color: COLORS.bg };
slide8.addText('Generative NFT 审计证书', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 28, fontFace: 'Courier New', color: COLORS.primary,
  bold: true, align: 'left'
});
// NFT image (centered)
slide8.addImage({
  path: IMAGES.nftSTier,
  x: 3.0, y: 1.2, w: 4.0, h: 3.9,
});
// NFT details overlay
slide8.addText([
  { text: 'S-TIER · Gold NFT', options: { bold: true, fontSize: 16, color: COLORS.gold } },
], {
  x: 3.0, y: 5.0, w: 4.0, h: 0.4,
  fontFace: 'Courier New', align: 'center'
});
// Left info panel
slide8.addShape(pres.shapes.RECTANGLE, {
  x: 0.3, y: 1.2, w: 2.5, h: 3.9,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.gold, width: 1 }
});
slide8.addText([
  { text: '262,144', options: { bold: true, fontSize: 20, color: COLORS.gold, breakLine: true } },
  { text: 'Trait 组合', options: { fontSize: 10, color: COLORS.secondary, breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: 'S/A/B/C 四级', options: { bold: true, fontSize: 12, color: COLORS.primary, breakLine: true } },
  { text: 'OpenRarity 算法', options: { fontSize: 10, color: COLORS.secondary, breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: 'Token #1', options: { bold: true, fontSize: 12, color: COLORS.gold, breakLine: true } },
  { text: '已铸造', options: { fontSize: 10, color: COLORS.green } },
], {
  x: 0.5, y: 1.5, w: 2.1, h: 3.2,
  fontFace: 'Courier New', align: 'center', valign: 'top'
});
// Right info panel
slide8.addShape(pres.shapes.RECTANGLE, {
  x: 7.2, y: 1.2, w: 2.5, h: 3.9,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.accent, width: 1 }
});
slide8.addText([
  { text: 'Sepolia', options: { bold: true, fontSize: 14, color: COLORS.accent, breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: 'ERC-1155', options: { fontSize: 10, color: COLORS.secondary, breakLine: true } },
  { text: 'ERC-20 ART', options: { fontSize: 10, color: COLORS.secondary, breakLine: true } },
  { text: 'EAS 认证', options: { fontSize: 10, color: COLORS.secondary, breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: '0x3247...', options: { fontSize: 8, color: COLORS.secondary, breakLine: true } },
  { text: 'd57d37bd', options: { fontSize: 8, color: COLORS.secondary } },
], {
  x: 7.4, y: 1.5, w: 2.1, h: 3.2,
  fontFace: 'Courier New', align: 'center', valign: 'top'
});
addFooter(slide8);

// Slide 9 — Agent Economy
let slide9 = pres.addSlide();
slide9.background = { color: COLORS.bg };
slide9.addText('Agent 经济的完整闭环', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Courier New', color: COLORS.primary,
  bold: true, align: 'left'
});
// Current mode
slide9.addShape(pres.shapes.RECTANGLE, {
  x: 0.5, y: 1.3, w: 4.2, h: 3.5,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.accent, width: 1 }
});
slide9.addText('当前模式（人类触发）', {
  x: 0.7, y: 1.4, w: 3.8, h: 0.5,
  fontSize: 14, fontFace: 'Courier New', color: COLORS.accent,
  bold: true, align: 'center'
});
slide9.addText([
  { text: '1. 项目方提交合约', options: { breakLine: true } },
  { text: '2. Agent 自主审计', options: { breakLine: true } },
  { text: '3. 结果自动上链（EAS）', options: { breakLine: true } },
  { text: '4. NFT 自动铸造', options: { breakLine: true } },
  { text: '5. 项目方支付费用', options: {} },
], {
  x: 0.7, y: 2.0, w: 3.8, h: 2.5,
  fontSize: 12, fontFace: 'Courier New', color: COLORS.secondary,
  align: 'left', valign: 'top'
});
// Future mode
slide9.addShape(pres.shapes.RECTANGLE, {
  x: 5.3, y: 1.3, w: 4.2, h: 3.5,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.gold, width: 2 }
});
slide9.addText('未来模式（Agent 自主）', {
  x: 5.5, y: 1.4, w: 3.8, h: 0.5,
  fontSize: 14, fontFace: 'Courier New', color: COLORS.gold,
  bold: true, align: 'center'
});
slide9.addText([
  { text: '1. Agent 监控链上新合约', options: { breakLine: true } },
  { text: '2. 自动审计', options: { breakLine: true } },
  { text: '3. 结果自动上链', options: { breakLine: true } },
  { text: '4. NFT 自动铸造 → 挂单', options: { breakLine: true } },
  { text: '5. 收入进入 Agent 钱包', options: { breakLine: true } },
  { text: '6. Agent 购买其他 Agent 服务', options: {} },
], {
  x: 5.5, y: 2.0, w: 3.8, h: 2.5,
  fontSize: 12, fontFace: 'Courier New', color: COLORS.green,
  align: 'left', valign: 'top'
});
slide9.addText('这是 Web3 Agent 经济的雏形。', {
  x: 0.5, y: 4.9, w: 9, h: 0.4,
  fontSize: 14, fontFace: 'Courier New', color: COLORS.gold,
  bold: true, align: 'center'
});
addFooter(slide9);

// Slide 10 — Summary & Roadmap
let slide10 = pres.addSlide();
slide10.background = { color: COLORS.bg };
slide10.addText('Athena 的价值', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Courier New', color: COLORS.primary,
  bold: true, align: 'left'
});
// Core values
slide10.addShape(pres.shapes.RECTANGLE, {
  x: 0.5, y: 1.3, w: 9, h: 2.0,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.accent, width: 1 }
});
slide10.addText([
  { text: '核心价值', options: { bold: true, breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: '• GLM-5.1 长程任务能力 → Agent 可以自主完成复杂任务', options: { breakLine: true } },
  { text: '• Web3 审计闭环 → Agent 经济的完整展示', options: { breakLine: true } },
  { text: '• 链上认证 → Agent 产出可验证、可交易', options: {} },
], {
  x: 0.7, y: 1.4, w: 8.6, h: 1.8,
  fontSize: 14, fontFace: 'Courier New', color: COLORS.secondary,
  align: 'left', valign: 'top'
});
// Roadmap
slide10.addShape(pres.shapes.RECTANGLE, {
  x: 0.5, y: 3.5, w: 9, h: 1.8,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.gold, width: 1 }
});
slide10.addText([
  { text: 'Roadmap', options: { bold: true, breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: '• ZK 隐私审计（v2）', options: { breakLine: true } },
  { text: '• 多链部署（Ethereum、Base、Arbitrum）', options: { breakLine: true } },
  { text: '• Agent 审计市场（Agent ↔ Agent 交易）', options: { breakLine: true } },
  { text: '• 真实协议审计（Curve、Aave）', options: {} },
], {
  x: 0.7, y: 3.6, w: 8.6, h: 1.6,
  fontSize: 14, fontFace: 'Courier New', color: COLORS.secondary,
  align: 'left', valign: 'top'
});
slide10.addText('感谢 Z.AI 赛道支持！', {
  x: 0.5, y: 5.0, w: 9, h: 0.4,
  fontSize: 16, fontFace: 'Courier New', color: COLORS.gold,
  bold: true, align: 'center'
});
addFooter(slide10);

  await pres.writeFile({ fileName: "/root/projects/glm-code/ppt-assets/Athena-Hackathon.pptx" })
    .then(() => console.log("PPT created: /root/projects/glm-code/ppt-assets/Athena-Hackathon.pptx"))
    .catch(err => console.error("Error:", err));
})();
