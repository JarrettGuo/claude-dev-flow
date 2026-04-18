---
description: Run the full bug fix flow for Vue3 + egg.js projects. Orchestrates bug-analyst → debugger → implementer → reviewer with focus on minimal, safe, regression-proof fixes.
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
Invoke `@bug-analyst` with the user's input. The agent will use `read-requirement` + `fetch-error-context` skills to gather full context.

After it completes:
- Show the bug report summary
- If there are `待确认` items, ask user to clarify (max 3 questions)
- If too vague, **pause** and suggest user gather more info (steps / error messages / screenshots)

Ask: "问题描述清楚了？(y / n / 编辑)"

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

Ask: "根因分析正确？可以进入修复？(y / n / 需要更多排查)"

**If "需要更多排查"**: re-invoke `@debugger` with user's additional context.

**If after 3 diagnosis rounds still unclear**: STOP and tell user:
> "经过 3 轮排查仍未定位根因。建议：
> 1. 加临时日志到生产环境收集更多信息
> 2. 寻找同事协助排查
> 3. 考虑是否是环境/配置问题而非代码 bug"

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
- 前端 / Node 层 / 两边
- 预计改动行数：约 X 行

### 回归测试
将添加：`path/to/test.ts` — <测试内容>

### 副作用评估
- 可能受影响的其他功能：<列出或"无">
- 是否需要 proto 变更：<是/否>
- 是否影响接口契约：<是/否>

### 风险等级
低 / 中 / 高

### 建议的 commit 类型
fix(<scope>): <subject-draft>
```

Ask: "修复方案确认？(y / n / 编辑)"

**If fix touches > 20 lines or affects interface contracts**: 警告并建议考虑 `/dev` 流程（大 bug 本质是设计问题）。

### Phase 4: Implement the fix

Based on fix scope:
- **仅前端**: invoke `@implementer-fe`
- **仅 Node 层**: invoke `@implementer-be`
- **两边都改**: 先 be 再 fe

**Critical instruction to pass to implementers**:
> 这是 bug 修复，不是新功能。约束：
> 1. **最小改动** —— 只改必要的行，不要顺手重构
> 2. **必须加回归测试** —— 至少一个能复现原 bug 的测试
> 3. **跑完整测试套件** —— 不能只跑新测试
> 4. **不要改公共接口** —— 除非根因就在接口上
> 5. 按团队规范：异常处理、日志上报、监控上报一样不能漏

If implementer hits blocker, invoke `@debugger` again — 可能初始诊断不完整。

### Phase 5: Verify

Run verification via Bash:

1. **复现原 bug 的步骤** —— 确认已修复
2. **跑新增的回归测试** —— 确认通过
3. **跑完整测试套件** —— 确认无回归
4. **跑 lint + typecheck** —— 确认规范

Show results. Any失败则回到 Phase 4。

### Phase 6: Review

Invoke `@reviewer` with focus hint:
> 这是 bug 修复 review，额外关注：
> 1. 改动是否真的最小？有没有夹带无关重构？
> 2. 根因是否真的被修了，还是只是掩盖症状？
> 3. 回归测试是否足够？能否真的复现原 bug？
> 4. 有没有引入新的异常路径或边界情况？

Handle:
- **APPROVED**: 进入 Phase 7
- **CHANGES_REQUESTED**: re-invoke implementer + re-review。最多 3 轮。
- **BLOCKED**: invoke `@debugger` —— 根因很可能判断错了。

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
<来自 format-commit skill 的输出>

## 建议分支
`hotfix/<bug-name>`
```

## Rules

- **Never skip Phase 5 (verify).** 未测试的 fix = 新 bug。
- **Never let the fix grow beyond necessary.** 如 implementer 开始重构无关代码，stop it。
- **Never suggest `git commit` without verification passed.**
- **If production is burning and user wants to skip review**: 警告一次，然后 comply。
- **Never execute `git commit` automatically.**
- **Update debugger's MEMORY.md** with the bug pattern — 以后类似 bug 更快。
