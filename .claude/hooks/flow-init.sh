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
if [ -f "$CURRENT_FLOW_FILE" ]; then
  PREV_FLOW=$(cat "$CURRENT_FLOW_FILE")
  PREV_LOG=".dev-flow/${PREV_FLOW}/FLOW.log"
  if [ -f "$PREV_LOG" ] && ! grep -q "COMPLETED:" "$PREV_LOG"; then
    echo "检测到异常中断的上一次 flow: $PREV_FLOW"
    echo "[c] 清理旧状态，开始新 flow"
    echo "[q] 退出手动处理"
    echo "[r] 建议跑 /flow-debug 复盘"
    read -p "选择: " choice
    case "$choice" in
      c) rm -f .dev-flow/.current-flow .dev-flow/.current-phase .dev-flow/.phase-start ;;
      q) exit 1 ;;
      r) echo "请运行: /flow-debug ${PREV_FLOW#specs/}" && exit 1 ;;
      *) echo "无效选择" && exit 1 ;;
    esac
  fi
fi

# flow 类型由 FLOW_TYPE_OVERRIDE 环境变量控制
# /dev 不传 → 默认 specs（向后兼容）
# /fix 传 FLOW_TYPE_OVERRIDE=fixes → 写到 fixes/
FLOW_TYPE="${FLOW_TYPE_OVERRIDE:-specs}"

# 合法性检查：只接受 specs 或 fixes
if [ "$FLOW_TYPE" != "specs" ] && [ "$FLOW_TYPE" != "fixes" ]; then
  echo "❌ FLOW_TYPE_OVERRIDE 必须是 'specs' 或 'fixes'（当前: '${FLOW_TYPE}'）" >&2
  exit 1
fi

FEATURE="${FLOW_TYPE}/${FEATURE_NAME}"
mkdir -p ".dev-flow/${FEATURE}"
echo "$FEATURE" > "$CURRENT_FLOW_FILE"

LOG_FILE=".dev-flow/${FEATURE}/FLOW.log"

cat > "$LOG_FILE" <<'EOF'
═══════════════════════════════════════════════════════════
 FLOW LOG: FEATURE_PLACEHOLDER
 Command: COMMAND_PLACEHOLDER
 Started: TIMESTAMP_PLACEHOLDER
 Project: PWD_PLACEHOLDER
═══════════════════════════════════════════════════════════

EOF

# BSD sed 兼容替换
sed -i '' "s|FEATURE_PLACEHOLDER|${FEATURE_NAME}|g" "$LOG_FILE"
sed -i '' "s|COMMAND_PLACEHOLDER|${COMMAND}|g" "$LOG_FILE"
sed -i '' "s|TIMESTAMP_PLACEHOLDER|$(date +'%Y-%m-%d %H:%M:%S')|" "$LOG_FILE"
sed -i '' "s|PWD_PLACEHOLDER|$(pwd)|g" "$LOG_FILE"

TS=$(date +"%H:%M:%S")
LINE1=$(printf "[%s] ▶ START %s 启动\n" "$TS" "$COMMAND")
LINE2=$(printf "[%s] ∙ INPUT %s\n" "$TS" "$INPUT_SUMMARY")

echo "$LINE1" >> "$LOG_FILE"
echo "$LINE2" >> "$LOG_FILE"
[ "${FLOW_LOG_QUIET:-0}" != "1" ] && echo "$LINE1" && echo "$LINE2" >&2

# 写 Phase 1 分隔符和启动
{
  printf "\n─── Phase %s: %s ──────────────────────────────────────\n" "$PHASE_NUM" "$PHASE_NAME"
  printf "[%s] ▶ PHASE Phase %s 启动\n" "$TS" "$PHASE_NUM"
} >> "$LOG_FILE"
[ "${FLOW_LOG_QUIET:-0}" != "1" ] && {
  printf "\n─── Phase %s: %s ──────────────────────────────────────\n" "$PHASE_NUM" "$PHASE_NAME" >&2
  printf "[%s] ▶ PHASE Phase %s 启动\n" "$TS" "$PHASE_NUM" >&2
}

# 启动 progress
if source .claude/skills/progress-display/progress.bash 2>/dev/null; then
  progress_init "$COMMAND" "$TOTAL" 2>/dev/null || true
  date +%s > .dev-flow/.phase-start
  progress_phase_start "$PHASE_NAME" "$PHASE_NUM" "$TOTAL" "$AGENT" 2>/dev/null || true
fi
