# GLM Code

**独立的 GLM-5.1 coding agent** - 基于 Pi harness，完全独立运行

## 简介

GLM Code 是一个独立的 coding agent，专门针对 GLM-5.1 模型优化。它基于 Pi harness 构建，但作为独立应用运行，不依赖 Pi 命令行。

## 特性

- **独立运行** - 不依赖 Pi 命令行，完全独立的应用
- **GLM-5.1 优化** - 针对 GLM-5.1 特性深度优化
- **长程任务** - 支持复杂任务的规划和执行
- **自我纠错** - 自动检测和修复错误
- **200K context** - 充分利用 GLM-5.1 的长上下文能力

## 安装

```bash
# 克隆项目
git clone <repository-url>
cd glm-tui

# 安装依赖
npm install

# 链接到全局（安装 glm 命令）
npm link

# 验证安装
glm --help
```

## 使用方法

### 基本用法

```bash
# 启动交互模式
glm

# 非交互模式
glm -p "创建一个 React 组件"

# 继续最近的会话
glm -c
```

### 规划模式

```bash
# 启用规划模式（默认启用）
glm --planning

# 禁用规划模式
glm --no-planning
```

### 自我纠错

```bash
# 启用自我纠错（默认启用）
glm --correction

# 禁用自我纠错
glm --no-correction
```

### 其他选项

```bash
# 显示帮助
glm --help

# 显示版本
glm --version

# 指定模型
glm --provider openai --model gpt-4o

# 指定 thinking level
glm --thinking high
```

## 配置

### 配置文件

GLM Code 支持多个配置文件位置：

1. **项目级配置**: `.glm-code.json`（在项目根目录）
2. **用户级配置**: `~/.glm-code.json`

### 配置示例

```json
{
  "provider": "zai",
  "model": "glm-5.1",
  "glm": {
    "apiKey": "your-api-key",
    "model": "glm-5.1",
    "endpoint": "https://api.z.ai/api/coding/paas/v4"
  },
  "features": {
    "planningMode": true,
    "selfCorrection": true
  }
}
```

### 环境变量

```bash
# GLM 配置
export GLM_API_KEY="your-api-key"
export GLM_MODEL="glm-5.1"
export GLM_ENDPOINT="https://api.z.ai/api/coding/paas/v4"

# 或者使用 Anthropic
export ANTHROPIC_API_KEY="your-key"
```

## 项目结构

```
glm-tui/
├── bin/
│   └── glm                  # 入口脚本
├── prompts/
│   ├── system.md            # 核心系统提示词
│   ├── planning.md          # 规划模式提示词
│   └── correction.md        # 自我纠错提示词
├── src/                     # TypeScript 源代码（未来扩展）
├── lib/                     # JavaScript 源代码
├── mcp/
│   └── servers.json         # MCP server 配置
├── benchmarks/
│   ├── humaneval/           # HumanEval+ 子集
│   ├── edit/                # 编辑测试
│   ├── multistep/           # 多步测试
│   └── run.sh               # 评测脚本
├── package.json
└── README.md
```

## 与 Pi 的区别

| 特性 | GLM Code | Pi |
|------|----------|-----|
| 独立性 | 完全独立 | 需要 Pi 命令行 |
| 系统提示词 | GLM-5.1 优化 | 通用 |
| 工具 | 自定义工具 | 通用工具 |
| 配置 | GLM 专用配置 | 通用配置 |

## 开发

### 本地开发

```bash
# 安装依赖
npm install

# 编译 TypeScript（可选）
npx tsc

# 链接到全局
npm link
```

### 添加新功能

1. 在 `prompts/` 目录添加新的提示词模板
2. 在 `lib/` 目录添加新的功能模块
3. 更新 `bin/glm` 入口脚本以支持新功能

## GLM-5.1 优化

### Interleaved Thinking
GLM-5.1 支持交错思考模式，GLM Code 自动利用这一特性。

### 200K Context
充分利用 GLM-5.1 的长上下文能力，支持复杂长程任务。

### 原生工具调用
支持 GLM-5.1 的原生 XML 工具调用格式。

## 路线图

### Phase 1: MVP (当前)
- [x] 独立入口脚本
- [x] 核心系统提示词
- [x] 规划模式
- [x] 自我纠错
- [ ] GLM-5.1 模型接入

### Phase 2: 增强功能
- [ ] 自定义工具
- [ ] 上下文管理
- [ ] 会话持久化

### Phase 3: 测试和优化
- [ ] HumanEval 测试
- [ ] 性能优化
- [ ] 文档完善

## 许可证

MIT License
