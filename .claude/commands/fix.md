---
description: 运行完整 bug 修复流程。协调 bug-analyst → debugger → implementer → reviewer，聚焦最小化、安全、防回归的修复方案。项目技术栈和规范从 CLAUDE.md 读取。
argument-hint: <bug description, error message, or bug report URL>
---

You are the orchestrator for a bug fix workflow. Bug fixes must be **minimal, targeted, and regression-proof** — different priorities from new feature development.

User's bug report: $ARGUMENTS

## Core Principles

1. **Root cause over symptom** — never patch what you don't understand.
2. **Minimal change** — the smaller the diff, the smaller the regression risk.
3. **Verify first, then fix** — reproduce the bug before changing anything.
4. **Add a regression test** — prevent this bug from coming back.

## Workflow

### Phase 1: Analyze the bug report

**初始化 flow 日志**（在调用任何 agent 之前）：
1. 生成 bug 名：根据用户输入的主题，用 kebab-case 提取 2-4 个词（如"登录后头像不显示" → `login-avatar-missing`）
2. 创建目录：`mkdir -p .dev-flow/fixes/<bug-name>/`
3. 创建日志文件并写入 header，使用 Bash 工具执行：

```bash
FEATURE="fixes/<bug-name>"
mkdir -p ".dev-flow/${FEATURE}"
echo "$FEATURE" > ".dev-flow/.current-flow"

LOG=".dev-flow/${FEATURE}/FLOW.log"
cat > "$LOG" <<'EOF'
═══════════════════════════════════════════════════════════
 FLOW LOG: <bug-name>
 Command: /fix <用户输入>
 Started: TIMESTAMP_PLACEHOLDER
 Project: PWD_PLACEHOLDER
═══════════════════════════════════════════════════════════

EOF

# 替换占位符
sed -i "s|TIMESTAMP_PLACEHOLDER|$(date +'%Y-%m-%d %H:%M:%S')|" "$LOG"
sed -i "s|PWD_PLACEHOLDER|$(pwd)|" "$LOG"

# 写启动事件（文件+终端）
TS=$(date +"%H:%M:%S")
printf "[%s] ▶ START /fix 启动\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：初始化
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_init "/fix" 7 2>/dev/null || true
printf "[%s] ∙ INPUT %s\n" "$TS" "<用户输入的简短摘要，≤60字符>" | tee -a "$LOG" >&2
printf "\n─── Phase 1: Analyze ──────────────────────────────────────\n" | tee -a "$LOG" >&2
printf "[%s] ▶ PHASE Phase 1 启动\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：Phase 1 开始
date +%s > .dev-flow/.phase-start
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_phase_start "Analyze" 1 7 "bug-analyst" 2>/dev/null || true
```

然后 invoke `@bug-analyst` with the user's input. The agent will use `read-requirement` + `fetch-error-context` skills to gather full context.

After it completes:

1. 写"等待确认"日志：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ⏸ GATE 等待用户确认问题描述\n" "$TS" | tee -a "$LOG" >&2
```

2. Show the bug report summary
- If there are `待确认` items, ask user to clarify (max 3 questions)
- If too vague, **pause** and suggest user gather more info (steps / error messages / screenshots)

3. Ask: "问题描述清楚了？(y / n / 编辑)"

4. 用户确认后，在进入 Phase 2 前写日志：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ DECISION 用户确认问题描述 → 进入 Phase 2\n" "$TS" | tee -a "$LOG" >&2
printf "\n─── Phase 2: Diagnose ─────────────────────────────────────\n" | tee -a "$LOG" >&2
printf "[%s] ▶ PHASE Phase 2 启动\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：Phase 1 完成 + Phase 2 开始
ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_phase_complete 1 "$ELAPSED" 2>/dev/null || true
date +%s > .dev-flow/.phase-start
progress_phase_start "Diagnose" 2 7 "debugger" 2>/dev/null || true
```

### Phase 2: Diagnose (root cause analysis)
Invoke `@debugger` with the bug report.

The debugger will:
1. Reproduce the failure
2. Isolate the location
3. Form and verify a hypothesis
4. Identify root cause
5. Write findings to `.dev-flow/fixes/<bug-name>/diagnosis.md`

Show:
- 根本原因
- 涉及的文件和行号
- 建议的修复方向

写"等待确认"日志：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ⏸ GATE 等待用户确认根因分析\n" "$TS" | tee -a "$LOG" >&2
```

Ask: "根因分析正确？可以进入修复？(y / n / 需要更多排查)"

**If "需要更多排查"**: re-invoke `@debugger` with user's additional context.

**If after 3 diagnosis rounds still unclear**: STOP and tell user:
> "经过 3 轮排查仍未定位根因。建议：
> 1. 加临时日志到生产环境收集更多信息
> 2. 寻找同事协助排查
> 3. 考虑是否是环境/配置问题而非代码 bug"

用户确认后，在进入 Phase 3 前写日志：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ DECISION 用户确认根因 → 进入 Phase 3\n" "$TS" | tee -a "$LOG" >&2
printf "\n─── Phase 3: Plan ────────────────────────────────────────\n" | tee -a "$LOG" >&2
printf "[%s] ▶ PHASE Phase 3 启动\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：Phase 2 完成 + Phase 3 开始
ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_phase_complete 2 "$ELAPSED" 2>/dev/null || true
date +%s > .dev-flow/.phase-start
progress_phase_start "Plan" 3 7 "architect" 2>/dev/null || true
```

### Phase 3: Plan the fix (lightweight)

Unlike `/dev`, we do NOT invoke `@architect` for a full design doc. Instead, produce a brief fix plan inline:

```
## 修复方案

### 根因
<一句话>

### 修复位置
- `path/to/file.ts:42` — <改什么，为什么>
- `path/to/other.ts:88` — <改什么，为什么>

### 改动范围
- 涉及端：前端 / 后端 / 两者（按 CLAUDE.md 的项目类型）
- 具体位置：按 CLAUDE.md 声明的目录结构
- 预计改动行数：约 X 行

### 回归测试
将添加：`path/to/test.ts` — <测试内容>

### 副作用评估
- 可能受影响的其他功能：<列出或"无">
- 是否需要接口定义变更（proto / OpenAPI / schema，如 CLAUDE.md 要求）：<是/否>
- 是否影响接口契约：<是/否>

### 风险等级
低 / 中 / 高

### 建议的 commit 类型
fix(<scope>): <subject-draft>
```

Ask: "修复方案确认？(y / n / 编辑)"

**If fix touches > 20 lines or affects interface contracts**: 警告并建议考虑 `/dev` 流程（大 bug 本质是设计问题）。

用户确认后，在进入 Phase 4 前写日志：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ DECISION 用户确认修复方案 → 进入 Phase 4\n" "$TS" | tee -a "$LOG" >&2
printf "\n─── Phase 4: Implement ─────────────────────────────────────\n" | tee -a "$LOG" >&2
printf "[%s] ▶ PHASE Phase 4 启动\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：Phase 3 完成 + Phase 4 开始
ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_phase_complete 3 "$ELAPSED" 2>/dev/null || true
date +%s > .dev-flow/.phase-start
progress_phase_start "Implement" 4 7 "implementer" 2>/dev/null || true
```

### Phase 4: Implement the fix

**先确认项目类型**（从 CLAUDE.md 读取）。

**按项目类型 + fix 涉及范围调度**：

| 项目类型 | fix 涉及 | 调度方式 |
|---------|---------|---------||
| full-stack | 仅前端 | invoke `@implementer-fe` |
| full-stack | 仅后端 | invoke `@implementer-be` |
| full-stack | 两者 | 先 `@implementer-be`（如果涉及接口），再 `@implementer-fe` |
| frontend-only | —— | invoke `@implementer-fe` |
| backend-only | —— | invoke `@implementer-be` |

**Critical instruction to pass to implementers**:
> 这是 bug 修复，不是新功能。约束：
> 1. **最小改动** —— 只改必要的行，不要顺手重构
> 2. **必须加回归测试** —— 至少一个能复现原 bug 的测试；测试框架按 CLAUDE.md 声明
> 3. **跑完整测试套件** —— 不能只跑新测试；命令按 CLAUDE.md 声明
> 4. **不要改公共接口** —— 除非根因就在接口上
> 5. **按 CLAUDE.md 的团队规范**：异常处理、日志上报、监控上报一样不能漏

If implementer hits blocker, invoke `@debugger` again — 可能初始诊断不完整。

实现完成后，在进入 Phase 5 前写日志：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ DECISION 修复实现完成 → 进入 Phase 5\n" "$TS" | tee -a "$LOG" >&2
printf "\n─── Phase 5: Verify ──────────────────────────────────────\n" | tee -a "$LOG" >&2
printf "[%s] ▶ PHASE Phase 5 启动\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：Phase 4 完成 + Phase 5 开始
ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_phase_complete 4 "$ELAPSED" 2>/dev/null || true
date +%s > .dev-flow/.phase-start
progress_phase_start "Verify" 5 7 "implementer" 2>/dev/null || true
```

### Phase 5: Verify

Run verification via Bash:

1. **复现原 bug 的步骤** —— 确认已修复
2. **跑新增的回归测试** —— 确认通过
3. **跑完整测试套件** —— 确认无回归
4. **跑 lint + typecheck** —— 确认规范

Show results. Any失败则：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ↻ RETRY Verify 失败，回到 Phase 4\n" "$TS" | tee -a "$LOG" >&2
```

回到 Phase 4。

验证通过后，在进入 Phase 6 前写日志：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ DECISION 验证通过 → 进入 Phase 6\n" "$TS" | tee -a "$LOG" >&2
printf "\n─── Phase 6: Review ──────────────────────────────────────\n" | tee -a "$LOG" >&2
printf "[%s] ▶ PHASE Phase 6 启动\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：Phase 5 完成 + Phase 6 开始
ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_phase_complete 5 "$ELAPSED" 2>/dev/null || true
date +%s > .dev-flow/.phase-start
progress_phase_start "Review" 6 7 "reviewer" 2>/dev/null || true
```

### Phase 6: Review

Invoke `@reviewer` with focus hint:
> 这是 bug 修复 review，额外关注：
> 1. 改动是否真的最小？有没有夹带无关重构？
> 2. 根因是否真的被修了，还是只是掩盖症状？
> 3. 回归测试是否足够？能否真的复现原 bug？
> 4. 有没有引入新的异常路径或边界情况？

Handle:
- **APPROVED**: 
  ```bash
  LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
  TS=$(date +"%H:%M:%S")
  printf "[%s] ✓ COMPLETE Review 通过\n" "$TS" | tee -a "$LOG" >&2
  printf "\n─── Phase 7: Commit & Summary ────────────────────────────\n" | tee -a "$LOG" >&2
  printf "[%s] ▶ PHASE Phase 7 启动\n" "$TS" | tee -a "$LOG" >&2

  # 进度可视化：Phase 6 完成 + Phase 7 开始
  ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))
  source .claude/skills/progress-display/progress.bash 2>/dev/null || true
  progress_phase_complete 6 "$ELAPSED" 2>/dev/null || true
  date +%s > .dev-flow/.phase-start
  progress_phase_start "Commit" 7 7 "orchestrator" 2>/dev/null || true
  ```
  进入 Phase 7
  
- **CHANGES_REQUESTED**: 
  ```bash
  LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
  TS=$(date +"%H:%M:%S")
  ROUND="<当前轮次>"  # 1/2/3
  printf "[%s] ↻ RETRY Review 要求修改（第 %s 轮/共3轮）\n" "$TS" "$ROUND" | tee -a "$LOG" >&2
  ```
  re-invoke implementer + re-review。最多 3 轮。
  
- **BLOCKED**: 
  ```bash
  LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
  TS=$(date +"%H:%M:%S")
  printf "[%s] ✗ ERROR Review 被阻止，invoke debugger\n" "$TS" | tee -a "$LOG" >&2
  ```
  invoke `@debugger` —— 根因很可能判断错了。

### Phase 7: Commit & Summary

Use the `format-commit` skill to generate a `fix(...)` commit message.

Write final report to `.dev-flow/fixes/<bug-name>/summary.md`:

```
# Fix Summary: <bug-name>

## 原 bug 现象
<一句话>

## 根本原因
<一两句话>

## 修复内容
- 改动文件：
  - `path:line` — <改动>
- 新增测试：
  - `path` — <测试内容>
- 改动行数：+X / -Y

## 验证
- [x] 原复现步骤已无法触发 bug
- [x] 回归测试通过
- [x] 完整测试套件通过
- [x] Lint + typecheck 通过

## Review 结果
<APPROVED / 迭代 N 次后 APPROVED>

## 同类 bug 预防
<根据根因，未来如何避免这类 bug>

## Commit 建议
<来自 format-commit skill 的输出。type 通常是 `fix`，scope 按 CLAUDE.md 的 Git 规范声明的值选择>

## 建议分支
按 CLAUDE.md 的 Git 分支命名规范（通常是 `hotfix/<bug-name>` 或类似）
```

最后写入 footer 并清理当前流程标记：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ COMPLETE /fix 流程完成\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：Phase 7 完成 + 清理临时状态
ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_phase_complete 7 "$ELAPSED" 2>/dev/null || true
rm -f .dev-flow/.phase-start

# footer
cat >> "$LOG" <<EOF

═══════════════════════════════════════════════════════════
 COMPLETED: $(date +'%Y-%m-%d %H:%M:%S')
 See .dev-flow/$(cat .dev-flow/.current-flow)/ for all deliverables
═══════════════════════════════════════════════════════════
EOF

# 清理当前流程标记
rm -f .dev-flow/.current-flow
```

## Rules

- **Never skip Phase 5 (verify).** 未测试的 fix = 新 bug。
- **Never let the fix grow beyond necessary.** 如 implementer 开始重构无关代码，stop it。
- **Never suggest `git commit` without verification passed.**
- **If production is burning and user wants to skip review**: 警告一次，然后 comply。
- **Never execute `git commit` automatically.**
- **Update debugger's MEMORY.md** with the bug pattern — 以后类似 bug 更快。
