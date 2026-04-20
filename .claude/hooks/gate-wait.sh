#!/usr/bin/env bash
# GATE 事件 — 等待用户确认
# 用法: bash .claude/hooks/gate-wait.sh <等待说明>
#
# 示例:
#   bash .claude/hooks/gate-wait.sh "用户确认需求"

CURRENT_FLOW_FILE=".dev-flow/.current-flow"
[ -f "$CURRENT_FLOW_FILE" ] || exit 0

FEATURE=$(cat "$CURRENT_FLOW_FILE")
FLOW_TYPE=$(echo "$FEATURE" | cut -d'/' -f1)
FLOW_NAME=$(echo "$FEATURE" | cut -d'/' -f2)
LOG_FILE=".dev-flow/${FLOW_TYPE}/${FLOW_NAME}/FLOW.log"

[ -f "$LOG_FILE" ] || exit 0

TS=$(date +"%H:%M:%S")
DESC="${1:-等待确认}"
LINE=$(printf "[%s] ⏸ GATE %s\n" "$TS" "$DESC")

echo "$LINE" >> "$LOG_FILE"
[ "${FLOW_LOG_QUIET:-0}" != "1" ] && echo "$LINE" >&2
