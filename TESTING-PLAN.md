# glm-tui 测试方案

## 对比设计

```
glm-tui (GLM-5.1 专属优化)  vs  Claude Code (通用 harness) + GLM-5.1
```

两者使用同一模型（GLM-5.1），差异只在 harness 层。

## Benchmark 套件

### L1 — HumanEval+（快速验证）
- 164 道 Python 函数生成
- 指标：Pass@1
- 预计耗时：1-2 小时

### L2 — Aider Polyglot（正式评测）
- 225 道 Exercism，7 种语言
- 指标：Pass rate / 编辑轮次 / token 消耗
- Docker 运行，预计耗时：半天
- 来源：https://github.com/Aider-AI/aider/tree/main/benchmark

### L3 — SWE-Bench 子集（压轴）
- 50 个真实 GitHub issue
- 指标：Resolved rate / 修复轮次
- 预计耗时：1-2 天

### 自建长程测试（Demo 展示用）

任务链 1：React Todo App（3步）
  ① 创建项目骨架 + 基础组件
  ② 添加增删改 + 持久化
  ③ 修 2 个故意 bug

任务链 2：Python CLI 工具（4步）
  ① 参数解析 + 核心逻辑
  ② 错误处理 + 日志
  ③ 单元测试
  ④ 根据测试反馈修复 3 个问题

任务链 3：智能合约审计（3步）
  ① 读取合约 + 识别漏洞
  ② 生成修复补丁
  ③ 验证修复后测试通过

## 评测指标

| 指标 | 说明 |
|------|------|
| Pass@1 | 一次生成通过率 |
| Resolved Rate | 最终解决率 |
| Token 效率 | 完成任务的 token 消耗 |
| 修正轮次 | 需要几轮对话 |
| 长程稳定性 | 多步任务是否偏离目标 |

## 执行顺序

1. API 配通 → 跑 L1 HumanEval+
2. 优化 system prompt → 再跑 L1（对比优化效果）
3. 跑 L2 Aider Polyglot
4. 跑自建长程任务链
5. 跑 L3 SWE-Bench 子集

## 结果呈现

| Benchmark | glm-tui | CC+GLM | Delta |
|-----------|---------|--------|-------|
| HumanEval+ | XX.X% | XX.X% | +X.X% |
| Aider | XX.X% | XX.X% | +X.X% |
| SWE-Bench | XX.X% | XX.X% | +X.X% |
| 长程任务链 | XX/XX | XX/XX | +X/XX |
| Avg Tokens | XXXX | XXXX | -XX% |
| Avg Rounds | X.X | X.X | -X.X |

## 每题评测脚本框架

```bash
#!/bin/bash
# run_benchmark.sh

TASK_FILE=$1
AGENT=$2  # "glm" or "claude-code"

while IFS= read -r task; do
  prompt="Solve this: $task"
  
  if [ "$AGENT" = "glm" ]; then
    result=$(glm code -p "$prompt" 2>&1)
  else
    result=$(ANTHROPIC_BASE_URL=$PROXY_URL \
             ANTHROPIC_API_KEY=$PROXY_KEY \
             claude --print "$prompt" 2>&1)
  fi
  
  # 保存结果
  echo "$task|$result" >> results_${AGENT}.csv
done < "$TASK_FILE"
```
