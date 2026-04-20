---
name: flow-log
description: Write concise progress entries to the current flow's log file, AND echo the same line to the terminal so the user can see real-time progress. Used by /dev, /fix, all 7 agents, and various commands to maintain observable execution traces.
---

# Flow Log

给整个框架一个"可观察性"能力。每当流程推进（进入 phase / 进入 agent / agent 完成 / 用户确认 / review 结果 / 错误等），都写一行日志。

**双通道**：同一行内容**同时**写入磁盘文件 + 输出到终端。

三级降级（向后兼容）：
| 变量 | 行为 |
|------|------|
| `FLOW_LOG_QUIET=1` | 仅写文件，静默终端 |
| `FLOW_LOG_STDERR=1` | 输出终端（deprecated，语义不直观） |
| 默认 | 输出终端（新默认行为） |

用户开一个 Claude Code 会话就能实时看到进度，不用额外开终端 `tail -f`。

## 能力范围

**负责**：
- 定义日志的统一格式
- 提供标准的写入规范（磁盘文件 + 终端）
- 维护 header / phase 分隔符 / footer 的一致性

**不负责**：
- 分析日志（那是 flow-debugger agent 的事）
- 高频或冗长日志（保持"每条一行、一眼能看懂"）

## 日志位置

- `/dev` 流程：`.dev-flow/specs/<feature>/FLOW.log`
- `/fix` 流程：`.dev-flow/fixes/<bug>/FLOW.log`

文件在流程首次启动时创建，后续所有写入都是追加（`>>`）。

## 标准格式

### 文件头（流程开始时写入一次）

```
═══════════════════════════════════════════════════════════
 FLOW LOG: <feature-or-bug-name>
 Command: /dev <args> 或 /fix <args>
 Started: YYYY-MM-DD HH:MM:SS
 Project: <项目根目录>
═══════════════════════════════════════════════════════════

```

### Phase 分隔符（进入新 phase 时写）

```

─── Phase <N>: <phase-name> ──────────────────────────────
```

### 事件行（所有正常事件）

统一格式：`[HH:MM:SS] <icon> <type> <detail>`

图标和类型：

| 图标 | 类型 | 使用场景 |
|-----|------|---------|
| `▶` | START / ENTER / PHASE | 进入流程 / 进入 agent / 进入 phase |
| `◀` | EXIT | 退出 agent（带耗时） |
| `⏸` | GATE | 等待用户确认 |
| `✓` | DECISION / COMPLETE | 用户决策 / 流程完成 |
| `↻` | RETRY | reviewer 拒绝后重新进入 implementer |
| `⚠` | WARN | 非致命警告（如 MCP 降级、超过预期耗时） |
| `✗` | ERROR | 错误或异常 |
| `∙` | ACTION | agent 内部做的具体动作（读文件、grep、跑命令等） |

### 示例完整日志

```
═══════════════════════════════════════════════════════════
 FLOW LOG: avatar-upload
 Command: /dev 用户资料页加头像上传
 Started: 2026-04-19 14:30:12
 Project: /home/jarrett/workspace/my-project
═══════════════════════════════════════════════════════════

[14:30:12] ▶ START /dev 启动
[14:30:12] ∙ INPUT "用户资料页加头像上传，圆形裁剪，最大 2MB"

─── Phase 1: Analyze ──────────────────────────────────────
[14:30:15] ▶ PHASE Phase 1 启动
[14:30:15] ▶ ENTER @analyst
[14:30:15] ∙ ACTION read-requirement skill → inline text
[14:30:18] ∙ ACTION Grep "avatar|upload" in codebase
[14:30:25] ∙ ACTION Read CLAUDE.md
[14:30:48] ∙ OUTPUT requirements.md (1.2KB, 5 acceptance criteria)
[14:30:48] ◀ EXIT @analyst (33s)
[14:30:48] ⏸ GATE 等待用户确认需求
[14:31:20] ✓ DECISION 用户确认 "y" → 进入 Phase 2

─── Phase 2: Design ───────────────────────────────────────
[14:31:22] ▶ PHASE Phase 2 启动
[14:31:22] ▶ ENTER @architect
[14:31:22] ∙ ACTION search-codebase skill → grep-based
[14:31:25] ∙ ACTION 找到 3 个类似上传组件
[14:31:58] ∙ OUTPUT design.md (2.1KB, 前后端都涉及)
[14:31:58] ◀ EXIT @architect (36s)

...
```

### 尾部（流程完成时写入）

```

═══════════════════════════════════════════════════════════
 COMPLETED: YYYY-MM-DD HH:MM:SS
 Total duration: Xm Ys
 Files changed: 前端 N 新 / M 改, 后端 N 新 / M 改
 Review rounds: N
 Final status: APPROVED / BLOCKED / MANUAL_INTERVENTION
═══════════════════════════════════════════════════════════
```

## 写入规范（实现要求）

所有写入日志的操作**必须**遵循：

1. **双通道输出：默认输出终端，FLOW_LOG_QUIET=1 时静默，FLOW_LOG_STDERR=1 仍兼容**

```bash
LOG_FILE=".dev-flow/specs/${FEATURE}/FLOW.log"
TIMESTAMP=$(date +"%H:%M:%S")
LINE="[${TIMESTAMP}] ▶ ENTER @analyst"

# 写文件（始终）
echo "$LINE" >> "$LOG_FILE"
# 终端输出（FLOW_LOG_QUIET=1 时静默；FLOW_LOG_STDERR=1 仍兼容）
if [ "${FLOW_LOG_QUIET:-0}" != "1" ] || [ "${FLOW_LOG_STDERR:-0}" = "1" ]; then
  echo "$LINE" >&2
fi
```

2. **一行原则**：每条事件占一行，不换行、不分段

3. **简洁原则**：detail 部分不超过 80 字符（总行长 ≤ 100 字符）

4. **时间戳必须**：除 header / footer / 分隔符外，所有事件行必须以 `[HH:MM:SS]` 开头

5. **追加不覆盖**：所有写入用 `>>`，不用 `>`

## 调用方式

### Hook 自动调用（主要方式）

见 `.claude/settings.json` 里的 hooks 配置。Claude Code 会在 subagent start/stop、tool use 等时点自动触发 hook 脚本写日志。

### Agent / Command 显式调用

Agent 或 command 在关键业务节点（如"完成 requirements.md"、"review 得出 CHANGES_REQUESTED"）主动用 Bash 写入一行。格式严格遵循上面规范。

**只写有语义价值的行**，不写机械的步骤（机械步骤由 hook 自动处理）。

### 获取当前 FEATURE 名

Agent / command 需要知道当前 flow 的 feature 名（用作日志路径）。约定：

- `/dev` 和 `/fix` 在流程开始时，把 feature 名写入临时文件 `.dev-flow/.current-flow`
- 后续所有 agent / hook 都从此文件读取
- 流程结束（写完 footer）后删除此文件

## Rules

- **不要写超过 100 字符的行**（难看、打印到终端会换行）
- **不要在日志里记录敏感信息**（token / 密码 / 凭证）
- **不要用日志做数据传递**（agent 之间通信用产物文件）
- 时间戳一律用本地时间（`date +"%H:%M:%S"`）
- 所有字符串内容建议中文优先（除了图标、类型关键词、技术标识符）

## 扩展

未来可能的扩展（不在本次范围）：
- 按级别过滤（INFO / WARN / ERROR）
- 日志压缩 / 归档
- 结构化 JSON 格式（目前故意选纯文本，因为给 GPT / 人类看都最友好）
