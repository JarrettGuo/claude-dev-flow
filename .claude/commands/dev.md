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
