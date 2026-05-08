---
description: 添加新 skill 或启用已有 MCP 插件。Claude 引导用户完成配置、编辑相关文件并验证结果。请用此命令而非手动编辑文件。
argument-hint: <what capability you want to add, in plain language>
---

你是框架的插件管理员。用户想增强框架能力。理解他们的意图，自动完成所有配置工作。

User request: $ARGUMENTS

## Workflow

### Step 1: 理解用户意图

用户的请求可能是以下几类之一：

**A. 启用已有 MCP 模板**（最常见）
- "启用飞书"
- "把 gitlab 打开"
- "我要用飞书文档"

**B. 添加新 MCP**（模板里没有的）
- "接入 Jira"
- "加一个 Sentry 错误监控"
- "连接企业微信"

**C. 创建全新 skill**（无现有 skill 能覆盖）
- "加一个能查数据库的能力"
- "做一个生成 API 文档的 skill"

**D. 增强现有 skill 的路由**
- "让 read-requirement 也支持 Confluence"
- "给 fetch-error-context 加上 Datadog 支持"

**E. 从 URL 导入已有 skill**
- "/add-skill https://github.com/user/repo/blob/main/my-skill/SKILL.md"
- "我有一个写好的 skill，链接是 https://..."
- "直接从这个 URL 装 skill: https://..."
- 任何包含 `https://` 且意图是"安装/导入/拉取 skill"的表述

先判断是哪类，告诉用户你的理解，让他们确认。（类别 E 例外：识别到 URL 意图后直接进入 Step 2 执行，无需等用户确认分类。）

### Step 2: 收集必要信息

根据类别问最少必要的问题（最多 3 个）：

**类别 A（启用已有）**：
- 查看 `.mcp.json` 确认模板存在
- 问用户凭证的环境变量名（或让他们确认默认值）

**类别 B（添加新 MCP）**：
- MCP 包名或启动命令
- 需要哪些环境变量
- 增强哪些 skill 的哪些场景

**类别 C（新 skill）**：
- 这个能力要做什么、不做什么
- 哪些 agent 会用
- 有 MCP 支持吗？没 MCP 时的降级逻辑

**类别 D（增强现有）**：
- 判断条件（什么 URL / 什么输入触发）
- 用哪个 MCP
- 放在路由表的什么优先级

**类别 E（从 URL 导入）**：
- 无需提问。直接进入 Step 3：先拉取 URL 内容，推断 skill 名，展示改动计划。

### Step 3: 展示改动计划

在真正改文件前，用这个格式告诉用户（**类别 E 使用专属模板，见下方"类别 E"详细指引**）：

```
## 我将改动

### 1. `.mcp.json`
<新增或启用的配置片段>

### 2. `.claude/skills/<skill-name>/SKILL.md`
<路由表新增的行>

### 3. `.claude/docs/plugins.config.md`
<状态概览更新>

### 4. （如需）`.claude/agents/<agent>.md`
<frontmatter 加 skills 或 mcpServers>

## 你需要做

- 设置环境变量：
  ```
  export XXX_TOKEN="..."
  ```
- 重启 Claude Code session
- 测试：<给一个具体测试命令>

确认以上改动？(y / n / 修改)
```

### Step 4: 执行改动

用户确认后，用 Edit / Write 工具严格按计划改文件。

**规则**：
- `.mcp.json` 里配置必须用 `${ENV_VAR}` 引用，绝不硬编码值
- 路由表的优先级插入位置要合理（最特定的条件在最前面）
- skill 的路由表更新时状态改为 ✅
- `plugins.config.md` 的状态表同步更新
- 如需改 agent frontmatter，只加不删

**类别 E 额外规则**：
- URL 转换、内容拉取、skill 名推断、冲突检测的完整执行流程见下方"类别 E"详细指引
- 写文件前必须先向用户展示计划并等待明确确认（y）
- 拉取失败（网络、404、返回 HTML）时展示明确错误信息，不创建任何文件

### Step 5: 验证改动

改完后：

1. 读一遍改过的文件确认语法正确（`.mcp.json` 必须是有效 JSON）
2. 告诉用户改了什么，给完整摘要
3. 再次提醒他们：设环境变量 + 重启 session + 测试命令

## 具体类别的详细指引

### 类别 A: 启用已有 MCP 模板

当前 `.mcp.json` 里有这些模板（默认 disabled）：
- `$example_feishu_DISABLED`
- `$example_gitlab_DISABLED`

启用步骤：
1. 把 key 从 `$example_feishu_DISABLED` 改成 `feishu`
2. 删除 `$note` 字段
3. 找到所有引用这个 MCP 的 skill，在路由表把状态改 ✅
4. 更新 `plugins.config.md`

### 类别 B: 添加新 MCP

需要问清楚：
- MCP 包名（如 `@atlassian/jira-mcp-server`）
- 启动方式（stdio / http / sse）
- 需要的环境变量
- 哪些 skill 会用它

然后：
1. 在 `.mcp.json` 加新条目（启用状态）
2. 在相关 skill 的路由表加新行
3. 更新 `plugins.config.md`

### 类别 C: 创建全新 skill

使用这个模板在 `.claude/skills/<skill-name>/SKILL.md` 创建：

```markdown
---
name: <skill-name>
description: <一句话说清能力 + 何时激活>
---

# <Skill Name>

## 能力范围
**负责**：
- <...>

**不负责**：
- <...>

## 输入
<...>

## 路由表

| 优先级 | 判断条件 | 实现 | 所需 MCP | 当前状态 |
|-------|---------|------|---------|---------|
| 1 | <MCP 可用时的条件> | <调用方式> | <mcp-name> | ✅/⚪ |
| 2 | 兜底 | <内置实现或明确告知用户> | 无 | ✅ |

## 降级规则
**绝不静默失败**。<具体话术>

## 输出格式
<统一结构>

## 示例
<至少一个 MCP 可用的例子，一个降级例子>

## 扩展此 Skill
<...>
```

然后：
1. 在需要使用它的 agent frontmatter 加 `skills: [<skill-name>]`
2. 更新 `plugins.config.md` 的 skills 能力矩阵

### 类别 D: 增强现有 skill

1. 找到对应 skill 的路由表
2. 在合适优先级插入新行（最特定的在前）
3. 如需新 MCP，走类别 B 流程
4. 更新 `plugins.config.md`

### 类别 E: 从 URL 导入已有 skill

#### URL 转换规则

用户提供的链接可能是浏览器页面链接，需要转换为 raw 内容链接才能拉取文件内容：

- **GitHub 页面链接**（URL 中包含 `github.com` 且路径含 `/blob/`）：
  将域名 `github.com` 替换为 `raw.githubusercontent.com`，并去掉路径中的 `/blob` 部分
  - 原：`https://github.com/alice/tools/blob/main/my-skill/SKILL.md`
  - 改为：`https://raw.githubusercontent.com/alice/tools/main/my-skill/SKILL.md`

- **GitLab 页面链接**（URL 中包含 `gitlab.com` 且路径含 `/-/blob/`）：
  将路径中的 `/-/blob/` 替换为 `/-/raw/`，域名不变
  - 原：`https://gitlab.com/alice/tools/-/blob/main/my-skill/SKILL.md`
  - 改为：`https://gitlab.com/alice/tools/-/raw/main/my-skill/SKILL.md`

- **其他 HTTPS URL**（已是 raw 链接或自托管服务）：直接使用，不转换

如果拉取后内容是 HTML（开头为 `<!DOCTYPE` 或 `<html`），说明链接仍是页面链接而非 raw 链接，此时告知用户并展示推断出的 raw URL 让用户确认。

#### 执行步骤

1. **转换 URL**：按上述规则将用户提供的 URL 转换为 raw 内容链接

2. **拉取内容**：使用 WebFetch 工具拉取转换后的 URL
  - 如果返回内容是 HTML，告知用户，展示推断的 raw URL，询问是否用该地址重试
  - 其他失败情况见下方"错误处理"

3. **推断 skill 名**：
  - 优先从文件内容 YAML frontmatter（文件开头 `---` 之间的部分）读取 `name` 字段值，用作 skill 目录名
  - 如果 frontmatter 不存在或没有 `name` 字段，从 URL 路径取**倒数第二个路径段**作为 skill 目录名
  （例如 URL 末段为 `/my-skill/SKILL.md`，则取 `my-skill`；末段为 `/some-skill/SKILL.md`，则取 `some-skill`）
  - 将推断结果在 Step 3 计划中向用户展示并确认

4. **检查同名冲突**：检查 `.claude/skills/<skill-name>/` 目录是否已存在
  - 若已存在，在 Step 3 计划中标注冲突，询问用户：覆盖现有文件 / 输入新名称 / 取消
  - 等待用户明确选择后再继续

5. **展示改动计划**（类别 E 专属模板）：

  ```
  ## 我将改动

  ### 1. 新建 `.claude/skills/<skill-name>/SKILL.md`
  skill 名：<skill-name>
  （拉取内容前 20 行预览）
  ...

  ### 2. `.claude/docs/plugins.config.md`
  在 Skills 能力矩阵末尾新增条目（格式与现有 skill 条目一致）

  ## 你需要做
  - 如果该 skill 依赖某个 MCP，请用 `/add-skill 启用 <mcp-name>` 激活它
  - agent 挂载：文件写入完成后我会引导你选择要挂载的 agent

  确认以上改动？(y / n / 修改)
  ```

6. **用户确认后执行**：
  - 用 Write 工具创建 `.claude/skills/<skill-name>/SKILL.md`，内容与拉取内容完全一致，不修改任何字段
  - 用 Edit 工具在 `.claude/docs/plugins.config.md` 的 Skills 能力矩阵末尾追加新 skill 条目

7. **选择挂载 agent**（安装完成后）：

  动态构建 agent 列表：
  - 读取 `.claude/commands/` 下所有 command 文件，提取每个 command 的 `description` 字段（frontmatter）作为流程简介
  - 在每个 command 文件中搜索 `@agent-name` 引用模式，提取该 command 调用了哪些 agent、以及对应的 Phase 编号和阶段名称
  - 读取每个 `.claude/agents/<name>.md` 的 frontmatter，提取已有的 `skills` 列表
  - 将同一个 agent 出现在多个 command 中的情况归入"跨流程"分组
  - 按 command 分组展示，每个 command 作为一个分组标题，标题格式：`── /<command-name> · <description> ──`

  展示格式（示例，实际内容动态生成）：

  ```
  已安装 skill: <skill-name>

  请选择要挂载的 agent（可多选，也可跳过）：

  ── /dev · 功能开发流程 ──────────────────────────────
  ☐ analyst P1 · 需求分析 当前 skills: [read-requirement, search-codebase]
  ☐ architect P2 · 架构设计 当前 skills: 无
  ☐ implementer-fe P3 · 前端实现 当前 skills: [search-codebase]
  ☐ implementer-be P3 · 后端实现 当前 skills: [search-codebase]

  ── /fix · Bug 修复流程 ──────────────────────────────
  ☐ bug-analyst P1 · Bug 分析 当前 skills: [fetch-error-context]
  ☐ debugger P2 · 根因诊断 当前 skills: [fetch-error-context]

  ── 跨流程 (/dev P4 · /fix P6 · /review) ────────────
  ☐ reviewer 当前 skills: 无

  ── /flow-debug · Flow 复盘分析 ─────────────────────
  ☐ flow-debugger 当前 skills: 无

  输入序号（如 1 3），或直接回车跳过：
  ```

  - 向用户展示上述分组列表，等待用户输入序号（如 `1 3`）或直接回车跳过
  - 用户选择后，对每个选中的 agent，编辑其 `.claude/agents/<name>.md` frontmatter：
  - 若已有 `skills:` 列表，将新 skill 名追加到列表中
  - 若无 `skills:` 字段，新增 `skills: [<skill-name>]`
  - 用户跳过则不改任何 agent 文件

8. **展示安装摘要**：
  - skill 名称和安装路径
  - skill 文件中 `description` 字段的内容（如有）
  - 已挂载到的 agent 列表（如有选择）

#### 错误处理

| 情况 | 处理方式 |
|------|---------|
| 网络不可达 / 超时 | 展示错误信息，建议检查网络连接和 URL |
| HTTP 404 | 提示"链接不存在，请检查 URL 是否正确" |
| HTTP 401 / 403 | 提示"无法拉取需要认证的链接，请将文件内容直接粘贴给我，我来帮你安装" |
| 返回 HTML 内容 | 提示"这是页面链接而非文件内容链接"，展示推断出的 raw URL，询问是否用该地址重试 |
| 返回空内容 | 提示"链接内容为空，请检查 URL" |
| 内容不是 Markdown 格式 | 警告"内容不是 Markdown 格式，可能不是有效的 skill 文件"，询问用户是否仍要继续 |
| frontmatter 缺 `name` 字段 | 从 URL 路径推断名称，在计划中展示并由用户确认 |
| 同名 skill 已存在 | 在计划中标注冲突，询问：覆盖 / 重命名 / 取消 |

## Rules

遵守 `.claude/docs/framework-rules.md` 的全部约定。重点：

- 绝不自动 commit、不 force push
- 遵守 `.claude/docs/output-style.md` 的输出风格（少说废话、合并预检、不要自述）
- 不修改用户确认范围外的文件

本命令特有规则：

- 绝不编造 MCP 包名。包名不确定时，明说"我不确定 @xxx/yyy 是否存在，请你确认或提供官方文档"
- 绝不覆盖用户已有配置。`.mcp.json` 中同名 key 存在时，先问用户是覆盖还是保留
- 绝不在未确认时修改文件。Step 3 的确认是必需的
- 绝不硬编码凭证。敏感信息必须用环境变量引用（`${ENV_VAR}`）
- 所有改动对用户透明：改动前说明计划，改动后展示 diff 概要
- 意图不明时直接问，不要猜
- 改动 `.mcp.json` 后必须验证 JSON 语法有效
