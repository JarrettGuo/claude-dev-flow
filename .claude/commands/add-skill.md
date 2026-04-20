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

先判断是哪类，告诉用户你的理解，让他们确认。

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

### Step 3: 展示改动计划

在真正改文件前，用这个格式告诉用户：

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
