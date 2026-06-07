#!/bin/bash

# glm-tui Benchmark 运行脚本
# 
# 用法: ./run.sh [benchmark] [agent]
#
# benchmark: humaneval, edit, multistep (默认: humaneval)
# agent: glm-tui, claude-code (默认: glm-tui)

set -e

BENCHMARK=${1:-humaneval}
AGENT=${2:-glm-tui}
RESULTS_DIR="results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 创建结果目录
mkdir -p "$RESULTS_DIR"

# 检查依赖
check_dependencies() {
  if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed"
    exit 1
  fi
  
  if [ "$AGENT" = "glm-tui" ] && ! command -v glm-tui &> /dev/null; then
    echo "Warning: glm-tui not found in PATH, using node bin/glm-tui"
    GLM_TUI_CMD="node bin/glm-tui"
  else
    GLM_TUI_CMD="glm-tui"
  fi
  
  if [ "$AGENT" = "claude-code" ] && ! command -v claude &> /dev/null; then
    echo "Error: claude is not installed"
    exit 1
  fi
}

# 运行 HumanEval 测试
run_humaneval() {
  echo "Running HumanEval benchmark with $AGENT..."
  
  TASK_FILE="benchmarks/humaneval/tasks.txt"
  RESULTS_FILE="$RESULTS_DIR/humaneval_${AGENT}_${TIMESTAMP}.csv"
  
  if [ ! -f "$TASK_FILE" ]; then
    echo "Error: Task file not found: $TASK_FILE"
    echo "Please create benchmarks/humaneval/tasks.txt with one task per line"
    exit 1
  fi
  
  echo "task_id,prompt,result,passed" > "$RESULTS_FILE"
  
  task_id=0
  while IFS= read -r task; do
    task_id=$((task_id + 1))
    echo "Running task $task_id..."
    
    prompt="Write a Python function that: $task"
    
    if [ "$AGENT" = "glm-tui" ]; then
      result=$($GLM_TUI_CMD -p "$prompt" 2>&1)
    else
      result=$(claude --print "$prompt" 2>&1)
    fi
    
    # 简单的结果检查（实际应该运行测试）
    if echo "$result" | grep -q "def "; then
      passed="true"
    else
      passed="false"
    fi
    
    echo "$task_id,\"$task\",\"$result\",$passed" >> "$RESULTS_FILE"
    
  done < "$TASK_FILE"
  
  echo "Results saved to $RESULTS_FILE"
}

# 运行 Edit 测试
run_edit() {
  echo "Running Edit benchmark with $AGENT..."
  
  TASK_FILE="benchmarks/edit/tasks.txt"
  RESULTS_FILE="$RESULTS_DIR/edit_${AGENT}_${TIMESTAMP}.csv"
  
  if [ ! -f "$TASK_FILE" ]; then
    echo "Error: Task file not found: $TASK_FILE"
    echo "Please create benchmarks/edit/tasks.txt with one task per line"
    exit 1
  fi
  
  echo "task_id,prompt,result,success" > "$RESULTS_FILE"
  
  task_id=0
  while IFS= read -r task; do
    task_id=$((task_id + 1))
    echo "Running task $task_id..."
    
    if [ "$AGENT" = "glm-tui" ]; then
      result=$($GLM_TUI_CMD -p "$task" 2>&1)
    else
      result=$(claude --print "$task" 2>&1)
    fi
    
    # 简单的结果检查
    if [ $? -eq 0 ]; then
      success="true"
    else
      success="false"
    fi
    
    echo "$task_id,\"$task\",\"$result\",$success" >> "$RESULTS_FILE"
    
  done < "$TASK_FILE"
  
  echo "Results saved to $RESULTS_FILE"
}

# 运行 Multi-step 测试
run_multistep() {
  echo "Running Multi-step benchmark with $AGENT..."
  
  TASK_FILE="benchmarks/multistep/tasks.txt"
  RESULTS_FILE="$RESULTS_DIR/multistep_${AGENT}_${TIMESTAMP}.csv"
  
  if [ ! -f "$TASK_FILE" ]; then
    echo "Error: Task file not found: $TASK_FILE"
    echo "Please create benchmarks/multistep/tasks.txt with one task per line"
    exit 1
  fi
  
  echo "task_id,prompt,result,completed_steps" > "$RESULTS_FILE"
  
  task_id=0
  while IFS= read -r task; do
    task_id=$((task_id + 1))
    echo "Running task $task_id..."
    
    if [ "$AGENT" = "glm-tui" ]; then
      result=$($GLM_TUI_CMD -p "$task" 2>&1)
    else
      result=$(claude --print "$task" 2>&1)
    fi
    
    # 统计完成的步骤数
    completed_steps=$(echo "$result" | grep -c "Step" || true)
    
    echo "$task_id,\"$task\",\"$result\",$completed_steps" >> "$RESULTS_FILE"
    
  done < "$TASK_FILE"
  
  echo "Results saved to $RESULTS_FILE"
}

# 主函数
main() {
  echo "=== glm-tui Benchmark Runner ==="
  echo "Benchmark: $BENCHMARK"
  echo "Agent: $AGENT"
  echo "Timestamp: $TIMESTAMP"
  echo ""
  
  check_dependencies
  
  case $BENCHMARK in
    humaneval)
      run_humaneval
      ;;
    edit)
      run_edit
      ;;
    multistep)
      run_multistep
      ;;
    *)
      echo "Error: Unknown benchmark: $BENCHMARK"
      echo "Available benchmarks: humaneval, edit, multistep"
      exit 1
      ;;
  esac
  
  echo ""
  echo "=== Benchmark Complete ==="
}

main
