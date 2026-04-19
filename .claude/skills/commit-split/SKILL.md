---
name: commit-split
description: 把工作区的大量改动智能分组成多个逻辑上独立的 commit 建议。按 CLAUDE.md 目录约定和 AI 语义审视分组，每组复用 format-commit skill 生成 commit message，最后让用户逐个确认执行。
---

# Commit Split

把一次大改动拆成多个逻辑上独立的 commit。**只输出建议和命令，永不自动执行 commit。**

## 能力范围

**负责**：
- 读 `git diff` 得到所有改动文件
- 按目录约定 + 语义审视把改动分组
- 为每组生成 commit message
- 输出结构化的分组方案（每组：message + 文件清单 + git add 命令）
- 用户确认后按顺序展示 commit 命令

**不负责**：
- 自动执行 `git commit`（由用户逐个跑）
- 拆分同一文件内的不同改动（只按文件为最小单位）
- 推送代码
- 和历史 commit 合并/改写

## 何时启用

- **用户显式触发**：`/commit --split`
- **/dev Phase 5 智能建议**：满足以下任一条件时自动建议走 split：
  - 改动文件数 ≥ 8
  - 改动跨越 ≥ 2 个顶级目录（前端 + 后端同时改）
  - 改动跨越 ≥ 3 种文件类型（代码 / 测试 / 配置 / 文档）

## 输入

- **始终**：通过 Bash 读取 `git status` 和 `git diff`
- **可选**：CLAUDE.md 的目录约定段落

## 分组策略（三级降级）

| 优先级 | 条件 | 策略 |
|-------|------|------|
| 1 | CLAUDE.md 存在且含目录约定 | 按 CLAUDE.md 约定分组 |
| 2 | 能识别常见模式（src/components/ / test/ / docs/ 等） | 按启发式规则分组 |
| 3 | 上面都识别不了 | 按一级目录分组 |

每级之后都有 **AI 语义审视**：AI 读 diff 判断分组是否合理。

## 执行流程

### Step 1：获取改动清单

```bash
CHANGED_FILES=$(git diff --name-only)
STAGED_FILES=$(git diff --cached --name-only)

if [ -n "$STAGED_FILES" ]; then
  ALL_FILES="$STAGED_FILES"
  SCOPE_HINT="(已暂存的改动)"
else
  ALL_FILES="$CHANGED_FILES"
  SCOPE_HINT="(工作区未暂存的改动)"
fi

if [ -z "$ALL_FILES" ]; then
  echo "没有改动可以 commit。"
  exit 0
fi

FILE_COUNT=$(echo "$ALL_FILES" | wc -l | tr -d ' ')
```

### Step 2：读取 CLAUDE.md 目录约定

```bash
DIRECTORY_HINTS=""
if [ -f CLAUDE.md ]; then
  DIRECTORY_HINTS=$(awk '/^## .*项目结构|^## .*目录|^## .*Structure/,/^## /' CLAUDE.md | head -30)
fi
```

### Step 3：机械分组

常见识别规则：
- `client/` / `web/` / `frontend/` / `src/` (SPA) → **前端**
- `server/` / `api/` / `backend/` → **后端**
- `test/` / `tests/` / `__tests__/` / `*.test.*` / `*.spec.*` → **测试**
- `docs/` / `*.md`（非代码内的）→ **文档**
- `migration/` / `migrations/` / `db/` → **数据库**
- `.claude/` / `.github/` / `config/` → **基础设施**

### Step 4：AI 语义审视

审视：
1. **跨组语义**：不同组是否属于同一逻辑特性？（如果是，可能应该合并）
2. **组内分裂**：同组内是否混杂 feat + fix + refactor？（如果是，可能应该再拆）
3. **孤儿文件**：某文件是否不属于任何现有组？

### Step 5：为每组生成 commit message

对每个分组，AI 读该组的 diff 片段，生成 `<type>(<scope>): <subject>`。

### Step 6：输出结构化方案

```
## 📦 Commit 分组方案（共 N 组）

### 组 1 — <group-name>
**Commit message**: `feat(api): 头像上传接口`
**影响文件** (3):
- server/controllers/avatar.ts
- server/services/avatar.ts
- server/routes/avatar.ts

**执行命令**:
```bash
git add server/controllers/avatar.ts server/services/avatar.ts server/routes/avatar.ts
git commit -m "feat(api): 头像上传接口"
```

### 组 2 — <group-name>
...
```

## 红旗检测

每组内仍要检查：
- 混杂多类改动（feat + fix 同组）
- 调试代码残留（`console.log`, `debugger`, `// TODO: remove`）
- 暂存区与工作区不一致

## 降级行为

| 场景 | 行为 |
|------|------|
| 只有一个分组（或文件 < 3） | 输出"改动太少无需拆分，建议走 /commit" |
| CLAUDE.md 缺失且识别不了模式 | 按一级目录分组，message 用通用 scope |
| `git diff` 空 | 报 "没有改动可以 commit" 并退出 |

## 硬性规则

- **绝不执行** `git add` 或 `git commit`，只输出建议
- **绝不拆同一文件内的 hunk**（v1 限制）
- **绝不改 commit 历史**
- **绝不推送**
- 分组数量：最少 1 组，最多 6 组
- 每组 subject 行 ≤ 50 字符

## 示例

**输入**：15 个文件改动（client/ + server/ + test/ + docs/ + migrations/）

**输出**：4 组 commit 建议

```
组 1: feat(db): 头像表 migration
 - server/db/migrations/20260419_avatar.sql

组 2: feat(api): 头像上传接口
 - server/controllers/avatar.ts
 - server/services/avatar.ts

组 3: feat(ui): 头像上传组件
 - client/components/Avatar.vue
 - client/api/avatar.ts

组 4: test+docs(avatar): 单测和文档
 - test/avatar.spec.ts
 - docs/api/avatar.md
 - CHANGELOG.md
```
