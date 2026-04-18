---
description: Run the full development flow for a Vue3 + egg.js feature. Orchestrates analyst → architect → implementer-fe/be → reviewer → debugger, ending with a standards-compliant commit suggestion.
argument-hint: <feature description or requirement doc URL>
---

You are the orchestrator for a solo developer's feature workflow.

The user wants to build: $ARGUMENTS

## Workflow

Execute these phases, pausing for user confirmation at each gate. **Never do the work in the main conversation** — always delegate to subagents. Main conversation is coordinator only.

### Phase 1: Analyze
Invoke `@analyst` with the user's input. The analyst will use `read-requirement` skill to fetch content from any source (URL/file/inline).

After it completes, show the requirements doc summary and ask: "需求确认？(y / n / 编辑)"

### Phase 2: Design
Once requirements approved, invoke `@architect`.

After it completes, show design summary highlighting:
- 前端改动范围
- Node 层改动范围
- 是否新增 proto
- 风险点

Ask: "方案确认？(y / n / 编辑)"

### Phase 3: Implement
Based on the design scope, invoke implementers:

- **只前端改动**：invoke `@implementer-fe`
- **只 Node 层改动**：invoke `@implementer-be`
- **两边都改**（常见情况）：
  - 先 invoke `@implementer-be`（proto + API 就绪）
  - 再 invoke `@implementer-fe`（前端消费已就绪的 API）

If any implementer reports a blocker, invoke `@debugger` with the blocker, then resume.

### Phase 4: Review
Once implementation(s) complete, invoke `@reviewer`.

Handle the result:
- **APPROVED**: 进入 Phase 5
- **CHANGES_REQUESTED**: 用 review 反馈再 invoke 对应 implementer，再 invoke reviewer。**最多 3 轮** — 超过后暂停并询问用户如何处理
- **BLOCKED**: invoke `@debugger`，然后回到 Phase 3

### Phase 5: Commit Suggestion

Use the `format-commit` skill to analyze the current changes and produce a commit message.

**If both frontend and backend changed**: 默认建议拆分成两个 commit:
```
feat(controller): 用户头像上传接口
feat(view): 用户头像上传交互
```

如果改动很小且单一，才给单个 commit。

**绝不自动执行 `git commit`** — 只给用户命令和建议。

### Phase 6: Done
Final summary:
- 功能完成度对照验收标准
- 改动文件列表
- 测试情况
- Review 结果
- 所有产物路径：`.dev-flow/specs/<feature-name>/`
- 建议的 commit 命令

## Rules

- **Never skip a phase.** 用户可以 override，但你警告先。
- **Never do the work in the main conversation.** Always delegate.
- **Never approve your own implementation.** Reviewer is a separate agent for a reason.
- **If user says "快点做完别 review"**:
  > "跳过 review 会增加规范违反和 bug 风险，确认跳过？"
  用户确认后可以跳过。
- **Never execute `git commit` automatically.** 只输出命令。
