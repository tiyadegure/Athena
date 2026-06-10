const pptxgen = require("pptxgenjs");

const pres = new pptxgen();
pres.layout = 'LAYOUT_16x9';
pres.author = 'Tiya Degurechaff';
pres.title = 'Athena — Web3 Security Audit Agent';

// Color palette - Midnight Executive
const COLORS = {
  bg: '0A0A0A',      // deep black
  bgLight: '1A1F3A', // dark navy
  primary: 'FFFFFF',  // white
  secondary: '888888', // gray
  accent: '4A90D9',   // blue
  gold: 'D4A535',     // gold
  green: '00FF00',    // green for checkmarks
  red: 'FF0000',      // red for critical
  orange: 'FF8800',   // orange for high
  yellow: 'FFFF00',   // yellow for medium
  blue: '0088FF',     // blue for low
};

// Helper: add footer
function addFooter(slide) {
  slide.addText('Athena · Z.AI Hackathon · GLM-5.1', {
    x: 0.5, y: 5.2, w: 9, h: 0.3,
    fontSize: 10, color: COLORS.secondary, align: 'center'
  });
}

// Slide 1 — Cover
let slide1 = pres.addSlide();
slide1.background = { color: COLORS.bg };
slide1.addText('ATHENA', {
  x: 0.5, y: 1.5, w: 9, h: 1.5,
  fontSize: 72, fontFace: 'Arial', color: COLORS.primary,
  bold: true, align: 'center', charSpacing: 8
});
slide1.addText('Web3 Security Audit Agent', {
  x: 0.5, y: 3.0, w: 9, h: 0.8,
  fontSize: 28, fontFace: 'Arial', color: COLORS.accent,
  align: 'center'
});
slide1.addText('基于 GLM-5.1 长程任务能力的 Web3 安全审计闭环', {
  x: 0.5, y: 3.8, w: 9, h: 0.6,
  fontSize: 16, fontFace: 'Arial', color: COLORS.secondary,
  align: 'center'
});
slide1.addText('Z.AI 赛道 · Tiya Degurechaff', {
  x: 0.5, y: 4.5, w: 9, h: 0.5,
  fontSize: 14, fontFace: 'Arial', color: COLORS.secondary,
  align: 'center'
});
addFooter(slide1);

// Slide 2 — Problem
let slide2 = pres.addSlide();
slide2.background = { color: COLORS.bg };
slide2.addText('Web3 安全审计的现状', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Arial', color: COLORS.primary,
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
  fontSize: 16, fontFace: 'Arial', color: COLORS.secondary,
  align: 'left', valign: 'top'
});
slide2.addShape(pres.shapes.RECTANGLE, {
  x: 0.5, y: 4.3, w: 9, h: 0.8,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.accent, width: 1 }
});
slide2.addText('核心问题：如何让 AI Agent 完成从漏洞发现到链上认证的完整闭环？', {
  x: 0.7, y: 4.4, w: 8.6, h: 0.6,
  fontSize: 14, fontFace: 'Arial', color: COLORS.accent,
  bold: true, align: 'center'
});
addFooter(slide2);

// Slide 3 — GLM-5.1
let slide3 = pres.addSlide();
slide3.background = { color: COLORS.bg };
slide3.addText('为什么是 GLM-5.1？', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Arial', color: COLORS.primary,
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
  fontSize: 16, fontFace: 'Arial', color: COLORS.secondary,
  bold: true, align: 'center'
});
slide3.addText([
  { text: '× 需要多次人工介入', options: { breakLine: true } },
  { text: '× 无法跨步骤传递上下文', options: { breakLine: true } },
  { text: '× 无法协调多个工具', options: {} },
], {
  x: 0.7, y: 2.0, w: 3.8, h: 2.5,
  fontSize: 14, fontFace: 'Arial', color: COLORS.red,
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
  fontSize: 16, fontFace: 'Arial', color: COLORS.accent,
  bold: true, align: 'center'
});
slide3.addText([
  { text: '✓ 单次会话完成 8 步审计闭环', options: { breakLine: true } },
  { text: '✓ 200K 上下文，跨步骤记忆', options: { breakLine: true } },
  { text: '✓ 协调 13 个 MCP 工具', options: { breakLine: true } },
  { text: '✓ 驱动 12 个并行 Agent', options: {} },
], {
  x: 5.5, y: 2.0, w: 3.8, h: 2.5,
  fontSize: 14, fontFace: 'Arial', color: COLORS.green,
  align: 'left', valign: 'top'
});
addFooter(slide3);

// Slide 4 — Architecture
let slide4 = pres.addSlide();
slide4.background = { color: COLORS.bg };
slide4.addText('8 步审计闭环架构', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Arial', color: COLORS.primary,
  bold: true, align: 'left'
});
// Architecture diagram placeholder
slide4.addShape(pres.shapes.RECTANGLE, {
  x: 0.5, y: 1.2, w: 9, h: 3.8,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.accent, width: 1 }
});
slide4.addText('GLM-5.1 推理引擎（中央协调）\n↓\n12 Agent 审计 Skill（并行执行）\n↓\n13 MCP 工具（链上+链下）\n↓\nSepolia 测试网（零成本验证）', {
  x: 1.0, y: 1.5, w: 8, h: 3.2,
  fontSize: 16, fontFace: 'Consolas', color: COLORS.primary,
  align: 'center', valign: 'middle'
});
addFooter(slide4);

// Slide 5 — 12 Agents
let slide5 = pres.addSlide();
slide5.background = { color: COLORS.bg };
slide5.addText('12 Agent 审计 Skill', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Arial', color: COLORS.primary,
  bold: true, align: 'left'
});
// 3 columns
const agentGroups = [
  { title: '基础分析', agents: ['Scope', 'Architecture', 'Access Control', 'Math'] },
  { title: '漏洞猎手', agents: ['Reentrancy', 'Oracle', 'Flash Loan', 'Logic'] },
  { title: '辅助/输出', agents: ['Gas', 'Frontend', 'PoC', 'Report'] },
];
agentGroups.forEach((group, i) => {
  const x = 0.5 + i * 3.1;
  slide5.addShape(pres.shapes.RECTANGLE, {
    x: x, y: 1.3, w: 2.8, h: 3.5,
    fill: { color: COLORS.bgLight },
    line: { color: COLORS.accent, width: 1 }
  });
  slide5.addText(group.title, {
    x: x + 0.1, y: 1.4, w: 2.6, h: 0.5,
    fontSize: 14, fontFace: 'Arial', color: COLORS.accent,
    bold: true, align: 'center'
  });
  slide5.addText(group.agents.map((a, j) => ({
    text: `• ${a}`,
    options: { breakLine: j < group.agents.length - 1 }
  })), {
    x: x + 0.2, y: 2.0, w: 2.4, h: 2.5,
    fontSize: 12, fontFace: 'Arial', color: COLORS.secondary,
    align: 'left', valign: 'top'
  });
});
slide5.addText('10 轮检查流程，GLM-5.1 协调', {
  x: 0.5, y: 4.9, w: 9, h: 0.4,
  fontSize: 12, fontFace: 'Arial', color: COLORS.secondary,
  align: 'center'
});
addFooter(slide5);

// Slide 6 — 13 MCP Tools
let slide6 = pres.addSlide();
slide6.background = { color: COLORS.bg };
slide6.addText('13 MCP 工具', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Arial', color: COLORS.primary,
  bold: true, align: 'left'
});
const toolGroups = [
  { title: '静态分析', tools: ['Slither', 'Aderyn', 'Halmos'] },
  { title: '攻击模拟', tools: ['PoC Generator', 'Exploit Simulator', 'Fuzz Runner'] },
  { title: '链上操作', tools: ['EAS Attest', 'Evidence Chain'] },
  { title: '高级功能', tools: ['Protocol Scanner', 'Repair Validator', 'Incremental Auditor', 'GEV Analyzer', 'Knowledge Base'] },
];
toolGroups.forEach((group, i) => {
  const x = 0.5 + i * 2.35;
  slide6.addShape(pres.shapes.RECTANGLE, {
    x: x, y: 1.3, w: 2.15, h: 3.5,
    fill: { color: COLORS.bgLight },
    line: { color: COLORS.accent, width: 1 }
  });
  slide6.addText(group.title, {
    x: x + 0.1, y: 1.4, w: 1.95, h: 0.5,
    fontSize: 12, fontFace: 'Arial', color: COLORS.accent,
    bold: true, align: 'center'
  });
  slide6.addText(group.tools.map((t, j) => ({
    text: `• ${t}`,
    options: { breakLine: j < group.tools.length - 1 }
  })), {
    x: x + 0.1, y: 2.0, w: 1.95, h: 2.5,
    fontSize: 10, fontFace: 'Arial', color: COLORS.secondary,
    align: 'left', valign: 'top'
  });
});
addFooter(slide6);

// Slide 7 — Audit Report
let slide7 = pres.addSlide();
slide7.background = { color: COLORS.bg };
slide7.addText('Agent 的产出：审计报告 + 链上验证', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 28, fontFace: 'Arial', color: COLORS.primary,
  bold: true, align: 'left'
});
// Report summary
slide7.addShape(pres.shapes.RECTANGLE, {
  x: 0.5, y: 1.3, w: 4.2, h: 3.5,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.accent, width: 1 }
});
slide7.addText('审计报告示例', {
  x: 0.7, y: 1.4, w: 3.8, h: 0.5,
  fontSize: 16, fontFace: 'Arial', color: COLORS.accent,
  bold: true, align: 'center'
});
slide7.addText([
  { text: 'DeFi Protocol Audit', options: { bold: true, breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: '5 个漏洞发现：', options: { breakLine: true } },
  { text: '• 1 Critical (Reentrancy)', options: { breakLine: true } },
  { text: '• 2 High (Oracle + Flash Loan)', options: { breakLine: true } },
  { text: '• 1 Medium (Access Control)', options: { breakLine: true } },
  { text: '• 1 Low (Gas Optimization)', options: { breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: '攻击模拟：$2.3M 预计损失', options: { breakLine: true } },
  { text: 'PoC 验证：Foundry 256 runs', options: {} },
], {
  x: 0.7, y: 2.0, w: 3.8, h: 2.5,
  fontSize: 12, fontFace: 'Arial', color: COLORS.secondary,
  align: 'left', valign: 'top'
});
// On-chain verification
slide7.addShape(pres.shapes.RECTANGLE, {
  x: 5.3, y: 1.3, w: 4.2, h: 3.5,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.gold, width: 2 }
});
slide7.addText('链上认证（EAS）', {
  x: 5.5, y: 1.4, w: 3.8, h: 0.5,
  fontSize: 16, fontFace: 'Arial', color: COLORS.gold,
  bold: true, align: 'center'
});
slide7.addText([
  { text: '✓ 不可篡改', options: { breakLine: true } },
  { text: '✓ 可验证', options: { breakLine: true } },
  { text: '✓ 可追溯', options: { breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: 'Sepolia 测试网', options: { breakLine: true } },
  { text: '零成本验证', options: {} },
], {
  x: 5.5, y: 2.0, w: 3.8, h: 2.5,
  fontSize: 14, fontFace: 'Arial', color: COLORS.green,
  align: 'left', valign: 'top'
});
addFooter(slide7);

// Slide 8 — NFT
let slide8 = pres.addSlide();
slide8.background = { color: COLORS.bg };
slide8.addText('Agent 的经济产出：Generative NFT', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 28, fontFace: 'Arial', color: COLORS.primary,
  bold: true, align: 'left'
});
slide8.addShape(pres.shapes.RECTANGLE, {
  x: 0.5, y: 1.3, w: 9, h: 3.8,
  fill: { color: COLORS.bgLight },
  line: { color: COLORS.gold, width: 2 }
});
slide8.addText([
  { text: 'uPEG 启发 Seed-based Generative 雅典娜', options: { bold: true, breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: '• uint256 18-bit seed → 9 traits x 2 bits', options: { breakLine: true } },
  { text: '• 4^9 = 262,144 种组合', options: { breakLine: true } },
  { text: '• S/A/B/C 四级稀有度', options: { breakLine: true } },
  { text: '• 动态稀有度：OpenRarity 算法', options: { breakLine: true } },
  { text: '• SVG 缓存机制：减少 gas', options: { breakLine: true } },
  { text: '• ART 声誉代币（ERC-20）：1000 ART = 1 NFT', options: { breakLine: true } },
  { text: '', options: { breakLine: true } },
  { text: 'Sepolia: 0x4F541D6f6249deAE5cDa2B00625d6933E4943b3c', options: { breakLine: true } },
  { text: 'EAS + ERC-1155 + ERC-20', options: {} },
], {
  x: 1.0, y: 1.5, w: 8, h: 3.4,
  fontSize: 14, fontFace: 'Consolas', color: COLORS.secondary,
  align: 'left', valign: 'top'
});
addFooter(slide8);

// Slide 9 — Agent Economy
let slide9 = pres.addSlide();
slide9.background = { color: COLORS.bg };
slide9.addText('Agent 经济的完整闭环', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Arial', color: COLORS.primary,
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
  fontSize: 14, fontFace: 'Arial', color: COLORS.accent,
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
  fontSize: 12, fontFace: 'Arial', color: COLORS.secondary,
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
  fontSize: 14, fontFace: 'Arial', color: COLORS.gold,
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
  fontSize: 12, fontFace: 'Arial', color: COLORS.green,
  align: 'left', valign: 'top'
});
slide9.addText('这是 Web3 Agent 经济的雏形。', {
  x: 0.5, y: 4.9, w: 9, h: 0.4,
  fontSize: 14, fontFace: 'Arial', color: COLORS.gold,
  bold: true, align: 'center'
});
addFooter(slide9);

// Slide 10 — Summary & Roadmap
let slide10 = pres.addSlide();
slide10.background = { color: COLORS.bg };
slide10.addText('Athena 的价值', {
  x: 0.5, y: 0.3, w: 9, h: 0.8,
  fontSize: 32, fontFace: 'Arial', color: COLORS.primary,
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
  fontSize: 14, fontFace: 'Arial', color: COLORS.secondary,
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
  fontSize: 14, fontFace: 'Arial', color: COLORS.secondary,
  align: 'left', valign: 'top'
});
slide10.addText('感谢 Z.AI 赛道支持！', {
  x: 0.5, y: 5.0, w: 9, h: 0.4,
  fontSize: 16, fontFace: 'Arial', color: COLORS.gold,
  bold: true, align: 'center'
});
addFooter(slide10);

// Save
pres.writeFile({ fileName: "/root/projects/glm-code/ppt-assets/Athena-Hackathon.pptx" })
  .then(() => console.log("PPT created: /root/projects/glm-code/ppt-assets/Athena-Hackathon.pptx"))
  .catch(err => console.error("Error:", err));
