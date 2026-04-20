#!/usr/bin/env bash
# DECISION 事件 + 自动切换 phase
# 用法: bash .claude/hooks/decision.sh <决策内容> <next_phase_num> <next_phase_name> <next_agent> <next_total>
#
# 示例:
#   bash .claude/hooks/decision.sh "用户确认需求 → 进入 Phase 2" 2 "Design" "architect" 6

CURRENT_FLOW_FILE=".dev-flow/.current-flow"
[ -f "$CURRENT_FLOW_FILE" ] || exit 0

FEATURE=$(cat "$CURRENT_FLOW_FILE")
FLOW_TYPE=$(echo "$FEATURE" | cut -d'/' -f1)
FLOW_NAME=$(echo "$FEATURE" | cut -d'/' -f2)
LOG_FILE=".dev-flow/${FLOW_TYPE}/${FLOW_NAME}/FLOW.log"

[ -f "$LOG_FILE" ] || exit 0

DECISION="$1"
NEXT_PHASE_NUM="$2"
NEXT_PHASE_NAME="$3"
NEXT_AGENT="$4"
NEXT_TOTAL="$5"

TS=$(date +"%H:%M:%S")

# 获取当前 phase（用于完成）
CURRENT_PHASE_FILE=".dev-flow/.current-phase"
CURRENT_PHASE="${6:-}"
if [ -z "$CURRENT_PHASE" ] && [ -f "$CURRENT_PHASE_FILE" ]; then
  CURRENT_PHASE=$(cat "$CURRENT_PHASE_FILE")
fi
[ -z "$CURRENT_PHASE" ] && CURRENT_PHASE=1

# 写 DECISION 事件
LINE=$(printf "[%s] ✓ DECISION %s\n" "$TS" "$DECISION")
echo "$LINE" >> "$LOG_FILE"
[ "${FLOW_LOG_QUIET:-0}" != "1" ] && echo "$LINE" >&2

# 完成当前 phase 并启动下一个
bash .claude/hooks/phase-complete.sh "$CURRENT_PHASE" "$NEXT_PHASE_NUM" "$NEXT_PHASE_NAME" "$NEXT_AGENT" "$NEXT_TOTAL"
