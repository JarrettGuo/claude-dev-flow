#!/bin/bash
# Progress Display Functions for CLAUDE Dev Flow
# 提供进度条、阶段状态面板、时间估算功能
# 使用方式：source progress.bash 或在命令中直接调用

# ═══════════════════════════════════════════════════════════
# 配置读取
# ═══════════════════════════════════════════════════════════

read_progress_config() {
 if [ -f ".claude/settings.json" ] && command -v jq &>/dev/null; then
 PROGRESS_ENABLED=$(jq -r '.progressDisplay.enabled // true' .claude/settings.json 2>/dev/null)
 PROGRESS_STYLE=$(jq -r '.progressDisplay.style // "full"' .claude/settings.json 2>/dev/null)
 PROGRESS_SHOW_TIME=$(jq -r '.progressDisplay.showTimeEstimate // true' .claude/settings.json 2>/dev/null)
 PROGRESS_CLEAR=$(jq -r '.progressDisplay.clearScreen // false' .claude/settings.json 2>/dev/null)
 else
 PROGRESS_ENABLED=true
 PROGRESS_STYLE=full
 PROGRESS_SHOW_TIME=true
 PROGRESS_CLEAR=false
 fi
}

# ═══════════════════════════════════════════════════════════
# 工具函数
# ═══════════════════════════════════════════════════════════

get_term_width() {
 echo "${TERM_WIDTH:-$(tput cols 2>/dev/null || echo 80)}"
}

get_color_support() {
 if [ -t 1 ] && [ -n "$(tput colors 2>/dev/null)" ] && [ "$(tput colors 2>/dev/null)" -ge 8 ]; then
 echo 1
 else
 echo 0
 fi
}

# ═══════════════════════════════════════════════════════════
# 进度条生成
# ═══════════════════════════════════════════════════════════

progress_bar() {
 local percent=$1
 local width=${2:-10}
 local filled=$((percent * width / 100))
 local empty=$((width - filled))

 # Emoji-free ASCII 版本（兼容性优先）
 local bar=$(printf "%${filled}s" | tr ' ' '#')
 bar+=$(printf "%${empty}s" | tr ' ' '-')

 echo "[${bar}] ${percent}%"
}

progress_bar_simple() {
 local percent=$1
 local width=${2:-10}
 local filled=$((percent * width / 100))
 local empty=$((width - filled))

 local bar=$(printf "%${filled}s" | tr ' ' '=')
 bar+=$(printf "%${empty}s" | tr ' ' '.')

 echo "[${bar}] ${percent}%"
}

# ═══════════════════════════════════════════════════════════
# 状态面板生成（full 模式）
# ═══════════════════════════════════════════════════════════

gen_progress_panel() {
 local cmd_name=$1
 local phase=$2
 local total_phases=$3
 local current_agent=$4
 local agent_status=$5 # format: "name:status,name:status"
 local elapsed_sec=$6
 local pct=$7

 local term_width=$(get_term_width)
 local max_width=$((term_width - 4))
 [ "$max_width" -gt 60 ] && max_width=60
 [ "$max_width" -lt 40 ] && max_width=40

 # 计算时间
 local elapsed_min=$((elapsed_sec / 60))
 local elapsed_display="${elapsed_min}min"

 # 估算剩余时间
 local remaining=""
 if [ "$PROGRESS_SHOW_TIME" = true ] && [ -n "$COMPLETED_PHASES" ] && [ "$COMPLETED_PHASES" -gt 0 ]; then
 local avg_sec=$((TOTAL_ELAPSED_SEC / COMPLETED_PHASES))
 local remaining_phases=$((total_phases - phase))
 local est_sec=$((avg_sec * remaining_phases))
 local est_min=$((est_sec / 60))
 remaining="~${est_min}min"
 fi

 # 解析 agent 状态
 local agents_lines=""
 local IFS_BAK=$IFS
 IFS=','
 local agents_list=""
 for entry in $agent_status; do
 local name="${entry%%:*}"
 local status="${entry##*:}"
 local icon=""
 case "$status" in
 complete) icon="[OK]" ;;
 running) icon="[>>]" ;;
 pending) icon="[..]" ;;
 error) icon="[!!]" ;;
 *) icon="[??]" ;;
 esac
 agents_lines+="  $icon $name\n"
 done
 IFS=$IFS_BAK

 # 构建面板
 local header="== $cmd_name =="
 local pct_line="## $(progress_bar_simple "$pct") phase $phase/$total_phases"

 local panel=""
 panel+="$(printf '%*s\n' "$max_width" '' | tr ' ' '=')\n"
 panel+="$header\n"
 panel+="$(printf '%*s\n' "$max_width" '' | tr ' ' '=')\n"
 panel+="$pct_line\n"
 [ -n "$remaining" ] && panel+="## elapsed: ${elapsed_display} | est: ${remaining}\n"
 panel+="---\n"
 [ -n "$agents_lines" ] && panel+="$agents_lines"
 panel+="$(printf '%*s\n' "$max_width" '' | tr ' ' '-')\n"

 echo -e "$panel"
}

# ═══════════════════════════════════════════════════════════
# 简洁更新（simple 模式）
# ═══════════════════════════════════════════════════════════

gen_simple_update() {
 local phase=$1
 local total_phases=$2
 local current_agent=$3
 local pct=$4
 local remaining=$5

 local bar=$(progress_bar_simple "$pct" 8)
 echo "## $bar phase $phase/$total_phases @${current_agent}${remaining:+, est: ${remaining}}"
}

# ═══════════════════════════════════════════════════════════
# 主显示函数
# ═══════════════════════════════════════════════════════════

progress_display() {
 read_progress_config

 [ "$PROGRESS_ENABLED" != true ] && return 0

 local cmd_name=${1:-"/dev"}
 local phase=${2:-1}
 local total_phases=${3:-6}
 local current_agent=${4:-""}
 local agent_status=${5:-""}
 local elapsed_sec=${6:-0}
 local pct=${7:-0}
 local remaining=${8:-""}

 case "$PROGRESS_STYLE" in
 simple)
 echo -e "$(gen_simple_update "$phase" "$total_phases" "$current_agent" "$pct" "$remaining")"
 ;;
 minimal)
 echo "## $pct% @${current_agent}"
 ;;
 full|*)
 echo -e "$(gen_progress_panel "$cmd_name" "$phase" "$total_phases" "$current_agent" "$agent_status" "$elapsed_sec" "$pct")"
 ;;
 esac
}

# ═══════════════════════════════════════════════════════════
# 阶段状态报告
# ═══════════════════════════════════════════════════════════

# 全局状态（供进度计算用）
PROGRESS_CMD_NAME=""
PROGRESS_TOTAL_PHASES=0
PROGRESS_START_TIME=0
PROGRESS_COMPLETED_PHASES=0
PROGRESS_TOTAL_ELAPSED_SEC=0

progress_init() {
 PROGRESS_CMD_NAME=$1
 PROGRESS_TOTAL_PHASES=$2
 PROGRESS_START_TIME=$(date +%s)
 PROGRESS_COMPLETED_PHASES=0
 PROGRESS_TOTAL_ELAPSED_SEC=0
}

progress_phase_complete() {
 local phase=$1
 local elapsed_sec=$2

 PROGRESS_COMPLETED_PHASES=$((PROGRESS_COMPLETED_PHASES + 1))
 PROGRESS_TOTAL_ELAPSED_SEC=$((PROGRESS_TOTAL_ELAPSED_SEC + elapsed_sec))
}

progress_get_elapsed() {
 echo $(($(date +%s) - PROGRESS_START_TIME))
}

progress_calc_pct() {
 local phase=$1
 local total=$2
 local completed=$3

 # 基础进度：已完成 phases * 100 / total
 local base_pct=$((completed * 100 / total))
 # 当前 phase 进度：加权计算
 local phase_pct=$(((phase - 1) * 100 / total))
 echo $((base_pct + phase_pct / 2))
}

# 便捷包装函数（供命令文件调用）
progress_phase_start() {
 read_progress_config
 [ "$PROGRESS_ENABLED" != true ] && return 0

 local phase_name=$1
 local phase_num=$2
 local total=$3
 local agent=$4
 local elapsed=$(progress_get_elapsed)
 local pct=$(progress_calc_pct "$phase_num" "$total" "$PROGRESS_COMPLETED_PHASES")

 progress_display "$PROGRESS_CMD_NAME" "$phase_num" "$total" "$agent" "" "$elapsed" "$pct"
}

progress_phase_done() {
 local phase_num=$1
 local elapsed_sec=$2

 progress_phase_complete "$phase_num" "$elapsed_sec"
}

progress_agent_done() {
 local agent=$1
 local elapsed_sec=$2

 # 这个函数只是记录，不做显示
 # 显示由 progress_phase_start 在下一阶段时更新
 :
}
