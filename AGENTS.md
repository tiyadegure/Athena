# glm-tui 项目规范

## 核心规则：生成代码前必须先检索

在编写任何新代码（函数、类、模块、工具）之前，**必须**先用 grep MCP 搜索项目中是否已存在类似实现：

```
mcp({ search: "你要实现的功能关键词" })
```

**流程：**
1. 拿到需求后，先用 `mcp({ search: "相关关键词" })` 搜索
2. 如果找到相似代码 → 复用或扩展现有实现，不要重写
3. 如果确认没有 → 才开始编写新代码

**目的：** 避免重复代码，保持项目一致性。

## 规划模式（Plan Mode）

项目已启用 plan-mode 扩展，支持目标导向的开发流程：

- `/plan` — 切换规划模式（只读探索 → 执行）
- `/todos` — 查看当前计划进度
- `Ctrl+Alt+P` — 快捷键切换

**工作流程：**
1. 开启 plan mode，让 agent 分析代码、制定计划
2. 确认计划后进入执行模式
3. Agent 按步骤执行，用 `[DONE:n]` 标记完成

## 已安装扩展

| 扩展 | 功能 |
|------|------|
| pi-mcp-adapter | MCP 支持（grep 搜索） |
| rpiv-todo | Todo 列表，支持 overlay 渲染 |
| context-mode | Context 管理，token 优化 |
| plan-mode | 规划模式，目标导向开发 |

## 项目结构

```
glm-tui/
├── bin/glm-tui              # 入口
├── prompts/                  # 系统提示词
├── lib/                      # 核心逻辑
├── mcp/servers.json          # MCP server 配置
├── benchmarks/               # 评测
├── .mcp.json                 # MCP 配置（pi-mcp-adapter）
├── .pi/
│   ├── settings.json         # 项目级 pi 配置
│   ├── extensions/           # 项目级扩展
│   │   └── plan-mode/        # 规划模式
│   └── npm/                  # 项目级 npm 包
└── AGENTS.md                 # 本文件
```

## 技术栈

- **运行时:** Node.js + Pi coding agent harness
- **模型:** GLM-5.1（通过 zai provider）
- **MCP:** pi-mcp-adapter（lazy 模式，按需启动）
- **规划:** plan-mode 扩展（目标导向）
