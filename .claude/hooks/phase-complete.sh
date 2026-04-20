#!/usr/bin/env bash
# 完成当前 phase
# 用法: bash .claude/hooks/phase-complete.sh <current_phase> [next_phase_num next_phase_name next_agent next_total]
#
# 示例:
#   bash .claude/hooks/phase-complete.sh 1                    # 仅完成 Phase 1
#   bash .claude/hooks/phase-complete.sh 1 2 "Design" "architect" 6  # 完成 Phase 1 并启动 Phase 2

CURRENT_FLOW_FILE=".dev-flow/.current-flow"
[ -f "$CURRENT_FLOW_FILE" ] || exit 0

FEATURE=$(cat "$CURRENT_FLOW_FILE")
FLOW_TYPE=$(echo "$FEATURE" | cut -d'/' -f1)
FLOW_NAME=$(echo "$FEATURE" | cut -d'/' -f2)
LOG_FILE=".dev-flow/${FLOW_TYPE}/${FLOW_NAME}/FLOW.log"

[ -f "$LOG_FILE" ] || exit 0

CURRENT_PHASE="$1"
shift || true

# 计算 elapsed
ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))

# 进度可视化：完成当前 phase
if source .claude/skills/progress-display/progress.bash 2>/dev/null; then
  progress_phase_complete "$CURRENT_PHASE" "$ELAPSED" 2>/dev/null || true
fi

# 如果有下一个 phase 参数，自动启动
if [ $# -ge 4 ]; then
  NEXT_PHASE_NUM="$1"
  NEXT_PHASE_NAME="$2"
  NEXT_AGENT="$3"
  NEXT_TOTAL="$4"
  bash .claude/hooks/phase-start.sh "$NEXT_PHASE_NUM" "$NEXT_PHASE_NAME" "$NEXT_AGENT" "$NEXT_TOTAL"
fi
