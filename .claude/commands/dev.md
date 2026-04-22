---
description: 运行完整功能开发流程。协调 analyst → architect → implementer-fe/be → reviewer → debugger，最终给出符合规范的 commit 建议。项目技术栈和规范从 CLAUDE.md 读取。
argument-hint: <feature description or requirement doc URL>
---

You are the orchestrator for a solo developer's feature workflow.

The user wants to build: $ARGUMENTS

## Workflow

### Phase 1: Analyze
1. 生成 feature 名（kebab-case，2-4 词）
2. 初始化 flow：
```bash
FEATURE="specs/<feature-name>"
mkdir -p ".dev-flow/${FEATURE}"
echo "$FEATURE" > ".dev-flow/.current-flow"
bash .claude/hooks/flow-init.sh "<feature-name>" "/dev" "<摘要>" 1 "Analyze" "analyst" 6
```
3. invoke `@analyst`
4. 等待确认：
```bash
bash .claude/hooks/gate-wait.sh "用户确认需求"
```

> 🛑 **STOP — 必须真正停下等待用户**
>
> 上一步已经向用户输出了 <Phase 1> 的产出摘要。现在必须把控制权交还给用户。
>
> **你（orchestrator）此刻要做的事：**
> 1. 向用户提问："需求是否准确？确认后进入设计阶段。"
> 2. **结束本轮 turn**，不要执行任何后续工具调用
> 3. 等待用户的下一条消息
>
> **严禁在未收到用户明确确认前**继续执行下面"用户确认后"段落里的任何 bash。
>
> 用户回复可能是："y" / "确认" / "继续" / "ok" / 或带修改意见的长文本。
> - 如果是确认类回复 → 执行下面"用户确认后"的 bash
> - 如果是修改意见 → 根据意见调整产出，再次回到本 STOP 门
> - 如果是 "n" / "不" / "重来" → 回退到上一步重新处理

**用户确认后**（且仅当用户确认后），执行：

> bash .claude/hooks/decision.sh "用户确认需求 → 进入 Phase 2" 2 "Design" "architect" 6

（上面这条是指令，不是可直接运行的代码块——当用户确认后你再把它转成实际的 Bash 工具调用。）

### Phase 2: Design
1. invoke `@architect`
2. 等待确认：
```bash
bash .claude/hooks/gate-wait.sh "用户确认设计"
```

> 🛑 **STOP — 必须真正停下等待用户**
>
> 上一步已经向用户输出了 <Phase 2> 的产出摘要。现在必须把控制权交还给用户。
>
> **你（orchestrator）此刻要做的事：**
> 1. 向用户提问："设计方案是否合理？确认后进入实现阶段。"
> 2. **结束本轮 turn**，不要执行任何后续工具调用
> 3. 等待用户的下一条消息
>
> **严禁在未收到用户明确确认前**继续执行下面"用户确认后"段落里的任何 bash。
>
> 用户回复可能是："y" / "确认" / "继续" / "ok" / 或带修改意见的长文本。
> - 如果是确认类回复 → 执行下面"用户确认后"的 bash
> - 如果是修改意见 → 根据意见调整产出，再次回到本 STOP 门
> - 如果是 "n" / "不" / "重来" → 回退到上一步重新处理

**用户确认后**（且仅当用户确认后），执行：

> bash .claude/hooks/decision.sh "用户确认设计 → 进入 Phase 3" 3 "Implement" "implementer" 6

（上面这条是指令，不是可直接运行的代码块——当用户确认后你再把它转成实际的 Bash 工具调用。）

### Phase 3: Implement
**确认项目类型**（frontend-only / backend-only / full-stack），按设计范围调度 implementer：

| 项目类型 | 范围 | 调度 |
|---------|------|------|
| full-stack | 前端 | `@implementer-fe` |
| full-stack | 后端 | `@implementer-be` |
| full-stack | 两者 | 先 `@implementer-be`，再 `@implementer-fe` |
| 其他 | —— | 对应 implementer |

If blocked, invoke `@debugger`.

#### 并行调度分支（仅当 design.md 含"并行工作单元"章节时激活）

**步骤 1 — 检测**

读取 `.dev-flow/specs/<feature-name>/design.md`，检查是否存在 `## 并行工作单元` 二级标题：
- 不存在 → 直接执行上方顺序调度表，以下所有步骤跳过。
- 存在 → 提取所有 `### 单元 N：<名称>` 子节，收集每个单元的"推荐 agent"字段值和"文件列表"中的每一行路径（去掉前缀 `- ` 和首尾空白）。

**步骤 2 — Precheck 四层检测**（任意一层失败立即降级串行，展示冲突详情，不启动任何 Task）

```bash
# 层 1a：单元文件数量检查
# 任一单元文件数 < 2 → WARN + 降级
# ⚠ WARN 并行单元 <名称> 文件数不足（<N> < 2），降级顺序执行

# 层 1b：跨单元文件重叠检查
# 同一文件出现在 ≥ 2 个单元 → WARN + 降级
# ⚠ WARN 并行冲突: <文件>，降级顺序执行

# 层 1c：共享路径检查
# 任意文件路径包含 types/、shared/、constants/ 目录，或文件名匹配 *.d.ts → WARN + 降级
# ⚠ WARN <文件> 属于共享路径，不允许出现在并行单元，降级顺序执行

# 层 1d：unstaged 改动冲突检查
UNSTAGED=$(git status --porcelain | awk '{print $2}')
# 与所有单元文件列表求交集，有重叠 → WARN + 降级
# ⚠ WARN 声明文件 <文件> 有 unstaged 改动，降级顺序执行
```

所有层通过 → 记录 baseline：
```bash
BASELINE_COMMIT=$(git rev-parse HEAD)
```

**步骤 3 — 并行确认门**

向用户展示：
```
检测到 2 个可并行工作单元：

  单元 1：<名称>  →  @<推荐agent>  （M 个文件）
  单元 2：<名称>  →  @<推荐agent>  （K 个文件）

并行启动？[y / n（顺序执行）]
```

若标注单元数 > 2，补充说明：`仅取前 2 个单元并行，剩余 <X> 个单元在并行完成后顺序执行。`

> 🛑 **STOP — 必须真正停下等待用户**
>
> 上一步已向用户展示并行调度方案。现在必须把控制权交还给用户。
>
> **你（orchestrator）此刻要做的事：**
> 1. 展示上方确认门内容
> 2. **结束本轮 turn**，不要执行任何后续工具调用
> 3. 等待用户的下一条消息
>
> **严禁在未收到用户明确确认前**启动任何 implementer Task。
>
> 用户回复处理：
> - `y` / 确认类 → 执行步骤 4（并行 Task 调用）
> - `n` / `顺序执行` → 按单元顺序顺序执行，不写 WARN
> - 修改意见 → 展示 design.md"并行工作单元"章节原文，询问是否重调用 `@architect` 调整划分

**步骤 4 — 并行 Task 调用**（用户确认后）

写入 FLOW.log，并记录开始时间：
```bash
PARALLEL_START=$(date +%s)
FEATURE_PATH=$(cat .dev-flow/.current-flow 2>/dev/null || echo "")
if [ -n "$FEATURE_PATH" ] && [ -f ".dev-flow/${FEATURE_PATH}/FLOW.log" ]; then
  LOG=".dev-flow/${FEATURE_PATH}/FLOW.log"
  TS=$(date +"%H:%M:%S")
  printf "[%s] ∙ ACTION 并行启动 2 个单元: <单元1名>, <单元2名>\n" "$TS" >> "$LOG"
fi
```

**在同一响应中同时发起 2 个 Task tool calls（并行，非串行）**，每个 Task 传入以下固定格式上下文块：

```
并行工作单元上下文：
UNIT_NAME: <名称>
UNIT_FILES:
  - path/to/file-a
  - path/to/file-b
产物文件：implementation-<单元名>.md
```

调用的 agent 取自 design.md"推荐 agent"字段（implementer-be / implementer-fe / implementer）。

**步骤 5 — Postcheck**（两个 Task 均返回后、进入 Phase 4 前）

两个 Task 均在并行中运行。**每个 Task 返回时立即采样其完成时刻**，不要等另一个 Task 也返回后再统一采样。

**Task 1 返回时**，立即执行：
```bash
UNIT1_END=$(date +%s)
UNIT1_ELAPSED=$((UNIT1_END - PARALLEL_START))
FEATURE_PATH=$(cat .dev-flow/.current-flow 2>/dev/null || echo "")
if [ -n "$FEATURE_PATH" ] && [ -f ".dev-flow/${FEATURE_PATH}/FLOW.log" ]; then
  LOG=".dev-flow/${FEATURE_PATH}/FLOW.log"
  TS=$(date +"%H:%M:%S")
  printf "[%s] ∙ ACTION 单元 <单元1名> 完成 (%ss)\n" "$TS" "$UNIT1_ELAPSED" >> "$LOG"
fi
```

**Task 2 返回时**，立即执行：
```bash
UNIT2_END=$(date +%s)
UNIT2_ELAPSED=$((UNIT2_END - PARALLEL_START))
FEATURE_PATH=$(cat .dev-flow/.current-flow 2>/dev/null || echo "")
if [ -n "$FEATURE_PATH" ] && [ -f ".dev-flow/${FEATURE_PATH}/FLOW.log" ]; then
  LOG=".dev-flow/${FEATURE_PATH}/FLOW.log"
  TS=$(date +"%H:%M:%S")
  printf "[%s] ∙ ACTION 单元 <单元2名> 完成 (%ss)\n" "$TS" "$UNIT2_ELAPSED" >> "$LOG"
fi
```

**两个 Task 均返回后**，计算并写入总耗时：
```bash
TOTAL_ELAPSED=$(( $(date +%s) - PARALLEL_START ))
FEATURE_PATH=$(cat .dev-flow/.current-flow 2>/dev/null || echo "")
if [ -n "$FEATURE_PATH" ] && [ -f ".dev-flow/${FEATURE_PATH}/FLOW.log" ]; then
  LOG=".dev-flow/${FEATURE_PATH}/FLOW.log"
  TS=$(date +"%H:%M:%S")
  printf "[%s] ∙ ACTION 所有并行单元完成，总耗时 %ss\n" "$TS" "$TOTAL_ELAPSED" >> "$LOG"
fi
```

（上方三段 bash 块是给 orchestrator 的示例指令。实际执行时，`<单元1名>`、`<单元2名>` 替换为 design.md 中对应的单元名称。）

```bash
# 收集实际改动文件（unstaged + staged 两者并集）
CHANGED=$( { git diff --name-only; git diff --name-only --cached; } | sort -u )

# 对每个改动文件检查是否在对应单元声明列表中
# 发现越界文件：
#   git checkout -- <越界文件>   # rollback
#   FLOW.log 写 ⚠ WARN postcheck 越界: <文件>，已 rollback，重调度 <单元名>
#   仅重新调度越界单元，另一单元产物不受影响
```

确认每个 agent 已写入对应的 `implementation-<单元名>.md`。

**步骤 6 — 失败模式处理**

| 失败场景 | 处理方式 |
|---------|---------|
| precheck 失败 | 降级串行，展示冲突详情，不启动任何 Task |
| Agent A 中途失败 | 通知 Agent B 停止；等 B 返回；调用 `@debugger` 修复 A；仅重跑 A 单元 |
| postcheck 越界 | rollback 越界文件，仅重调度越界单元 |
| Reviewer 发现跨单元逻辑冲突 | Phase 4 `CHANGES_REQUESTED` 时回 Phase 3 顺序重做；FLOW.log 写 `⚠ WARN review 发现跨单元冲突，顺序重做` |
| 并行超时（v1 不实现） | 用户手动中断后写 `⚠ WARN 用户中断并行，<单元名> 未完成` |

完成后进入 Phase 4：
```bash
bash .claude/hooks/decision.sh "实现完成 → 进入 Phase 4" 4 "Review" "reviewer" 6
```

### Phase 4: Review
1. invoke `@reviewer`
2. Handle result:
- **APPROVED**:
```bash
bash .claude/hooks/phase-complete.sh 4
# commit 分组检测（保留内联逻辑）
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ COMPLETE Review 通过\n" "$TS" >> "$LOG"
[ "${FLOW_LOG_QUIET:-0}" != "1" ] && printf "[%s] ✓ COMPLETE Review 通过\n" "$TS" >&2
# SUGGEST_SPLIT 检测逻辑...
```
进入 Phase 5
- **CHANGES_REQUESTED**:
```bash
bash .claude/hooks/retry.sh "<轮次>" 3
```
最多 3 轮
- **BLOCKED**:
```bash
bash .claude/hooks/error.sh "Review 被阻止，invoke debugger"
```
invoke `@debugger`，回 Phase 3

### Phase 5: Commit Suggestion
Use `format-commit` or `commit-split` skill（按 `SUGGEST_SPLIT` 变量）。

完成后进入 Phase 6：
```bash
bash .claude/hooks/decision.sh "Commit 建议完成 → 进入 Phase 6" 6 "Done" "orchestrator" 6
```

### Phase 6: Done
Show summary and complete:
```bash
bash .claude/hooks/flow-footer.sh 6
```

## Rules
- 绝不自动 commit、不 force push
- 遵守 `.claude/docs/output-style.md`
- 不跳过 phase（用户可 override，但先警告）
- 绝不 approve 自己实现（Reviewer 是独立 agent）
- 绝不自动执行 `git commit`