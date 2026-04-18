# 插件清单（Plugins Config）

> 项目当前**启用**和**可用**的 MCP 插件清单。打开这个文件就能知道：框架挂了哪些能力、哪些还没启用、怎么启用。

最后更新：项目初始化

---

## 当前状态概览

| 插件 | 状态 | 增强的 Skill | 凭证要求 |
|------|------|-------------|---------|
| feishu | ⚪ 未启用 | `read-requirement` | FEISHU_APP_ID, FEISHU_APP_SECRET |
| gitlab | ⚪ 未启用 | `read-requirement`、`search-codebase`、`fetch-error-context` | GITLAB_TOKEN, GITLAB_API_URL |

**状态图例**：✅ 已启用 / ⚪ 未启用

---

## Skills 能力矩阵

### `read-requirement` — 读取需求文档

| 优先级 | 源 | 所需 MCP | 状态 |
|-------|---|---------|------|
| 1 | 飞书文档链接 | feishu | ⚪ |
| 2 | GitLab issue / MR / wiki | gitlab | ⚪ |
| 3 | 其他 https URL | —（WebFetch 原生） | ✅ |
| 4 | 本地 md/txt/pdf | —（Read 原生） | ✅ |
| 5 | inline 文本 | — | ✅ |

**结论**：即使一个 MCP 都不装，也能处理本地文件和 inline 文本。

### `search-codebase` — 代码库搜索

| 优先级 | 实现 | 所需 MCP | 状态 |
|-------|------|---------|------|
| 1 | GitLab 语义搜索（如部署了） | gitlab | ⚪ |
| 2 | 原生 Grep + Glob | — | ✅ |

### `fetch-error-context` — 获取错误上下文

| 优先级 | 源 | 所需 MCP | 状态 |
|-------|---|---------|------|
| 1 | GitLab issue 链接 | gitlab | ⚪ |
| 2 | git log + grep 降级 | — | ✅ |

### `format-commit` — 生成 commit message

| 优先级 | 实现 | 所需 MCP | 状态 |
|-------|------|---------|------|
| 1 | 内置（基于 git diff） | — | ✅ |

---

## 启用一个插件

完整步骤见 [`add-plugin-guide.md`](./add-plugin-guide.md)。

**最快的方式：让 Claude 帮你做**

```
> /add-skill 我想启用飞书文档读取
```

Claude 会引导你完成配置。

**手动步骤**：

1. 编辑 `.mcp.json`，去掉 `$example_feishu_DISABLED` 的前缀和后缀，改成 `feishu`，删除 `$note` 字段
2. 设环境变量 `FEISHU_APP_ID` 和 `FEISHU_APP_SECRET`
3. 更新对应 skill 路由表的状态（⚪ → ✅）
4. 更新本文档的状态概览表
5. 重启 Claude Code session
6. 测试一条真实请求
7. 提交改动

---

## 停用一个插件

**最快的方式**：

```
> /remove-skill 停用飞书
```

**手动步骤**：

1. 编辑 `.mcp.json`，把名字改回 `$example_feishu_DISABLED`，加回 `$note`
2. 更新对应 skill 路由表（✅ → ⚪）
3. 更新本文档的状态概览表
4. 重启 Claude Code session

---

## 个人级 MCP（不提交）

如果某个 MCP 只给自己用，配置在用户级：

```
~/.claude/settings.json
```

不要写进项目的 `.mcp.json`。

---

## 变更日志

> 每次启用/停用 MCP 在这里加一行，方便追溯

- `YYYY-MM-DD` — 初始化，所有 MCP 默认未启用
