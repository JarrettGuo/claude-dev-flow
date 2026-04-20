#!/usr/bin/env bash
# RETRY 事件 — 重试标记
# 用法: bash .claude/hooks/retry.sh <轮次> [最大轮次]
#
# 示例:
#   bash .claude/hooks/retry.sh 1 3
#   bash .claude/hooks/retry.sh 2

CURRENT_FLOW_FILE=".dev-flow/.current-flow"
[ -f "$CURRENT_FLOW_FILE" ] || exit 0

FEATURE=$(cat "$CURRENT_FLOW_FILE")
FLOW_TYPE=$(echo "$FEATURE" | cut -d'/' -f1)
FLOW_NAME=$(echo "$FEATURE" | cut -d'/' -f2)
LOG_FILE=".dev-flow/${FLOW_TYPE}/${FLOW_NAME}/FLOW.log"

[ -f "$LOG_FILE" ] || exit 0

ROUND="$1"
MAX="${2:-3}"

TS=$(date +"%H:%M:%S")
LINE=$(printf "[%s] ↻ RETRY 第 %s 轮/共%s轮\n" "$TS" "$ROUND" "$MAX")

echo "$LINE" >> "$LOG_FILE"
[ "${FLOW_LOG_QUIET:-0}" != "1" ] && echo "$LINE" >&2
