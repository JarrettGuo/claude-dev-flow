---
description: 运行完整 bug 修复流程。协调 bug-analyst → debugger → implementer → reviewer，聚焦最小化、安全、防回归的修复方案。项目技术栈和规范从 CLAUDE.md 读取。
argument-hint: <bug description, error message, or bug report URL>
---

You are the orchestrator for a bug fix workflow. **Minimal, targeted, regression-proof.**

User's bug report: $ARGUMENTS

## Workflow

### Phase 1: Analyze
1. 生成 bug 名（kebab-case，2-4 词）
2. 初始化 flow：
```bash
FEATURE="fixes/<bug-name>"
mkdir -p ".dev-flow/${FEATURE}"
echo "$FEATURE" > ".dev-flow/.current-flow"
FLOW_TYPE_OVERRIDE=fixes bash .claude/hooks/flow-init.sh "<bug-name>" "/fix" "<摘要>" 1 "Analyze" "bug-analyst" 7
```
3. invoke `@bug-analyst`
4. 等待确认：
```bash
bash .claude/hooks/gate-wait.sh "用户确认问题描述"
```

> 🛑 **STOP — 必须真正停下等待用户**
>
> 上一步已经向用户输出了 <Phase 1> 的产出摘要。现在必须把控制权交还给用户。
>
> **你（orchestrator）此刻要做的事：**
> 1. 向用户提问："问题描述是否准确？确认后进入根因诊断。"
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

> bash .claude/hooks/decision.sh "用户确认问题描述 → 进入 Phase 2" 2 "Diagnose" "debugger" 7

（上面这条是指令，不是可直接运行的代码块——当用户确认后你再把它转成实际的 Bash 工具调用。）

### Phase 2: Diagnose
1. invoke `@debugger`（reproduce → isolate → hypothesis → root cause）
2. 等待确认：
```bash
bash .claude/hooks/gate-wait.sh "用户确认根因分析"
```
3. If after 3 rounds still unclear, STOP with guidance

> 🛑 **STOP — 必须真正停下等待用户**
>
> 上一步已经向用户输出了 <Phase 2> 的产出摘要。现在必须把控制权交还给用户。
>
> **你（orchestrator）此刻要做的事：**
> 1. 向用户提问："根因分析是否正确？确认后进入修复方案阶段。"
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

> bash .claude/hooks/decision.sh "用户确认根因 → 进入 Phase 3" 3 "Plan" "architect" 7

（上面这条是指令，不是可直接运行的代码块——当用户确认后你再把它转成实际的 Bash 工具调用。）

### Phase 3: Plan
Produce inline fix plan（简短，一页纸）:
```
## 修复方案
### 根因
### 修复位置
### 改动范围
### 回归测试
### 风险等级
```
Ask: "修复方案确认？(y / n / 编辑)"

> 🛑 **STOP — 必须真正停下等待用户**
>
> 上一步已经向用户输出了修复方案摘要（根因、修复位置、改动范围、回归测试、风险等级）。现在必须把控制权交还给用户。
>
> **你（orchestrator）此刻要做的事：**
> 1. 向用户提问："修复方案是否可行？确认后进入实现阶段。"
> 2. **结束本轮 turn**，不要执行任何后续工具调用
> 3. 等待用户的下一条消息
>
> **严禁在未收到用户明确确认前**继续执行下面"用户确认后"段落里的任何 bash。
>
> 用户回复可能是："y" / "确认" / "继续" / "ok" / 或带修改意见的长文本。
> - 如果是确认类回复 → 执行下面"用户确认后"的 bash
> - 如果是修改意见 → 根据意见调整修复方案，再次回到本 STOP 门
> - 如果是 "n" / "不" / "重来" → 回退到根因诊断

If > 20 lines or affects interface contracts，警告并建议 `/dev`。

**用户确认后**（且仅当用户确认后），执行：

> bash .claude/hooks/decision.sh "用户确认修复方案 → 进入 Phase 4" 4 "Implement" "implementer" 7

（上面这条是指令，不是可直接运行的代码块——当用户确认后你再把它转成实际的 Bash 工具调用。）

### Phase 4: Implement
**按项目类型调度** implementer，传参：
> 这是 bug 修复。约束：最小改动、加回归测试、跑完整测试套件、不改公共接口。

If blocked, invoke `@debugger`。

完成后进入 Phase 5：
```bash
bash .claude/hooks/decision.sh "修复实现完成 → 进入 Phase 5" 5 "Verify" "implementer" 7
```

### Phase 5: Verify
Run via Bash:
1. 复现原 bug（确认已修复）
2. 跑新增回归测试
3. 跑完整测试套件
4. 跑 lint + typecheck

失败则回到 Phase 4：
```bash
bash .claude/hooks/retry.sh "<轮次>" 3
```

通过后进入 Phase 6：
```bash
bash .claude/hooks/decision.sh "验证通过 → 进入 Phase 6" 6 "Review" "reviewer" 7
```

### Phase 6: Review
invoke `@reviewer` with focus on: 最小改动、根因修复、回归测试、边界情况。

Handle:
- **APPROVED**:
```bash
bash .claude/hooks/phase-complete.sh 6
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ COMPLETE Review 通过\n" "$TS" >> "$LOG"
[ "${FLOW_LOG_QUIET:-0}" != "1" ] && printf "[%s] ✓ COMPLETE Review 通过\n" "$TS" >&2
```
进入 Phase 7
- **CHANGES_REQUESTED**:
```bash
bash .claude/hooks/retry.sh "<轮次>" 3
```
- **BLOCKED**:
```bash
bash .claude/hooks/error.sh "Review 被阻止，invoke debugger"
```
invoke `@debugger`

### Phase 7: Commit & Summary
1. Use `format-commit` skill（生成 `fix(...)` commit）
2. Write summary to `.dev-flow/fixes/<bug-name>/summary.md`
3. Complete:
```bash
bash .claude/hooks/flow-footer.sh 7
```
4. Update debugger's MEMORY.md

## Rules
- 绝不自动 commit
- 遵守 `.claude/docs/output-style.md`
- 绝不跳过 Phase 5（verify）
- 绝不让 fix 范围扩大
- verify 通过前不给 commit 建议
- 修复后更新 debugger MEMORY.md
