#!/usr/bin/env bash
# Phase 分隔符 + PHASE 事件
# 用法: bash .claude/hooks/phase-start.sh <phase_num> <phase_name> <agent> <total_phases>
#
# 示例:
#   bash .claude/hooks/phase-start.sh 2 "Design" "architect" 6

CURRENT_FLOW_FILE=".dev-flow/.current-flow"
[ -f "$CURRENT_FLOW_FILE" ] || exit 0

FEATURE=$(cat "$CURRENT_FLOW_FILE")
FLOW_TYPE=$(echo "$FEATURE" | cut -d'/' -f1)
FLOW_NAME=$(echo "$FEATURE" | cut -d'/' -f2)
LOG_FILE=".dev-flow/${FLOW_TYPE}/${FLOW_NAME}/FLOW.log"

[ -f "$LOG_FILE" ] || exit 0

PHASE_NUM="$1"
PHASE_NAME="$2"
AGENT="$3"
TOTAL="$4"

TS=$(date +"%H:%M:%S")

# 写分隔符和 PHASE 事件
{
  printf "\n─── Phase %s: %s ──────────────────────────────────────\n" "$PHASE_NUM" "$PHASE_NAME"
  printf "[%s] ▶ PHASE Phase %s 启动\n" "$TS" "$PHASE_NUM"
} >> "$LOG_FILE"

# 更新状态文件
echo "$PHASE_NUM" > ".dev-flow/.current-phase"
date +%s > .dev-flow/.phase-start

# 简洁终端提示(单行紧凑 banner,只在终端显示,不污染 FLOW.log)
if [ "${FLOW_LOG_QUIET:-0}" != "1" ]; then
  printf "════════════════ Phase %s/%s: %s @%s ════════════════════════════════════════════════\n" "$PHASE_NUM" "$TOTAL" "$PHASE_NAME" "$AGENT" >&2
fi
