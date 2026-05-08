#!/usr/bin/env bash
# flow-log hook — 从 stdin JSON 读取 Claude Code hook 事件，记录到 FLOW.log
# 由 .claude/settings.json 配置触发，所有事件共用一个 command。
# 通过 hook_event_name 字段自判事件类型。

set -eu

# === 通用前置 ===

# 没有当前 flow 就不记录
CURRENT_FLOW_FILE=".dev-flow/.current-flow"
[ -f "$CURRENT_FLOW_FILE" ] || exit 0

FEATURE=$(cat "$CURRENT_FLOW_FILE")
FLOW_TYPE=$(echo "$FEATURE" | cut -d'/' -f1)
FLOW_NAME=$(echo "$FEATURE" | cut -d'/' -f2)
LOG_FILE=".dev-flow/${FLOW_TYPE}/${FLOW_NAME}/FLOW.log"
[ -f "$LOG_FILE" ] || exit 0

# 读 stdin JSON
INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

# jq 缺失保护
if ! command -v jq >/dev/null 2>&1; then
  if [ ! -f .dev-flow/.jq-warned ]; then
    TS=$(date +"%H:%M:%S")
    printf "[%s] ⚠ WARN jq 未安装，subagent 名称和用户输入无法解析，日志只记事件类型\n" "$TS" >> "$LOG_FILE"
    if [ "${FLOW_LOG_QUIET:-0}" != "1" ]; then
      printf "[%s] ⚠ WARN jq 未安装，subagent 名称和用户输入无法解析，日志只记事件类型\n" "$TS" >&2
    fi
    touch .dev-flow/.jq-warned
  fi
  exit 0
fi

# 提取事件类型
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')
TIMESTAMP=$(date +"%H:%M:%S")

# 根据事件分发
case "$EVENT" in
  SubagentStart)
    AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "unknown"')
    AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // ""')

    # 存时间戳供 SubagentStop 计算耗时
    if [ -n "$AGENT_ID" ]; then
      date +%s > ".dev-flow/.agent-${AGENT_ID}.start"
    fi

    LINE=$(printf "[%s] ▶ ENTER @%s" "$TIMESTAMP" "$AGENT_TYPE")
    ;;

  SubagentStop)
    AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "unknown"')
    AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // ""')

    # 计算耗时
    ELAPSED_DISPLAY="?"
    START_FILE=".dev-flow/.agent-${AGENT_ID}.start"
    if [ -n "$AGENT_ID" ] && [ -f "$START_FILE" ]; then
      START_SEC=$(cat "$START_FILE")
      NOW_SEC=$(date +%s)
      ELAPSED_DISPLAY=$((NOW_SEC - START_SEC))
      rm -f "$START_FILE"
    fi

    LINE=$(printf "[%s] ◀ EXIT @%s (%ss)" "$TIMESTAMP" "$AGENT_TYPE" "$ELAPSED_DISPLAY")
    ;;

  UserPromptSubmit)
    PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')
    # trim 首尾空白
    PROMPT_TRIMMED=$(printf "%s" "$PROMPT" | awk '{$1=$1};1')

    # 空输入跳过（用户敲空回车不记日志）
    [ -z "$PROMPT_TRIMMED" ] && exit 0

    # 字符数判断短确认 vs 长输入
    CHAR_COUNT=$(printf "%s" "$PROMPT_TRIMMED" | wc -m | tr -d ' ')
    if [ "$CHAR_COUNT" -le 6 ]; then
      LINE=$(printf "[%s] ✓ DECISION 用户输入: \"%s\"" "$TIMESTAMP" "$PROMPT_TRIMMED")
    else
      LINE=$(printf "[%s] ✓ DECISION 用户发送新指令（%d 字符）" "$TIMESTAMP" "$CHAR_COUNT")
    fi
    ;;

  *)
    LINE=$(printf "[%s] ∙ HOOK 未知事件: %s" "$TIMESTAMP" "$EVENT")
    ;;
esac

# 双通道输出
echo "$LINE" >> "$LOG_FILE"
if [ "${FLOW_LOG_QUIET:-0}" != "1" ]; then
  echo "$LINE" >&2
fi
