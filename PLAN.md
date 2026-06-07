# glm-tui 完整方案

## 定位

**glm-tui 是一个长期维护的 GLM-5.1 专属 coding agent。**

黑客松阶段目标：MVP + 最小合格测试 + AuditAI MCP 集成。

## 三层架构

```
┌─────────────────────────────────────────────────┐
│                   glm-tui                        │
│            (GLM-5.1 专属 coding agent)            │
│                                                  │
│  核心能力:                                        │
│  · 长程任务规划与执行                              │
│  · 自主拆解 + 持续迭代 + 自我纠错                  │
│  · 200K context 管理                             │
│  · GLM 原生工具调用格式                            │
│  · Interleaved Thinking                          │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │              Pi Agent Harness             │    │
│  │  session / TUI / tools / provider 管理    │    │
│  └──────────────────────────────────────────┘    │
│                                                  │
│  ┌──────────────────────────────────────────┐    │
│  │              MCP 层                       │    │
│  │  · AuditAI MCP Server (Web3)             │    │
│  │  · 其他 MCP servers (可扩展)              │    │
│  └──────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
```

## 黑客松交付物

### 1. glm-tui 本身（产品）

入口脚本 + 系统提示词 + Planning Mode + Pi harness

### 2. 最小合格测试（证明是合格 coding agent）

任何 coding agent 都应该能通过的基础测试：

| 测试 | 说明 | 指标 |
|------|------|------|
| HumanEval+ 子集 | 30 题 Python 函数生成 | Pass@1 |
| Edit 测试 | 10 题已有代码修改 | 成功率 |
| Multi-step 测试 | 5 题多步任务（读→改→测） | 完成率 |

对比：glm code vs Claude Code + GLM-5.1（同模型，不同 harness）

### 3. Web3 长程任务 Demo（证明 Long-Horizon 能力）

通过 MCP 连接 AuditAI，跑一条完整审计任务链：

```
① 读取合约 → 识别协议类型 + 风险面
② slither + aderyn 双引擎扫描
③ RAG 检索知识库，交叉验证
④ PoC exploit 生成
⑤ Foundry fuzz 验证
⑥ 生成修复补丁
⑦ EAS 链上认证
```

每步记录：工具调用、中间结果、决策理由、迭代/纠错次数

对比：同一个任务，glm code vs Claude Code + GLM-5.1

### 4. Benchmark 表（数据佐证）

```
┌──────────────────────────────────────────────────┐
│       glm code vs Claude Code + GLM-5.1          │
├──────────────┬──────────┬──────────┬──────────────┤
│ 测试          │ glm-tui  │ CC+GLM   │ Delta        │
├──────────────┼──────────┼──────────┼──────────────┤
│ HumanEval+   │ XX.X%    │ XX.X%    │ +X.X%        │
│ Edit 测试     │ XX/10    │ XX/10    │              │
│ Multi-step   │ XX/5     │ XX/5     │              │
│ 审计任务链    │ 完成N步  │ 完成N步  │              │
│ Avg Tokens   │ XXXX     │ XXXX     │ -XX%         │
│ Avg Rounds   │ X.X      │ X.X      │              │
└──────────────┴──────────┴──────────┴──────────────┘
```

## 项目结构（长期）

```
glm-tui/
├── bin/glm                  # 入口
├── prompts/
│   ├── system.md            # 核心系统提示词
│   ├── planning.md          # Planning mode
│   └── correction.md        # 自我纠错
├── lib/
│   ├── config.js            # 配置
│   ├── launcher.js          # Pi 启动器
│   └── context-manager.js   # Context 管理
├── mcp/
│   └── servers.json         # MCP server 配置（含 AuditAI）
├── benchmarks/
│   ├── humaneval/           # HumanEval+ 子集
│   ├── edit/                # 编辑测试
│   ├── multistep/           # 多步测试
│   └── run.sh               # 评测脚本
├── package.json
└── README.md
```

## 执行计划

### Phase 1: glm-tui MVP（1-2天）
- [ ] 入口脚本（包装 Pi + GLM-5.1）
- [ ] 核心系统提示词（规划 + 纠错 + 长程）
- [ ] 验证 Pi --provider zai --model glm-5.1 能跑通
- [ ] MCP 配置接入 AuditAI

### Phase 2: 最小合格测试（1天）
- [ ] 准备 HumanEval+ 30 题子集
- [ ] 准备 Edit 10 题
- [ ] 准备 Multi-step 5 题
- [ ] 跑 glm code 一轮
- [ ] 跑 Claude Code + GLM-5.1 一轮

### Phase 3: Web3 长程 Demo（1-2天）
- [ ] 设计审计任务链（选一个有漏洞的合约）
- [ ] glm code 跑完整链路，记录过程
- [ ] Claude Code 跑同一条链路
- [ ] 录屏

### Phase 4: 打磨提交（1天）
- [ ] Benchmark 表格
- [ ] README + Demo 视频
- [ ] GitHub repo 整理
- [ ] 提交
