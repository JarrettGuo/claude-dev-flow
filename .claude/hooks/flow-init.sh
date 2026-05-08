#!/usr/bin/env bash
# Phase 1 初始化：检测异常中断、创建 FLOW.log、写 header、启动 progress
# 用法: bash .claude/hooks/flow-init.sh <feature> <command> <input_summary> <phase_num> <phase_name> <agent> <total_phases>
#
# 示例:
#   bash .claude/hooks/flow-init.sh "user-avatar-upload" "/dev" "用户头像上传功能" 1 "Analyze" "analyst" 6

set -eu

FEATURE_NAME="$1"
COMMAND="$2"
INPUT_SUMMARY="$3"
PHASE_NUM="$4"
PHASE_NAME="$5"
AGENT="$6"
TOTAL="$7"

CURRENT_FLOW_FILE=".dev-flow/.current-flow"

# 检测异常中断
# 参考 gate-wait.sh 范式：脚本只做检测和信号输出，真正的"等待用户决策"
# 由调用方的 LLM prompt 层负责（见 dev.md / fix.md 的 STOP 块）。
# Claude Code 的 Bash tool 以子进程执行，stdin 不连用户终端，
# 任何 read 调用会立即得到 EOF，因此这里绝不使用 read。
if [ -f "$CURRENT_FLOW_FILE" ]; then
  PREV_FLOW=$(cat "$CURRENT_FLOW_FILE")
  PREV_LOG=".dev-flow/${PREV_FLOW}/FLOW.log"
  if [ -f "$PREV_LOG" ] && ! grep -q "COMPLETED:" "$PREV_LOG"; then
    if [ "${FLOW_INIT_FORCE:-0}" = "1" ]; then
      # 强制模式：清理旧状态，继续创建新 flow
      rm -f .dev-flow/.current-flow .dev-flow/.current-phase .dev-flow/.phase-start
    else
      FLOW_NAME="${PREV_FLOW#specs/}"
      FLOW_NAME="${FLOW_NAME#fixes/}"
      echo "DETECTED_ABANDONED_FLOW: ${PREV_FLOW}" >&2
      echo "上一次 flow（${FLOW_NAME}）异常中断，FLOW.log 中无 COMPLETED: 标记。" >&2
      echo "" >&2
      echo "如何处理：" >&2
      echo "  [清理] 设置 FLOW_INIT_FORCE=1 重新调用本脚本，丢弃旧状态开始新 flow" >&2
      echo "  [退出] 不做任何操作，手动检查 .dev-flow/${PREV_FLOW}/ 后再决定" >&2
      echo "  [复盘] 运行 /flow-debug ${FLOW_NAME}，复完盘后再回来" >&2
      exit 2
    fi
  fi
fi

# flow 类型由 FLOW_TYPE_OVERRIDE 环境变量控制
# /dev 不传 → 默认 specs；/fix 传 FLOW_TYPE_OVERRIDE=fixes → 写到 fixes/
FLOW_TYPE="${FLOW_TYPE_OVERRIDE:-specs}"

# 合法性检查：只接受 specs 或 fixes
if [ "$FLOW_TYPE" != "specs" ] && [ "$FLOW_TYPE" != "fixes" ]; then
  echo "❌ FLOW_TYPE_OVERRIDE 必须是 'specs' 或 'fixes'（当前: '${FLOW_TYPE}'）" >&2
  exit 1
fi

FEATURE="${FLOW_TYPE}/${FEATURE_NAME}"
mkdir -p ".dev-flow/${FEATURE}"

# 清理上次流程残留的 agent 时间戳（防止误关联）
rm -f .dev-flow/.agent-*.start .dev-flow/.jq-warned

echo "$FEATURE" > "$CURRENT_FLOW_FILE"

LOG_FILE=".dev-flow/${FEATURE}/FLOW.log"

cat > "$LOG_FILE" <<EOF
═══════════════════════════════════════════════════════════
 FLOW LOG: ${FEATURE_NAME}
 Command: ${COMMAND}
 Started: $(date +'%Y-%m-%d %H:%M:%S')
 Project: $(pwd)
═══════════════════════════════════════════════════════════

EOF

TS=$(date +"%H:%M:%S")
LINE1=$(printf "[%s] ▶ START %s 启动\n" "$TS" "$COMMAND")
LINE2=$(printf "[%s] ∙ INPUT %s\n" "$TS" "$INPUT_SUMMARY")

echo "$LINE1" >> "$LOG_FILE"
echo "$LINE2" >> "$LOG_FILE"

# 写 Phase 1 分隔符和启动
{
  printf "\n─── Phase %s: %s ──────────────────────────────────────\n" "$PHASE_NUM" "$PHASE_NAME"
  printf "[%s] ▶ PHASE Phase %s 启动\n" "$TS" "$PHASE_NUM"
} >> "$LOG_FILE"

# 记录 phase 起始时间（供 phase-complete 计算耗时用）
date +%s > .dev-flow/.phase-start

# 简洁终端提示(单行紧凑 banner,只在终端显示,不污染 FLOW.log)
if [ "${FLOW_LOG_QUIET:-0}" != "1" ]; then
  printf "════════════════ Phase %s/%s: %s @%s ════════════════════════════════════════════════\n" "$PHASE_NUM" "$TOTAL" "$PHASE_NAME" "$AGENT" >&2
fi
