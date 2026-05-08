#!/usr/bin/env bash
# COMPLETE + footer + 清理状态
# 用法: bash .claude/hooks/flow-footer.sh [final_phase]
#
# 示例:
#   bash .claude/hooks/flow-footer.sh 6
set -eu
CURRENT_FLOW_FILE=".dev-flow/.current-flow"
[ -f "$CURRENT_FLOW_FILE" ] || exit 0

FEATURE=$(cat "$CURRENT_FLOW_FILE")
FLOW_TYPE=$(echo "$FEATURE" | cut -d'/' -f1)
FLOW_NAME=$(echo "$FEATURE" | cut -d'/' -f2)
LOG_FILE=".dev-flow/${FLOW_TYPE}/${FLOW_NAME}/FLOW.log"

[ -f "$LOG_FILE" ] || exit 0

FINAL_PHASE="${1:-}"

TS=$(date +"%H:%M:%S")

# 计算最终 elapsed
ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))

# 写 COMPLETE 事件
COMMAND_NAME=$(echo "$FEATURE" | cut -d'/' -f1 | sed 's/specs/dev/;s/fixes/fix/')
LINE=$(printf "[%s] ✓ COMPLETE /%s 流程完成\n" "$TS" "$COMMAND_NAME")
echo "$LINE" >> "$LOG_FILE"
if [ "${FLOW_LOG_QUIET:-0}" != "1" ]; then
  echo "$LINE" >&2
fi

# 清理临时状态
rm -f .dev-flow/.phase-start
rm -f .dev-flow/.current-phase
rm -f .dev-flow/.current-flow
rm -f .dev-flow/.agent-*.start .dev-flow/.jq-warned

# 写 footer
cat >> "$LOG_FILE" <<EOF

═══════════════════════════════════════════════════════════
 COMPLETED: $(date +'%Y-%m-%d %H:%M:%S')
 See .dev-flow/${FEATURE}/ for all deliverables
═══════════════════════════════════════════════════════════
EOF

if [ "${FLOW_LOG_QUIET:-0}" != "1" ]; then
  echo "Flow completed. See .dev-flow/${FEATURE}/" >&2
fi
