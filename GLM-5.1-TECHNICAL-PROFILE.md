# GLM-5.1 完整技术特征

> 来源：arxiv:2602.15763 + HuggingFace zai-org/GLM-5.1 + z.ai 官方文档

## 1. 架构：GlmMoeDsaForCausalLM

MoE + DeepSeek Sparse Attention (DSA) 混合架构。

### 核心参数（从 config.json 提取）

```
总参数量:        744B（论文数据）
激活参数量:      40B（每 token 只激活 8/256 专家）
层数:            78
隐藏维度:        6144
注意力头数:      64
KV 头数:         64（与 Q 头相同，非 GQA）
路由专家数:      256
每 token 激活:   8 个专家 + 1 个共享专家
MoE 中间层大小:  2048
Dense 中间层:    12288
词表:            154,880
最大上下文:      202,752 tokens
精度:            bfloat16
```

### DSA（DeepSeek Sparse Attention）

GLM-5.1 的注意力不是标准 MHA，而是 MLA（Multi-Latent Attention）+ DSA：

```
Q LoRA rank:     2048（Q 压缩）
KV LoRA rank:    512（KV 压缩，极低显存）
QK head dim:     256
QK nope dim:     192（不带位置编码的部分）
QK rope dim:     64（带 RoPE 的部分）
V head dim:      256
Head dim:        64
```

DSA 的核心创新：
- **Lightning Indexer** — 轻量级索引器，为每个 token 动态选择重要的历史 token
- **Token 级稀疏** — 不丢弃任何长距离依赖，但只计算被选中的 token
- **无损长上下文** — 相比 SWA（滑动窗口注意力）有本质优势，不会在 128K+ 退化
- **Index 参数**：`index_n_heads=32`, `index_head_dim=128`, `index_topk=2048`

前 3 层是 Dense（`first_k_dense_replace=3`），之后全部是 MoE 层（`moe_layer_freq=1`）。

### MoE 路由

```
scoring_func:    sigmoid（非 softmax）
topk_method:     noaux_tc（无辅助损失的 top-k）
routed_scaling:  2.5
norm_topk_prob:  true
```

## 2. 训练管线

### 2.1 预训练

```
总 token 数:     28.5T（GLM-4.5 为 23T）
数据构成:        代码+推理优先
```

### 2.2 Mid-Training（上下文扩展）

```
4K → 200K 渐进式扩展
重点: 长上下文 agentic 数据
目标: 复杂工作流中的稳定性
```

### 2.3 Post-Training（三阶段 RL）

```
SFT（监督微调）
  ├── 三大类数据：通用 / 推理 / Agent
  ├── 最大上下文扩展到 202,752 tokens
  └── 支持三种 thinking 模式
      ↓
Reasoning RL
  ├── 基于 GRPO + IcePop
  ├── 混合领域推理（数学+代码+科学+TIR）
  ├── 难度过滤：只保留 GLM-4.7 难以解决的问题
  └── 去掉 KL 正则化加速改进
      ↓
Agentic RL ← 核心创新
  ├── 异步解耦 RL 框架（slime）
  ├── 10K+ 真实 SWE 环境
  ├── 终端环境 + 搜索环境
  └── 错误轨迹保留但 loss mask（学习纠错）
      ↓
General RL
  ├── 三维优化：质量 / 偏好 / 安全
  └── 人类风格对齐
      ↓
On-Policy Cross-Stage Distillation
  └── 防止灾难性遗忘
```

## 3. Thinking 模式（关键特性）

GLM-5.1 支持三种推理模式，全部在 chat_template 中实现：

### 3.1 标准 Thinking
```xml
<think>推理内容</think>
```
每轮对话前思考。

### 3.2 Interleaved Thinking（交错思考）
```xml
<|assistant|>
<think>第一个动作的推理</think>
第一个动作

<|assistant|>
<think>继续之前的推理，复用已有思考块</think>
第二个动作
```
**关键**: 多轮对话中自动保留所有 thinking 块，不重新推理。
这直接支撑了长程任务——模型记住之前的推理过程。

### 3.3 Preserved Thinking（保留思考）
支持按轮次控制是否启用 thinking：
- 简单请求 → 关闭 thinking（低延迟低成本）
- 复杂任务 → 开启 thinking（高精度高稳定性）

## 4. 工具调用格式（Native）

GLM-5.1 的原生工具调用是 XML 格式：

```xml
<tool_call>function-name
<arg_key>param1</arg_key>
<arg_value>value1</arg_value>
<arg_key>param2</arg_key>
<arg_value>value2</arg_value>
</tool_call>
```

工具结果返回：
```xml
<|observation|>
<tool_response>工具返回内容</think>
```

多个工具调用可并行发出（不依赖前一个的结果）。

## 5. Agentic RL 的环境构建（论文 Section 4）

### 5.1 SWE 环境
- 基于 RepoLaunch 框架
- 从真实 GitHub Issue-PR 对构建
- **10,000+ 可验证环境**
- 覆盖 9 种语言：Python, Java, Go, C, CPP, JS, TS, PHP, Ruby
- 自动生成 F2P（Fail-to-Pass）和 P2P（Pass-to-Pass）测试用例

### 5.2 终端环境
- 从种子任务 + LLM 头脑风暴生成
- Harbor 格式：结构化描述 + Docker 环境 + 测试脚本
- Refine Agent 迭代优化
- Docker 构建成功率 > 90%
- 数千个多样化终端任务

### 5.3 搜索环境
- 高难度多跳搜索任务
- 推理时使用 Context Management 策略

### 5.4 错误学习机制
**核心创新**: 训练数据中的错误轨迹被**保留但 loss mask**：
- 模型看到错误发生的过程
- 但不会从错误中强化学习
- 学到的是**纠错行为**而非错误本身

## 6. 异步 RL 基础设施（slime 框架）

```
┌─────────────────────────────────────┐
│   Multi-Task Rollout Orchestrator    │
│   ┌──────────┐    ┌──────────┐     │
│   │ Inference │    │ Training │     │
│   │  Engine   │    │  Engine  │     │
│   └────┬─────┘    └────▲─────┘     │
│        │    异步解耦      │          │
│        └────────────────┘          │
│                                     │
│   关键机制:                          │
│   · TITO（Token-in-Token-out）      │
│     消除重 tokenize 不匹配           │
│   · Direct Double-sided IS          │
│     token 级重要性采样裁剪           │
│   · DP-aware Routing                │
│     最大化 KV-cache 复用            │
│   · Heartbeat 容错                  │
│     心跳驱动的故障恢复               │
└─────────────────────────────────────┘
```

## 7. Benchmark 完整数据

| 测试 | GLM-5.1 | GLM-5 | Claude Opus 4.6 | GPT-5.4 |
|------|---------|-------|-----------------|---------|
| HLE | 31.0 | 30.5 | 36.7 | 39.8 |
| HLE (w/ Tools) | 52.3 | 50.4 | 53.1 | 52.1 |
| AIME 2026 | 95.3 | 95.4 | 95.6 | 98.7 |
| GPQA-Diamond | 86.2 | 86.0 | 91.3 | 92.0 |
| SWE-Bench Pro | **58.4** | 55.1 | 57.3 | 57.7 |
| NL2Repo | 42.7 | 35.9 | **49.8** | 41.3 |
| Terminal-Bench 2.0 | 63.5 | 56.2 | 65.4 | — |
| Terminal-Bench (Claude Code) | 69.0 | 56.2 | — | — |
| CyberGym | **68.7** | 48.3 | 66.6 | 66.3 |
| BrowseComp | **68.0** | 62.0 | — | — |
| BrowseComp (w/ CM) | 79.3 | 75.9 | 84.0 | 82.7 |
| τ³-Bench | 70.6 | 69.2 | 72.4 | 72.9 |
| MCP-Atlas | 71.8 | 69.2 | 73.8 | 67.2 |
| Tool-Decathlon | 40.7 | 38.0 | 47.2 | 54.6 |
| Vending Bench 2 | $5,634 | $4,432 | **$8,018** | $6,144 |

## 8. 部署要求

### API 调用
```
端点: https://api.z.ai/api/coding/paas/v4  (coding 专属)
      https://api.z.ai/api/paas/v4          (通用)
模型: glm-5.1
认证: Bearer Token (ZAI_API_KEY)
```

### 本地部署（开源）
```
框架: vLLM (v0.19.0+), SGLang (v0.5.10+), xLLM, KTransformers
显存: 8×GPU（FP8 版本可减少显存）
命令:
  vllm serve zai-org/GLM-5.1-FP8 \
    --tensor-parallel-size 8 \
    --gpu-memory-utilization 0.85 \
    --speculative-config.method mtp \
    --speculative-config.num_speculative_tokens 3 \
    --tool-call-parser glm47 \
    --reasoning-parser glm45 \
    --enable-auto-tool-choice
```

## 9. 对 glm-tui 设计的启示

1. **Interleaved Thinking** → glm-tui 应该利用这个特性，在长程任务中保持推理连续性
2. **Native XML Tool Format** → 需要确保 Pi harness 正确处理 GLM 的 tool_call 格式
3. **错误学习** → 系统提示词应该鼓励"发现错误 → 分析原因 → 修复"而非跳过
4. **200K Context + DSA** → 不需要急着压缩上下文，GLM-5.1 的长上下文是无损的
5. **Coding Endpoint** → 用 `/api/coding/paas/v4` 而非通用端点
6. **Thinking 模式** → 复杂任务开启 thinking，简单任务关闭以降低延迟
