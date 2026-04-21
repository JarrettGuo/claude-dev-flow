#!/usr/bin/env bash
#
# ⚠️  本脚本只做日志记录（写入 FLOW.log + 回显到终端），不做任何真正的阻塞等待。
#
# 原因：Claude Code 的 Bash tool 以子进程执行此脚本，stdin 不连用户终端，
# 任何 `read` 调用会立即得到 EOF，无法真正等待用户输入。
#
# 真正的"等待用户确认"必须由调用方的 LLM 层 prompt 实现——在 orchestrator
# 的 command 文件（如 dev.md / fix.md）中，在调用本脚本之后插入明确的
# STOP 停顿指令，由 Claude 主动把控制权交还用户。
#
# 不要试图给本脚本加 `read` 或其他"阻塞"逻辑，那样做无效。
#
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
