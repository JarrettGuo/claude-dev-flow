#!/usr/bin/env bash
# flow-log hook — 自动记录 subagent 进出和用户确认
# 由 .claude/settings.json 里的 hooks 触发
#
# 参数：$1 = event type (subagent-start / subagent-stop / user-input)
#       $2+ = event-specific args

set -eu

# 当前 flow 的 feature 名（由 /dev 或 /fix 写入此文件）
CURRENT_FLOW_FILE=".dev-flow/.current-flow"

# 没有当前 flow 就不记录（Claude Code 不是每次对话都在 flow 里）
[ -f "$CURRENT_FLOW_FILE" ] || exit 0

FEATURE=$(cat "$CURRENT_FLOW_FILE")
FLOW_TYPE=$(echo "$FEATURE" | cut -d'/' -f1)  # "specs" 或 "fixes"
FLOW_NAME=$(echo "$FEATURE" | cut -d'/' -f2)
LOG_FILE=".dev-flow/${FLOW_TYPE}/${FLOW_NAME}/FLOW.log"

# 日志文件不存在就不写（还没初始化）
[ -f "$LOG_FILE" ] || exit 0

TIMESTAMP=$(date +"%H:%M:%S")
EVENT_TYPE="$1"
shift

case "$EVENT_TYPE" in
  subagent-start)
    AGENT_NAME="${1:-unknown}"
    AGENT_ID="${2:-}"
    ID_PREFIX=""
    [ -n "$AGENT_ID" ] && ID_PREFIX=" @${AGENT_ID}"
    LINE=$(printf "[%s]%s ▶ ENTER @%s" "$TIMESTAMP" "$ID_PREFIX" "$AGENT_NAME")
    ;;
  subagent-stop)
    AGENT_NAME="${1:-unknown}"
    DURATION="${2:-}"
    [ -z "$DURATION" ] && DURATION=0
    AGENT_ID="${3:-}"
    ID_PREFIX=""
    [ -n "$AGENT_ID" ] && ID_PREFIX=" @${AGENT_ID}"
    LINE=$(printf "[%s]%s ◀ EXIT @%s (%ss)" "$TIMESTAMP" "$ID_PREFIX" "$AGENT_NAME" "$DURATION")
    ;;
  user-input)
    INPUT="${1:-}"
    AGENT_ID="${2:-}"
    ID_PREFIX=""
    [ -n "$AGENT_ID" ] && ID_PREFIX=" @${AGENT_ID}"
    # 去掉首尾空白，但保留原字符
    INPUT_TRIMMED=$(echo "$INPUT" | awk '{$1=$1};1')
    # 用 awk 统计"字符数"（UTF-8 安全）而不是字节数
    CHAR_COUNT=$(printf "%s" "$INPUT_TRIMMED" | awk '{print length}')

    # 判断是短确认（≤ 6 字符，覆盖 y/yes/n/no/编辑/确认/跳过）还是长输入
    if [ "$CHAR_COUNT" -le 6 ]; then
      LINE=$(printf "[%s]%s ✓ DECISION 用户输入: \"%s\"" "$TIMESTAMP" "$ID_PREFIX" "$INPUT_TRIMMED")
    else
      LINE=$(printf "[%s]%s ✓ DECISION 用户发送新指令（%d 字符）" "$TIMESTAMP" "$ID_PREFIX" "$CHAR_COUNT")
    fi
    ;;
  *)
    LINE=$(printf "[%s] ∙ HOOK 未知事件: %s" "$TIMESTAMP" "$EVENT_TYPE")
    ;;
esac

# 双通道输出：默认输出终端；FLOW_LOG_QUIET=1 时静默；FLOW_LOG_STDERR=1 仍兼容
echo "$LINE" >> "$LOG_FILE"
if [ "${FLOW_LOG_QUIET:-0}" != "1" ] || [ "${FLOW_LOG_STDERR:-0}" = "1" ]; then
  echo "$LINE" >&2
fi