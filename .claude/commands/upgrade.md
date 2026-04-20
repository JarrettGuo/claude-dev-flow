---
description: 从 GitHub 拉取最新框架并安全升级本项目的 .claude/ 目录（保护用户本地文件与改动）
argument-hint: "[--source <url>] [--with-readme] [--dry-run]"
---

你现在执行 /upgrade 命令：把当前项目的框架文件（.claude/ 下的 agent / command / skill / hook / docs）升级到 GitHub 最新版，保护用户本地文件和用户对框架文件的修改。

## 参数解析

从 "$ARGUMENTS" 解析：
- `--source <url>`：覆盖默认框架源（默认 https://github.com/JarrettGuo/claude-dev-flow）
- `--with-readme`：同步最新的 README.md（默认不动 README）
- `--dry-run`：只展示会做什么，不实际改文件

没有参数就用默认值。

## Phase 1 — 前置检查

**1.1 确认 .claude/ 存在**

```bash
if [ ! -d ".claude" ]; then
 echo "✗ 当前目录不是 claude-dev-flow 框架项目（.claude/ 不存在）"
 exit 1
fi
```

**1.2 确认 git 工作区干净**（可选但强烈建议）

```bash
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
 echo "⚠️ 工作区不干净，升级过程中如遇冲突可能和你未提交的改动混在一起"
 echo "建议先 git stash 或 commit 再升级"
 echo "继续? [y/n]"
fi
```

等用户确认后继续（或用户选 n 则退出）。

**1.3 读本地版本**

```bash
LOCAL_VERSION=""
if [ -f ".claude/.version" ]; then
 LOCAL_VERSION=$(cat .claude/.version)
fi
if [ -z "$LOCAL_VERSION" ]; then
 echo "⚠️ 本地没有 .claude/.version 文件（可能是早期版本或手动拷贝的 .claude/）"
 echo "升级时会把远端所有框架文件作为'新增'处理，不做冲突检测"
 echo "继续? [y/n]"
fi
```

## Phase 2 — 拉取远端框架

**2.1 初始化日志**（如果 flow-log 能力可用）

```bash
# /upgrade 本身也用 flow-log
FEATURE="fixes/upgrade-$(date +%Y%m%d-%H%M%S)"
mkdir -p ".dev-flow/${FEATURE}"
echo "$FEATURE" > ".dev-flow/.current-flow"
LOG=".dev-flow/${FEATURE}/FLOW.log"

cat > "$LOG" <<EOF
═══════════════════════════════════════════════════════════
 FLOW LOG: upgrade
 Command: /upgrade $ARGUMENTS
 Started: $(date +'%Y-%m-%d %H:%M:%S')
 Project: $(pwd)
═══════════════════════════════════════════════════════════

EOF

TS=$(date +"%H:%M:%S")
printf "[%s] ▶ START /upgrade 启动\n" "$TS" >> "$LOG"
[ "${FLOW_LOG_STDERR:-0}" = "1" ] && printf "[%s] ▶ START /upgrade 启动\n" "$TS" >&2
```

**2.2 拉取远端到临时目录**

```bash
SOURCE_URL="${SOURCE_URL:-https://github.com/JarrettGuo/claude-dev-flow}"
TMPDIR=$(mktemp -d -t claude-dev-flow-upgrade-XXXXXX)
trap 'rm -rf "$TMPDIR"' EXIT

TS=$(date +"%H:%M:%S")
printf "[%s] ∙ ACTION 拉取远端: %s\n" "$TS" "$SOURCE_URL" >> "$LOG"
[ "${FLOW_LOG_STDERR:-0}" = "1" ] && printf "[%s] ∙ ACTION 拉取远端: %s\n" "$TS" "$SOURCE_URL" >&2

git clone --quiet "$SOURCE_URL" "$TMPDIR" || {
 printf "[%s] ✗ ERROR 拉取失败\n" "$(date +%H:%M:%S)" >> "$LOG"
 [ "${FLOW_LOG_STDERR:-0}" = "1" ] && printf "[%s] ✗ ERROR 拉取失败\n" "$(date +%H:%M:%S)" >&2
 exit 1
}

REMOTE_SHA=$(cd "$TMPDIR" && git rev-parse HEAD)
REMOTE_SHORT=$(cd "$TMPDIR" && git rev-parse --short HEAD)
REMOTE_MSG=$(cd "$TMPDIR" && git log -1 --format='%s')

printf "[%s] ∙ OUTPUT 远端版本: %s (%s)\n" "$(date +%H:%M:%S)" "$REMOTE_SHORT" "$REMOTE_MSG" >> "$LOG"
[ "${FLOW_LOG_STDERR:-0}" = "1" ] && printf "[%s] ∙ OUTPUT 远端版本: %s (%s)\n" "$(date +%H:%M:%S)" "$REMOTE_SHORT" "$REMOTE_MSG" >&2
```

**2.3 判断是否已经是最新**

```bash
if [ "$LOCAL_VERSION" = "$REMOTE_SHA" ]; then
 echo "✓ 已经是最新版本 ($REMOTE_SHORT)，无需升级"
 printf "[%s] ✓ COMPLETE 已是最新\n" "$(date +%H:%M:%S)" >> "$LOG"
[ "${FLOW_LOG_STDERR:-0}" = "1" ] && printf "[%s] ✓ COMPLETE 已是最新\n" "$(date +%H:%M:%S)" >&2
 rm -f .dev-flow/.current-flow
 exit 0
fi
```

## Phase 3 — 冲突检测（路径 C 核心逻辑）

**3.1 从远端仓库回溯到本地版本**

如果 `LOCAL_VERSION` 存在且在远端 git 历史里能找到，就用它作为"旧基线"做三方对比。

```bash
HAS_BASE="false"
if [ -n "$LOCAL_VERSION" ]; then
 if (cd "$TMPDIR" && git cat-file -e "$LOCAL_VERSION" 2>/dev/null); then
 HAS_BASE="true"
 printf "[%s] ∙ ACTION 使用 %s 作为对比基线\n" "$(date +%H:%M:%S)" "${LOCAL_VERSION:0:7}" >> "$LOG"
 [ "${FLOW_LOG_STDERR:-0}" = "1" ] && printf "[%s] ∙ ACTION 使用 %s 作为对比基线\n" "$(date +%H:%M:%S)" "${LOCAL_VERSION:0:7}" >&2
 else
 printf "[%s] ⚠ WARN 本地版本 %s 在远端历史中找不到（可能是 force push 或手动改过版本号）\n" "$(date +%H:%M:%S)" "${LOCAL_VERSION:0:7}" >> "$LOG"
 [ "${FLOW_LOG_STDERR:-0}" = "1" ] && printf "[%s] ⚠ WARN 本地版本 %s 在远端历史中找不到（可能是 force push 或手动改过版本号）\n" "$(date +%H:%M:%S)" "${LOCAL_VERSION:0:7}" >&2
 fi
fi
```

**3.2 对每个框架文件分三类处理**

列出远端 `.claude/` 下的所有文件：

```bash
REMOTE_FILES=$(cd "$TMPDIR" && find .claude -type f \
 ! -path '.claude/agent-memory-local/*' \
 ! -path '.claude/.version' \
 | sort)
```

对每个文件分类：
- **新增**：本地不存在 → 直接创建
- **用户未改**：本地存在 + 本地 hash = 基线 hash → 直接覆盖（安全）
- **用户改过**：本地存在 + 本地 hash ≠ 基线 hash → 加入冲突列表

```bash
NEW_FILES=()
SAFE_OVERWRITE=()
CONFLICTS=()
UNCHANGED=() # 本地 hash = 远端 hash，啥也不用做

for f in $REMOTE_FILES; do
 REMOTE_HASH=$(cd "$TMPDIR" && git hash-object "$f")

 if [ ! -f "$f" ]; then
 NEW_FILES+=("$f")
 continue
 fi

 LOCAL_HASH=$(git hash-object "$f" 2>/dev/null || sha256sum "$f" | awk '{print $1}')

 if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
 UNCHANGED+=("$f")
 continue
 fi

 # 本地 ≠ 远端，需要判断用户是否改过
 if [ "$HAS_BASE" = "true" ]; then
 BASE_HASH=$(cd "$TMPDIR" && git rev-parse "${LOCAL_VERSION}:${f}" 2>/dev/null || echo "")
 if [ -z "$BASE_HASH" ]; then
 # 基线版本里没这个文件（框架新加的，但本地已有同名文件——罕见）
 CONFLICTS+=("$f")
 elif [ "$LOCAL_HASH" = "$BASE_HASH" ]; then
 SAFE_OVERWRITE+=("$f")
 else
 CONFLICTS+=("$f")
 fi
 else
 # 没有基线，保守起见全部列为潜在冲突
 CONFLICTS+=("$f")
 fi
done
```

**3.3 展示升级预览**

````
## 升级预览

远端: <REMOTE_SHORT> (<REMOTE_MSG>)
本地: <LOCAL_SHORT> 或 "未知"

### 🆕 新增文件（<N> 个）
<列出 NEW_FILES>

### ✅ 安全覆盖（<N> 个，你未改过）
<列出 SAFE_OVERWRITE>

### ⚠️ 冲突（<N> 个，你改过）
<列出 CONFLICTS>

### 🔁 无变化（<N> 个）
（折叠，不展示具体文件名，只显示数量）

### 🛡️ 保护（不动）
- CLAUDE.md / CLAUDE.md.bak
- .mcp.json
- .dev-flow/
- .env / .env.*
- .claude/agent-memory-local/

### 📄 README.md
<如果 --with-readme：将同步最新版>
<否则：保持本地版本>
````

## Phase 4 — 处理冲突（用户决策门）

如果 CONFLICTS 非空：

**4.1 对每个冲突文件询问用户**

````
⚠️ 以下文件你改过，请逐个决定：

[1/3] .claude/agents/reviewer.md
 你比基线多了 15 行
 选项:
 [o] 覆盖（你的改动备份到 .claude.backup-<ts>/）
 [s] 跳过（保留本地版本，下次升级还会问）
 [d] 看 diff 再决定
 [O] 本次全部覆盖（剩余冲突文件都选 o）
 [S] 本次全部跳过（剩余冲突文件都选 s）
 选择:
````

**4.2 先统一备份**

如果有任何文件选了 `o` 或 `O`，先统一备份整个 .claude/：

```bash
BACKUP_DIR=".claude.backup-$(date +%Y%m%d-%H%M%S)"
cp -r .claude "$BACKUP_DIR"
printf "[%s] ∙ ACTION 备份到 %s\n" "$(date +%H:%M:%S)" "$BACKUP_DIR" >> "$LOG"
[ "${FLOW_LOG_STDERR:-0}" = "1" ] && printf "[%s] ∙ ACTION 备份到 %s\n" "$(date +%H:%M:%S)" "$BACKUP_DIR" >&2
```

## Phase 5 — 执行升级

**5.1 DRY-RUN 分支**

如果是 --dry-run，打印决策结果，不改任何文件，退出。

**5.2 真正执行**

```bash
# 处理新增
for f in "${NEW_FILES[@]}"; do
 mkdir -p "$(dirname "$f")"
 cp "$TMPDIR/$f" "$f"
done

# 处理安全覆盖
for f in "${SAFE_OVERWRITE[@]}"; do
 cp "$TMPDIR/$f" "$f"
done

# 处理用户选了覆盖的冲突文件
for f in "${CONFLICTS_TO_OVERWRITE[@]}"; do
 cp "$TMPDIR/$f" "$f"
done

# 智能合并 settings.json
if [ -f ".claude/settings.json" ] && [ -f "$TMPDIR/.claude/settings.json" ]; then
 # 用 jq 合并: 用户键 + 远端 hooks（hooks 以远端为准）
 jq -s '.[0] * {hooks: .[1].hooks}' \
 .claude/settings.json "$TMPDIR/.claude/settings.json" \
 > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json
fi

# 智能合并 .gitignore（仅当用户选 --with-readme 或框架 .gitignore 有变化时）
# 取并集：用户的行 + 远端的行（去重、保序）
if [ -f ".gitignore" ] && [ -f "$TMPDIR/.gitignore" ]; then
 awk '!seen[$0]++' .gitignore "$TMPDIR/.gitignore" > .gitignore.tmp && mv .gitignore.tmp .gitignore
fi

# README 按 --with-readme 决定
if [ "$WITH_README" = "true" ] && [ -f "$TMPDIR/README.md" ]; then
 cp "$TMPDIR/README.md" README.md
fi

# 更新 .version
echo "$REMOTE_SHA" > .claude/.version

# hooks 脚本要可执行
chmod +x .claude/hooks/*.sh 2>/dev/null
```

**5.3 验证**

```bash
# settings.json 是有效 JSON
jq empty .claude/settings.json || echo "⚠️ settings.json 不是有效 JSON，请检查"

# hook 脚本可执行
ls -l .claude/hooks/*.sh

# .version 已更新
cat .claude/.version
```

## Phase 6 — 收尾

**6.1 输出摘要**

````
✅ 升级完成

从 <LOCAL_SHORT> → <REMOTE_SHORT>

- 新增 <N> 个文件
- 覆盖 <N> 个文件（<M> 个有备份）
- 跳过 <N> 个文件（你的改动保留）
- 智能合并: settings.json / .gitignore

备份位置: <BACKUP_DIR>（如有）

建议：
1. 跑一下现有 command 确认框架工作正常（比如 /dev 的 dry test）
2. 如果升级引入了你不需要的新能力，可以 /remove-skill 或 /remove-agent
3. .dev-flow/ 里的历史日志未受影响
````

**6.2 关闭 flow-log**

```bash
TS=$(date +"%H:%M:%S")
printf "[%s] ✓ COMPLETE /upgrade 完成\n" "$TS" >> "$LOG"
[ "${FLOW_LOG_STDERR:-0}" = "1" ] && printf "[%s] ✓ COMPLETE /upgrade 完成\n" "$TS" >&2

cat >> "$LOG" <<EOF

═══════════════════════════════════════════════════════════
 COMPLETED: $(date +'%Y-%m-%d %H:%M:%S')
 From: ${LOCAL_VERSION:0:7}
 To: ${REMOTE_SHA:0:7}
═══════════════════════════════════════════════════════════
EOF
rm -f .dev-flow/.current-flow
```

## Rules

遵守 `.claude/docs/framework-rules.md` 的全部约定。重点：

- 绝不自动 commit、不 force push
- 遵守 `.claude/docs/output-style.md` 的输出风格（少说废话、合并预检、不要自述）
- 不修改用户确认范围外的文件

本命令特有规则：

- 绝不自动执行 `git commit` 升级后的文件（防止在框架仓库跑 `/upgrade` 时误提交）
- 绝不强制推送，绝不 `--force`
- 绝不覆盖这些受保护的用户文件：`CLAUDE.md` / `CLAUDE.md.bak` / `.mcp.json` / `.dev-flow/` / `.env` / `.env.*` / `.claude/agent-memory-local/`
- `.claude/.version` 只在升级末尾由本命令更新，其余时机绝不触碰
- 绝不在用户确认升级前动任何文件
- 所有冲突必须逐个或批量让用户选择，绝不静默覆盖
- 备份目录名固定格式 `.claude.backup-YYYYMMDD-HHMMSS`
- 临时目录用 `mktemp` 并在退出时清理

## 错误处理

- 网络失败：清理临时目录，提示"网络问题，稍后重试"
- git clone 失败：检查 source URL 是否可达，必要时建议改用 --source 指定
- 用户中途取消（Ctrl+C）：清理临时目录，保证本地状态不变
- jq 未安装：降级为"不智能合并 settings.json"，仅覆盖 hooks 部分并提醒用户

```