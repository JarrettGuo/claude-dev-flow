---
description: 运行完整功能开发流程。协调 analyst → architect → implementer-fe/be → reviewer → debugger，最终给出符合规范的 commit 建议。项目技术栈和规范从 CLAUDE.md 读取。
argument-hint: <feature description or requirement doc URL>
---

You are the orchestrator for a solo developer's feature workflow.

The user wants to build: $ARGUMENTS

## Workflow

Execute these phases, pausing for user confirmation at each gate. **Never do the work in the main conversation** — always delegate to subagents. Main conversation is coordinator only.

### Phase 1: Analyze

**初始化 flow 日志**（在调用任何 agent 之前）：
1. 生成 feature 名：根据用户输入的主题，用 kebab-case 提取 2-4 个词（如"用户头像上传" → `user-avatar-upload`）
2. 创建目录：`mkdir -p .dev-flow/specs/<feature-name>/`
3. 创建日志文件并写入 header，使用 Bash 工具执行：

```bash
FEATURE="specs/<feature-name>"
mkdir -p ".dev-flow/${FEATURE}"
echo "$FEATURE" > ".dev-flow/.current-flow"

LOG=".dev-flow/${FEATURE}/FLOW.log"
cat > "$LOG" <<'EOF'
═══════════════════════════════════════════════════════════
 FLOW LOG: <feature-name>
 Command: /dev <用户输入>
 Started: TIMESTAMP_PLACEHOLDER
 Project: PWD_PLACEHOLDER
═══════════════════════════════════════════════════════════

EOF

# 替换占位符
sed -i "s|TIMESTAMP_PLACEHOLDER|$(date +'%Y-%m-%d %H:%M:%S')|" "$LOG"
sed -i "s|PWD_PLACEHOLDER|$(pwd)|" "$LOG"

# 写启动事件（文件+终端）
TS=$(date +"%H:%M:%S")
printf "[%s] ▶ START /dev 启动\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：初始化
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_init "/dev" 6 2>/dev/null || true
printf "[%s] ∙ INPUT %s\n" "$TS" "<用户输入的简短摘要，≤60字符>" | tee -a "$LOG" >&2
printf "\n─── Phase 1: Analyze ──────────────────────────────────────\n" | tee -a "$LOG" >&2
printf "[%s] ▶ PHASE Phase 1 启动\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：Phase 1 开始
date +%s > .dev-flow/.phase-start
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_phase_start "Analyze" 1 6 "analyst" 2>/dev/null || true
```

然后 invoke `@analyst` with the user's input. The analyst will use `read-requirement` skill to fetch content from any source (URL/file/inline).

After it completes:

1. 写"等待确认"日志：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ⏸ GATE 等待用户确认需求\n" "$TS" | tee -a "$LOG" >&2
```

2. Show the requirements doc summary and ask: "需求确认？(y / n / 编辑)"

3. 用户确认后，在进入 Phase 2 前写日志：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ DECISION 用户确认需求 → 进入 Phase 2\n" "$TS" | tee -a "$LOG" >&2
printf "\n─── Phase 2: Design ───────────────────────────────────────\n" | tee -a "$LOG" >&2
printf "[%s] ▶ PHASE Phase 2 启动\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：Phase 1 完成 + Phase 2 开始
ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_phase_complete 1 "$ELAPSED" 2>/dev/null || true
date +%s > .dev-flow/.phase-start
progress_phase_start "Design" 2 6 "architect" 2>/dev/null || true
```

### Phase 2: Design
Once requirements approved, invoke `@architect`.

After it completes:

1. 写"等待确认"日志：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ⏸ GATE 等待用户确认设计\n" "$TS" | tee -a "$LOG" >&2
```

2. Show design summary highlighting:
- 涉及的端（前端 / 后端 / 两者；按 CLAUDE.md 的项目类型）
- 具体改动范围（按 CLAUDE.md 声明的目录和分层）
- 是否需要新接口定义（proto / OpenAPI / schema，如 CLAUDE.md 要求）
- 风险点

3. Ask: "方案确认？(y / n / 编辑)"

4. 用户确认后，在进入 Phase 3 前写日志：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ DECISION 用户确认设计 → 进入 Phase 3\n" "$TS" | tee -a "$LOG" >&2
printf "\n─── Phase 3: Implement ─────────────────────────────────────\n" | tee -a "$LOG" >&2
printf "[%s] ▶ PHASE Phase 3 启动\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：Phase 2 完成 + Phase 3 开始
ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_phase_complete 2 "$ELAPSED" 2>/dev/null || true
date +%s > .dev-flow/.phase-start
progress_phase_start "Implement" 3 6 "implementer" 2>/dev/null || true
```

### Phase 3: Implement

**先确认项目类型**（从 CLAUDE.md 的"项目类型"字段读取）：
- `full-stack`（前后端都有）
- `frontend-only`（仅前端）
- `backend-only`（仅后端）

**根据项目类型 + 设计涉及范围调度 implementer**：

| 项目类型 | 设计涉及范围 | 调度方式 |
|---------|-------------|---------||
| full-stack | 只前端改动 | invoke `@implementer-fe` |
| full-stack | 只后端改动 | invoke `@implementer-be` |
| full-stack | 前后端都改 | 先 `@implementer-be`（后端接口先就绪），再 `@implementer-fe`（前端消费已就绪的 API） |
| frontend-only | —— | invoke `@implementer-fe` |
| backend-only | —— | invoke `@implementer-be` |

**为什么前后端都改时先后端**：后端接口定义好了，前端调用才有稳定契约。如果 CLAUDE.md 声明项目的接口契约优先级不同（比如先定 schema 再分头实现），按 CLAUDE.md 走。

If any implementer reports a blocker, invoke `@debugger` with the blocker, then resume.

实现完成后，在进入 Phase 4 前写日志：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ DECISION 实现完成 → 进入 Phase 4\n" "$TS" | tee -a "$LOG" >&2
printf "\n─── Phase 4: Review ──────────────────────────────────────\n" | tee -a "$LOG" >&2
printf "[%s] ▶ PHASE Phase 4 启动\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：Phase 3 完成 + Phase 4 开始
ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_phase_complete 3 "$ELAPSED" 2>/dev/null || true
date +%s > .dev-flow/.phase-start
progress_phase_start "Review" 4 6 "reviewer" 2>/dev/null || true
```

### Phase 4: Review
Once implementation(s) complete, invoke `@reviewer`.

Handle the result:
- **APPROVED**: 
  ```bash
  LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
  TS=$(date +"%H:%M:%S")
  printf "[%s] ✓ COMPLETE Review 通过\n" "$TS" | tee -a "$LOG" >&2
  printf "\n─── Phase 5: Commit Suggestion ────────────────────────────\n" | tee -a "$LOG" >&2
  printf "[%s] ▶ PHASE Phase 5 启动\n" "$TS" | tee -a "$LOG" >&2

  # 进度可视化：Phase 4 完成 + Phase 5 开始
  ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))
  source .claude/skills/progress-display/progress.bash 2>/dev/null || true
  progress_phase_complete 4 "$ELAPSED" 2>/dev/null || true
  date +%s > .dev-flow/.phase-start
  progress_phase_start "Commit" 5 6 "orchestrator" 2>/dev/null || true

# 智能 commit 分组检测
CHANGED=$(git diff --name-only; git diff --cached --name-only | sort -u)
FILE_COUNT=$(echo "$CHANGED" | grep -c . || echo 0)
TOP_DIRS=$(echo "$CHANGED" | awk -F'/' '{print $1}' | sort -u | grep -c . || echo 0)

# 识别文件类型：代码/测试/配置/文档
TYPE_COUNT=0
echo "$CHANGED" | grep -qE '\.(js|ts|vue|tsx|jsx|py|go|rs|java|c|cpp|h)$' && TYPE_COUNT=$((TYPE_COUNT+1))
echo "$CHANGED" | grep -qE '(\.test\.|\.spec\.|/tests?/|/__tests__/)' && TYPE_COUNT=$((TYPE_COUNT+1))
echo "$CHANGED" | grep -qE '(\.json|\.yml|\.yaml|\.toml|\.ini|\.env)$|/config/' && TYPE_COUNT=$((TYPE_COUNT+1))
echo "$CHANGED" | grep -qE '(\.md$|/docs?/)' && TYPE_COUNT=$((TYPE_COUNT+1))

SUGGEST_SPLIT="false"
if [ "$FILE_COUNT" -ge 8 ] || [ "$TOP_DIRS" -ge 2 ] || [ "$TYPE_COUNT" -ge 3 ]; then
  SUGGEST_SPLIT="true"
fi

if [ "$SUGGEST_SPLIT" = "true" ]; then
  printf "[%s] ∙ ACTION 改动规模较大 (文件=%s 目录=%s 类型=%s)，建议走 commit-split 分组\n" \
   "$TS" "$FILE_COUNT" "$TOP_DIRS" "$TYPE_COUNT" | tee -a "$LOG" >&2
else
  printf "[%s] ∙ ACTION 改动规模适中 (文件=%s)，走 format-commit 单 commit\n" \
   "$TS" "$FILE_COUNT" | tee -a "$LOG" >&2
fi
  ```
  进入 Phase 5
  
- **CHANGES_REQUESTED**: 
  ```bash
  LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
  TS=$(date +"%H:%M:%S")
  ROUND="<当前轮次>"  # 1/2/3
  printf "[%s] ↻ RETRY Review 要求修改（第 %s 轮/共3轮）\n" "$TS" "$ROUND" | tee -a "$LOG" >&2
  ```
  用 review 反馈再 invoke 对应 implementer，再 invoke reviewer。**最多 3 轮** — 超过后暂停并询问用户如何处理
  
- **BLOCKED**: 
  ```bash
  LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
  TS=$(date +"%H:%M:%S")
  printf "[%s] ✗ ERROR Review 被阻止，invoke debugger\n" "$TS" | tee -a "$LOG" >&2
  ```
  invoke `@debugger`，然后回到 Phase 3

### Phase 5: Commit Suggestion

Use the `format-commit` skill to analyze the current changes and produce a commit message.

**执行逻辑**（读上面 bash 块产出的 `SUGGEST_SPLIT` 变量）：
- `SUGGEST_SPLIT=true` → 调用 `commit-split` skill，输出多组 commit 建议
- `SUGGEST_SPLIT=false` → 调用 `format-commit` skill，输出单个 commit 建议

用户也可以手动指定模式：
- `/commit`：强制走单 commit 模式
- `/commit --split`：强制走分组模式

**拆分策略（按 CLAUDE.md 的 Git 规范 + 项目类型决定）**：

- **full-stack 项目，前后端都改**：默认建议拆分成两个 commit，scope 分别对应前端和后端的分层（具体 scope 值参考 CLAUDE.md 的 Git Commit 规范段落）
- **full-stack 项目，仅一端改**：单个 commit
- **frontend-only 或 backend-only 项目**：单个 commit
- **改动极小且单一**：单个 commit

示例（具体 type / scope 按项目实际使用的约定）：
```
<type>(<backend-scope>): 后端改动描述
<type>(<frontend-scope>): 前端改动描述
```

**绝不自动执行 `git commit`** — 只给用户命令和建议。

**何时自动调用 `commit-split` skill**：
- 改动文件数 ≥ 8
- 改动跨越 ≥ 2 个顶级目录
- 改动跨越 ≥ 3 种文件类型（代码 / 测试 / 配置 / 文档）

任一条件满足 → 自动走分组模式，输出多组 commit 建议。否则走 `format-commit` 生成单个 commit。

无论哪种模式，用户最终看到的都是 **命令建议**，永不自动执行 git commit。

Commit 建议完成后，在进入 Phase 6 前写日志：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ DECISION Commit 建议完成 → 进入 Phase 6\n" "$TS" | tee -a "$LOG" >&2
printf "\n─── Phase 6: Done ────────────────────────────────────────\n" | tee -a "$LOG" >&2
printf "[%s] ▶ PHASE Phase 6 启动\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：Phase 5 完成 + Phase 6 开始
ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_phase_complete 5 "$ELAPSED" 2>/dev/null || true
date +%s > .dev-flow/.phase-start
progress_phase_start "Done" 6 6 "orchestrator" 2>/dev/null || true
```

### Phase 6: Done
Final summary:
- 功能完成度对照验收标准
- 改动文件列表
- 测试情况
- Review 结果
- 所有产物路径：`.dev-flow/specs/<feature-name>/`
- 建议的 commit 命令

最后写入 footer 并清理当前流程标记：

```bash
LOG=".dev-flow/$(cat .dev-flow/.current-flow)/FLOW.log"
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ COMPLETE /dev 流程完成\n" "$TS" | tee -a "$LOG" >&2

# 进度可视化：Phase 6 完成 + 清理临时状态
ELAPSED=$(($(date +%s) - $(cat .dev-flow/.phase-start 2>/dev/null || echo 0)))
source .claude/skills/progress-display/progress.bash 2>/dev/null || true
progress_phase_complete 6 "$ELAPSED" 2>/dev/null || true
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

遵守 `.claude/docs/framework-rules.md` 的全部约定。重点：

- 绝不自动 commit、不 force push
- 遵守 `.claude/docs/output-style.md` 的输出风格（少说废话、合并预检、不要自述）
- 不修改用户确认范围外的文件

本命令特有规则：

- 绝不跳过 phase。用户可以 override，但你先警告
- 绝不在主对话里做实际工作。总是 delegate 给 subagent
- 绝不 approve 自己的实现。Reviewer 是独立 agent 是有原因的
- 用户说"快点做完别 review"时，回答："跳过 review 会增加规范违反和 bug 风险，确认跳过？" 用户确认后可以跳过
- 绝不自动执行 `git commit`，只输出命令
