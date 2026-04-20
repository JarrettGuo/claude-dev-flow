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
bash .claude/hooks/flow-init.sh "<bug-name>" "/fix" "<摘要>" 1 "Analyze" "bug-analyst" 7
```
3. invoke `@bug-analyst`
4. 等待确认：
```bash
bash .claude/hooks/gate-wait.sh "用户确认问题描述"
```
5. 进入 Phase 2：
```bash
bash .claude/hooks/decision.sh "用户确认问题描述 → 进入 Phase 2" 2 "Diagnose" "debugger" 7
```

### Phase 2: Diagnose
1. invoke `@debugger`（reproduce → isolate → hypothesis → root cause）
2. 等待确认：
```bash
bash .claude/hooks/gate-wait.sh "用户确认根因分析"
```
3. If after 3 rounds still unclear, STOP with guidance
4. 进入 Phase 3：
```bash
bash .claude/hooks/decision.sh "用户确认根因 → 进入 Phase 3" 3 "Plan" "architect" 7
```

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

If > 20 lines or affects interface contracts，警告并建议 `/dev`。

进入 Phase 4：
```bash
bash .claude/hooks/decision.sh "用户确认修复方案 → 进入 Phase 4" 4 "Implement" "implementer" 7
```

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
