#!/usr/bin/env bash
# ERROR 事件
# 用法: bash .claude/hooks/error.sh <错误描述>
#
# 示例:
#   bash .claude/hooks/error.sh "Review 被阻止，invoke debugger"

CURRENT_FLOW_FILE=".dev-flow/.current-flow"
[ -f "$CURRENT_FLOW_FILE" ] || exit 0

FEATURE=$(cat "$CURRENT_FLOW_FILE")
FLOW_TYPE=$(echo "$FEATURE" | cut -d'/' -f1)
FLOW_NAME=$(echo "$FEATURE" | cut -d'/' -f2)
LOG_FILE=".dev-flow/${FLOW_TYPE}/${FLOW_NAME}/FLOW.log"

[ -f "$LOG_FILE" ] || exit 0

TS=$(date +"%H:%M:%S")
ERROR_DESC="${1:-未知错误}"
LINE=$(printf "[%s] ✗ ERROR %s\n" "$TS" "$ERROR_DESC")

echo "$LINE" >> "$LOG_FILE"
[ "${FLOW_LOG_QUIET:-0}" != "1" ] && echo "$LINE" >&2
