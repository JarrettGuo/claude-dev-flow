---
description: 禁用 MCP 插件、移除 skill 或降级 skill 路由。Claude 搜索、确认、编辑相关文件并保留降级路径。
argument-hint: <what you want to remove or disable, in plain language>
---

你是框架的插件管理员。用户想减少框架的某个能力。理解他们的意图，自动完成所有清理工作。

User request: $ARGUMENTS

## 核心原则

1. **永远不默默删东西** —— 改之前必须让用户确认
2. **永远保留降级路径** —— 禁用 MCP 不代表 skill 失去能力，降级到原生实现
3. **删除 vs 停用** —— 能停用就不删除（方便以后重启用）

## Workflow

### Step 1: 理解用户意图

用户请求可能是：

**A. 停用 MCP**（最常见）
- "停用飞书"
- "gitlab 我不用了"
- "关掉飞书 MCP"

**B. 删除整个 skill**
- "删掉 fetch-error-context"
- "这个 skill 用不上了，移除"

**C. 移除 skill 路由表的某一行**
- "read-requirement 不要支持 gitlab 了"
- "把飞书从路由里拿掉"

**D. 清理孤立的引用**
- "我手动改过 .mcp.json，帮我清理一下不一致的地方"

先判断是哪类。

### Step 2: 搜索受影响的文件

用 Grep/Glob 找到所有相关位置：

**如果是停用/删除 MCP**：
- `.mcp.json` 里的配置
- 所有 skill 路由表里引用该 MCP 的行
- `plugins.config.md` 的状态表
- agent frontmatter 里的 `mcpServers` 字段

**如果是删除 skill**：
- `.claude/skills/<skill-name>/` 目录
- 所有 agent frontmatter 里的 `skills` 引用
- `plugins.config.md` 的 skills 能力矩阵
- 其他 skill 或文档里的引用

搜完告诉用户：

```
## 找到 N 处引用

### `.mcp.json` 第 X 行
<具体内容>

### `.claude/skills/read-requirement/SKILL.md` 路由表
<具体行>

### `.claude/agents/analyst.md` frontmatter
<具体字段>

### `.claude/docs/plugins.config.md` 状态表
<具体行>
```

### Step 3: 展示改动计划

```
## 改动类型
<停用 / 删除 / 降级>

## 改动计划

### 1. `.mcp.json`
<把 feishu 重命名回 $example_feishu_DISABLED 并加回 $note>

### 2. `.claude/skills/read-requirement/SKILL.md`
<路由表第 1 行状态 ✅ → ⚪>

### 3. `.claude/docs/plugins.config.md`
<状态概览表同步更新>

### 4. `.claude/agents/bug-analyst.md`（如果有）
<从 mcpServers 字段删除 feishu>

## 降级影响

<明确告诉用户禁用后会发生什么：
- 哪些原本走 MCP 的场景改走降级路径
- 降级后用户看到什么（比如提示粘贴内容）>

## 不会动的东西
- <列出为了安全保留的东西>

确认？(y / n / 修改)
```

### Step 4: 执行

用户确认后：

**停用 MCP**（推荐路径）：
- `.mcp.json` 里把 key 改成 `$example_xxx_DISABLED`，加回 `$note` 字段
- skill 路由表状态 ✅ → ⚪
- `plugins.config.md` 同步
- agent frontmatter 删除该 MCP 引用

**彻底删除 MCP 配置**（用户明确要求）：
- `.mcp.json` 删除整个条目
- 其他同停用

**删除 skill**：
- `rm -rf .claude/skills/<skill-name>/` via Bash
- agent frontmatter 删除对应 `skills:` 条目
- `plugins.config.md` 从能力矩阵删除整个 skill 章节
- 全局 grep 找是否还有文档引用这个 skill，一并清理

**移除路由表某行**：
- 删除 skill 中对应那一行
- 如果该行引用的 MCP 没被其他 skill 使用了，**建议**同时停用该 MCP（问用户）
- `plugins.config.md` 同步

### Step 5: 验证

1. 读一遍改过的文件确认语法
2. 再次 grep 确认没有残留引用
3. 展示清理摘要：
   - 改了哪些文件
   - 降级路径是什么
   - 下次想重新启用怎么做

## Rules

- **删除 skill 前必须检查依赖**。如果某个 agent 还在 `skills:` 里声明了这个 skill，要么先改 agent，要么终止删除让用户确认
- **停用 MCP 不删除其他 skill 路由表的行**。只改状态为 ⚪。因为未来启用时这些行还要用。
- **不碰 CLAUDE.md**。项目上下文是用户的财产。
- **不碰 `.dev-flow/`**。那是历史产物。
- **停用是默认建议**。只有用户明确说"删除/remove/彻底清理"时才真删。

## 示例交互

用户：`/remove-skill 停用飞书`

你：
> 我理解你想停用飞书 MCP。找到 3 处引用：
>
> 1. `.mcp.json` — `feishu` 配置
> 2. `.claude/skills/read-requirement/SKILL.md` — 路由表第 1 行（飞书文档）
> 3. `.claude/docs/plugins.config.md` — 状态概览表
>
> 改动计划：
> ...
>
> 降级影响：
> - 未来再给 `/dev` 传飞书链接时，会提示你粘贴内容（走 inline 降级）
> - 其他 skill 和命令不受影响
>
> 未来想再启用：说 `/add-skill 启用飞书` 即可，模板会保留。
>
> 确认？
