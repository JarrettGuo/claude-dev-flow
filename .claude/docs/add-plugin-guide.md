# 如何添加/删除插件

> 本框架的可插拔架构：三层解耦（agent → skill → MCP）。**推荐用 `/add-skill` 和 `/remove-skill` 自然语言管理**，手动改文件仅供理解原理和排错。

---

## 目录

1. [最快的方式：自然语言](#最快的方式自然语言)
2. [三层架构一览](#三层架构一览)
3. [手动三步流程](#手动三步流程)
4. [完整示例：启用飞书](#完整示例启用飞书)
5. [完整示例:启用 GitLab](#完整示例启用-gitlab)
6. [完整示例：添加 Confluence 支持](#完整示例添加-confluence-支持)
7. [常见错误与反模式](#常见错误与反模式)
8. [分发给组员](#分发给组员)

---

## 最快的方式：自然语言

**启用已有模板**（飞书/gitlab 默认就有模板）：

```
> /add-skill 启用飞书
> /add-skill 把 gitlab 打开
```

**添加新的 MCP**：

```
> /add-skill 接入 Confluence
> /add-skill 加一个 Sentry 错误监控
```

**给现有 skill 加路由**：

```
> /add-skill 让 read-requirement 也支持企业微信文档
> /add-skill fetch-error-context 增加 Datadog 支持
```

**新建一个全新 skill**：

```
> /add-skill 加一个能执行数据库查询的 skill
> /add-skill 做一个自动生成 API 文档的能力
```

**停用/删除**：

```
> /remove-skill 停用飞书
> /remove-skill 删除 fetch-error-context
> /remove-skill read-requirement 不要支持 gitlab 了
```

---

## 三层架构一览

```
┌──────────────────────────────────────────────┐
│ Agent（analyst / debugger / ...）           │
│ 声明需要什么 skill，不关心具体实现          │
└──────────────────────────────────────────────┘
                      ↑
┌──────────────────────────────────────────────┐
│ Skill（read-requirement / ...）             │
│ 定义统一接口 + 路由表 + 降级逻辑            │
└──────────────────────────────────────────────┘
                      ↑
┌──────────────────────────────────────────────┐
│ MCP Server（feishu / gitlab / ...）         │
│ 通过 .mcp.json 配置                          │
└──────────────────────────────────────────────┘
```

**设计铁律**：

- Agent 不直接写"如果是飞书就 xxx" —— 判断在 skill 里
- Skill 永远声明降级路径 —— 没 MCP 也不崩
- MCP 配置永远在 `.mcp.json` —— 不写进 agent frontmatter

---

## 手动三步流程

如果你不想用 `/add-skill`（比如想理解原理或调试），手动步骤如下：

### Step 1: 配置 `.mcp.json`

```json
{
  "mcpServers": {
    "feishu": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@larksuite/mcp-server"],
      "env": {
        "FEISHU_APP_ID": "${FEISHU_APP_ID}",
        "FEISHU_APP_SECRET": "${FEISHU_APP_SECRET}"
      }
    }
  }
}
```

敏感信息必须用 `${ENV_VAR}` 引用，**绝不硬编码**。

### Step 2: 更新对应 skill 的路由表

编辑 `.claude/skills/read-requirement/SKILL.md`，把状态从 ⚪ 改成 ✅：

```
| 1 | URL 匹配 `*.feishu.cn` | 调用 feishu MCP | `feishu` | ✅ 已启用 |
```

### Step 3: 同步 `plugins.config.md` 状态表

让组员打开就能看到当前启用了什么。

---

## 完整示例：启用飞书

**用 `/add-skill`**（推荐）：

```
> /add-skill 启用飞书
```

Claude 引导你：
- 确认 `.mcp.json` 里的模板
- 告诉你需要设哪些环境变量
- 自动改 `.mcp.json` / skill 路由 / `plugins.config.md`
- 展示变更 diff
- 提示重启 + 测试命令

**手动**：

1. 编辑 `.mcp.json`，把 `$example_feishu_DISABLED` 改成 `feishu`，删除 `$note`
2. 设环境变量：
   ```
   export FEISHU_APP_ID="cli_xxx"
   export FEISHU_APP_SECRET="yyy"
   ```
3. 编辑 `.claude/skills/read-requirement/SKILL.md`，路由表飞书那行状态改 ✅
4. 编辑 `.claude/docs/plugins.config.md`，状态概览表更新
5. 重启 Claude Code session
6. 测试：`/dev https://xxx.feishu.cn/docx/abc123`

---

## 完整示例：启用 GitLab

GitLab MCP 会同时增强三个 skill：`read-requirement`、`search-codebase`、`fetch-error-context`。

**用 `/add-skill`**：

```
> /add-skill 启用 gitlab
```

Claude 会自动把三个 skill 的相关路由行都改为 ✅。

**手动需要改的文件**（更多）：

1. `.mcp.json` — 启用 gitlab 配置
2. 设环境变量 `GITLAB_TOKEN` 和 `GITLAB_API_URL`
3. `.claude/skills/read-requirement/SKILL.md` — 路由表第 2 行
4. `.claude/skills/search-codebase/SKILL.md` — 路由表第 1 行
5. `.claude/skills/fetch-error-context/SKILL.md` — 路由表第 1 行
6. `.claude/docs/plugins.config.md` — 状态表

这就是为什么推荐用 `/add-skill` —— 手动改容易漏。

---

## 完整示例：添加 Confluence 支持

Confluence 在模板里没有，这是"添加新 MCP"场景。

**用 `/add-skill`**：

```
> /add-skill 接入 Confluence，用来读 wiki 页面作为需求
```

Claude 会问你：
- Confluence 的 URL
- API token 用哪个环境变量
- 增强哪个 skill（通常是 `read-requirement`）

然后自动完成配置。

**手动**：

1. 在 `.mcp.json` 加新条目（启用状态）：
   ```json
   "confluence": {
     "type": "stdio",
     "command": "npx",
     "args": ["-y", "@atlassian/confluence-mcp-server"],
     "env": {
       "CONFLUENCE_URL": "${CONFLUENCE_URL}",
       "CONFLUENCE_EMAIL": "${CONFLUENCE_EMAIL}",
       "CONFLUENCE_API_TOKEN": "${CONFLUENCE_API_TOKEN}"
     }
   }
   ```
2. 在 `read-requirement` 路由表加新行：
   ```
   | 2 | URL 匹配 `*.atlassian.net/wiki/*` | 调用 confluence MCP | `confluence` | ✅ |
   ```
3. 重新编号下面的优先级
4. 更新 `plugins.config.md`
5. 设环境变量，重启，测试

---

## 常见错误与反模式

### ❌ 反模式 1：在 agent prompt 里写源判断

```
# analyst.md ← 错的
如果用户给飞书链接，调用 feishu_get_document...
```

**正确做法**：agent 只调 `read-requirement` skill，判断在 skill 里。

### ❌ 反模式 2：一个源一个 skill

`read-requirement-feishu.md` + `read-requirement-gitlab.md` + ...

**正确做法**：一个 `read-requirement` skill，路由表列所有源。

### ❌ 反模式 3：硬编码凭证

```
env:
  FEISHU_APP_SECRET: "cli_actual_secret_xxxxx" ← 泄露
```

**正确做法**：`${ENV_VAR}` + 环境变量。

### ❌ 反模式 4：skill 没有降级路径

没装 MCP 整个 skill 崩。

**正确做法**：skill 总有"无 MCP 时怎么办"的兜底，明确告知用户。

### ❌ 反模式 5：改了 `.mcp.json` 忘了更新 skill 路由

MCP 装了但没人调用，或者被当成未启用提示用户粘贴内容。

**预防措施**：
- 用 `/add-skill` 避免漏步骤
- 或手动时按 [三步流程](#手动三步流程) 严格走

---

## 分发给组员

### 场景 1：你本地加了新 MCP，想让全组用

1. 把改动（`.mcp.json` + skill + `plugins.config.md`）提交到 git
2. 环境变量名和获取方式**写进项目 README**（不要贴凭证本身）
3. 通知组员：
   - `git pull`
   - 设新环境变量
   - 重启 Claude Code session

### 场景 2：某个 MCP 是个人用（比如你的个人 Jira）

配置在用户级：`~/.claude/settings.json`，不提交到项目。

### 场景 3：想让多个项目共享同一套插件配置

考虑做成 **Claude Code Plugin**（独立仓库）：

```
company-dev-plugin/
├── plugin.json
├── .mcp.json
└── agents/ skills/ commands/（可选）
```

组员 `/plugin install company-dev-plugin@your-org/repo` 一键安装。

---

## 检查清单

加插件前：
- [ ] 要的能力已有对应 skill 吗？有 → 只改路由表 / 用 `/add-skill`
- [ ] 新 skill 有完整路由表和降级逻辑吗？
- [ ] `.mcp.json` 没硬编码凭证吗？
- [ ] 环境变量获取方式写在文档里了吗？
- [ ] 没 MCP 的组员运行框架还能工作吗？
- [ ] 测过"MCP 缺失时的降级路径"吗？

删插件前：
- [ ] 用 `/remove-skill` 还是手动删？
- [ ] 删除 skill 前检查过 agent 依赖吗？
- [ ] 降级后用户会看到什么？
- [ ] 清理了所有文档和 `plugins.config.md` 里的引用吗？

全部 ✅ 再合入主干。
