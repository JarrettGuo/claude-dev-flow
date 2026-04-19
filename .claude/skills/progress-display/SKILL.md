# Progress Display Skill

提供流程进度可视化功能，在终端中实时显示进度条、阶段状态和预计完成时间。

## 核心概念

- **进度状态**：当前 phase、agent、耗时、预计剩余时间
- **显示层**：额外的可视化层，叠加在纯文本 FLOW.log 之上
- **配置驱动**：通过 `.claude/settings.json` 的 `progressDisplay` 配置控制开关和样式

## 配置项

```json
{
  "progressDisplay": {
    "enabled": true,
    "style": "full",
    "showTimeEstimate": true,
    "clearScreen": false
  }
}
```

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| enabled | boolean | true | 是否启用进度显示 |
| style | string | "full" | 显示样式：full / simple / minimal |
| showTimeEstimate | boolean | true | 是否显示预计剩余时间 |
| clearScreen | boolean | false | 是否清屏后重绘（实验性） |

## 状态结构

```bash
# 全局进度状态（写入临时文件供显示函数读取）
PROGRESS_STATE_FILE=".dev-flow/.progress-state"
```

状态文件格式：
```
PHASE=4
TOTAL_PHASES=6
CURRENT_AGENT=reviewer
PHASE_NAME="Phase 4: Review"
START_TIME=1742451000
AGENTS_STATUS="analyst:complete,architect:complete,implementer:running,reviewer:pending,debugger:pending"
PROGRESS_PCT=65
```

## 显示函数

### progress_bar percent width

生成 ASCII 进度条。

```bash
progress_bar 65 10
# 输出: [██████░░░░] 65%
```

### progress_phase_panel

显示当前阶段的完整状态面板（full 模式）。

```bash
# 输出示例：
┌─ /dev: 用户头像上传功能 ─────────────────────┐
│ 📊 [██████░░░░] 65% | Phase 4/6 │
│ 🕐 已用时: 8min 30s | 预计剩余: 2min │
│ │
│ ✅ @analyst 完成 (2m 30s) │
│ ✅ @architect 完成 (1m 45s) │
│ 🔄 @implementer 进行中... (已耗时 1m) │
│ ⏸️ @reviewer 等待中 │
│ ⏸️ @debugger 等待中 │
└────────────────────────────────────────────┘
```

### progress_simple_update

显示简洁更新（simple 模式）。

```bash
# 输出示例：
📊 [██████░░░░] 65% | Phase 4/6: @reviewer | ~2min
```

### progress_phase_start

报告阶段开始。

```bash
progress_phase_start "Phase 1" "Analyze" 1 6
```

### progress_phase_complete

报告阶段完成。

```bash
progress_phase_complete "Phase 1" "Analyze" 150
# 参数：阶段名 阶段描述 耗时(秒)
```

### progress_agent_start

报告 agent 开始执行。

```bash
progress_agent_start "@analyst" "分析需求"
```

### progress_agent_complete

报告 agent 完成。

```bash
progress_agent_complete "@analyst" "分析需求" 150
# 参数：agent名 描述 耗时(秒)
```

## 时间估算逻辑

基于已完成阶段的平均耗时估算剩余时间：

```bash
# 计算公式：
# avg_phase_time = 已完成阶段总耗时 / 已完成阶段数
# remaining_phases = TOTAL_PHASES - CURRENT_PHASE
# estimated_remaining = avg_phase_time * remaining_phases
```

注意：首次 phase 结束前无法估算（数据不足）。

## 样式变体

### full 模式
完整状态面板，包含所有 agent 状态、已用时间、预计剩余时间。
适用于：本地开发、个人项目。

### simple 模式
单行显示：`📊 [██████░░░░] 65% | Phase 4/6 | ~2min`
适用于：CI/CD、远程终端。

### minimal 模式
仅百分比和当前 agent：`📊 65% @reviewer`
适用于：极窄终端、日志文件（不显示动画）。

## 终端兼容性

```bash
# 检测终端宽度
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)

# 宽度 < 60 时自动降级为 minimal
# 宽度 < 80 时自动降级为 simple

# 检测彩色支持
if [ -t 1 ] && [ -n "$(tput colors 2>/dev/null)" ] && [ "$(tput colors 2>/dev/null)" -ge 8 ]; then
  USE_COLOR=1
else
  USE_COLOR=0
fi
```

## 与 FLOW.log 的关系

进度显示**不写入** FLOW.log，只输出到终端。
FLOW.log 保持完整的文本日志，供 `/flow-debug` 解析。

进度显示函数通过 `tee -a "$LOG" >&2` 将日志写入 FLOW.log，同时通过普通 stdout 输出进度（进度显示函数只输出到 stderr 以分离日志流）。

## 使用示例

```bash
# 在 dev.md 的 phase 切换处调用
source ~/.claude/skills/progress-display/progress.bash

# 初始化进度状态
progress_init "/dev" 6

# 阶段开始
progress_phase_start "Phase 1" "Analyze" 1 6

# Agent 开始
progress_agent_start "@analyst" "分析需求"

# Agent 完成
sleep 30
progress_agent_complete "@analyst" "分析需求" 30

# 阶段完成
progress_phase_complete "Phase 1" "Analyze" 45
```

## 与 flow-log.sh 的集成点

`flow-log.sh` 是 hook 脚本，由 OpenClaw 自动调用。
`progress-display` skill 是被 `.claude/commands/dev.md` 等命令显式调用的辅助库。

两者关系：
- `flow-log.sh`：记录结构化日志到 FLOW.log（必须，不显示进度）
- `progress-display`：显示进度到终端（可选，不写日志）

命令文件可以在调用 `flow-log.sh` 的同时调用 `progress-display` 函数，两者是正交关系。
