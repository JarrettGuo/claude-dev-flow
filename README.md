# Claude Dev Flow

一个基于 Claude Code 的开发流程框架，用于规范化多 agent 协作开发。

## 项目简介

Claude Dev Flow 是一个轻量级的开发流程框架，旨在：
- 规范 Claude Code 的开发协作流程
- 提供可追溯、可审计的任务执行记录
- 支持多 agent 协同工作
- 保持与现有工具链的适配性

## 快速开始

详见 [INSTALL.md](./INSTALL.md)

## 项目结构

```
claude-dev-flow/
├── README.md           # 项目说明
├── INSTALL.md          # 安装指南
├── .mcp.json           # MCP 配置
├── examples/           # 示例文件
│   └── hello-world.md  # Hello World 示例
└── docs/               # 文档目录（待补充）
```

## 命令速查

框架提供 9 个 slash 命令，分为**开发流程**和**框架管理**两类。

### 开发流程命令

| 命令 | 用途 | 参数 | 产物位置 |
|-----|------|------|---------|
| `/dev` | 完整新功能开发流程 | 需求描述 / URL / 文件路径 | `.dev-flow/specs/<feature>/` |
| `/fix` | Bug 修复流程（含强制验证） | bug 描述 / 错误信息 / 工单链接 | `.dev-flow/fixes/<bug>/` |
| `/review` | 独立对抗性审查 | （可选）文件路径 | 终端输出 |
| `/commit` | 按规范生成 commit message | （可选）改动提示 | 终端输出 |
| `/flow-debug` | 复盘已完成的 /dev 或 /fix 流程，可选自动修复 | `<feature-name>` | `.dev-flow/.../DEBUG-REPORT.md` |

### 框架管理命令

| 命令 | 用途 |
|-----|------|
| `/init-claude-md` | 扫描项目自动生成 `CLAUDE.md` 项目上下文 |
| `/add-skill` | 用自然语言添加/启用能力（MCP 或 skill） |
| `/remove-skill` | 用自然语言停用/删除能力 |
| `/upgrade` | 从 GitHub 拉取最新框架，安全升级本项目 `.claude/`（保护本地改动） |

---

## 命令示例（一看就会用）

### `/dev` — 开发新功能

从简单到复杂，任意输入形式都支持。

**简单需求（inline 文本）**
```
/dev 登录页用户名输入框加最大长度 50 和错误提示
```

**带本地需求文档**
```
/dev docs/requirements/avatar-upload.md
```

**带飞书文档链接**（需先启用飞书 MCP，见 `/add-skill`）
```
/dev https://xxx.feishu.cn/docx/abc123
```

**带 GitLab issue**（需先启用 gitlab MCP）
```
/dev https://gitlab.company.com/team/repo/-/issues/42
```

执行后 Claude 会自动走 analyst → architect → implementer → reviewer → commit 建议，每个阶段有确认门。

---

### `/fix` — 修复 bug

**带错误堆栈**
```
/fix TypeError: Cannot read property 'id' of undefined at Profile.vue:142
```

**带用户反馈描述**
```
/fix 用户反馈登录后刷新头像不显示，偶发
```

**带 GitLab 工单链接**
```
/fix https://gitlab.company.com/team/repo/-/issues/128
```

`/fix` 与 `/dev` 的区别：默认走"最小改动 + 根因优先 + 强制回归测试"路径。

---

### `/review` — 独立代码审查

**无参数：审查当前未提交改动**
```
/review
```

**审查指定文件**
```
/review src/pages/profile/Main.vue
```

**审查多个文件**（一次一个命令）
```
/review server/app/controller/user.ts
```

输出对抗性 review 报告，只看不改。

---

### `/commit` — 生成规范 commit

**无参数：自动分析 staged/工作区改动**
```
/commit
```

**带改动提示（帮 Claude 更准确理解）**
```
/commit 这次主要是修了头像上传的 OOM bug
```

输出符合团队 `<type>(<scope>): <subject>` 规范的 commit 建议，前后端混改时自动建议拆分提交。**不自动执行 `git commit`**。

---

### `/init-claude-md` — 初始化项目上下文

**首次使用框架时跑（每个项目只跑一次）**
```
/init-claude-md
```

Claude 会：
1. 扫描 `package.json` 识别技术栈（Vue/React/Angular、egg/Express/NestJS/Koa 等）
2. 扫描目录结构识别前端/后端根目录
3. 识别包管理器（pnpm/npm/yarn/bun）
4. 读 `scripts` 识别常用命令
5. 问 1-3 个扫不出来的问题（业务领域、敏感模块等）
6. 生成 `CLAUDE.md`

生成后建议 review 一遍再提交到 git。

---

### `/add-skill` — 用自然语言添加能力

Claude 自动改 `.mcp.json` / skill 路由表 / `plugins.config.md`，不用自己记要改哪几个文件。

**启用已有 MCP 模板**
```
/add-skill 启用飞书
```
```
/add-skill 把 gitlab 打开
```

**添加新 MCP**（模板里没有的）
```
/add-skill 接入 Confluence 作为需求来源
```
```
/add-skill 加一个 Sentry 错误监控
```

**给现有 skill 加路由**
```
/add-skill 让 read-requirement 也支持 Notion 文档
```

**创建全新 skill**
```
/add-skill 加一个能查数据库的 skill
```
```
/add-skill 做一个自动生成 API 文档的能力
```

Claude 会展示改动计划让你确认，再执行。

---

### `/remove-skill` — 用自然语言移除能力

**停用 MCP**（默认做法，方便以后重启用）
```
/remove-skill 停用飞书
```
```
/remove-skill gitlab 暂时不用了
```

**删除整个 skill**
```
/remove-skill 删掉 fetch-error-context
```

**移除某条路由**
```
/remove-skill read-requirement 不要支持 gitlab 了
```

**清理 .mcp.json 不一致**
```
/remove-skill 帮我清理 .mcp.json 里孤立的配置
```

Claude 会展示删除/停用计划、列出降级影响，让你确认后再动手。

---

### `/flow-debug` — 复盘流程 + 一键修复

每次 `/dev` 和 `/fix` 都会在 `.dev-flow/specs/<name>/FLOW.log` 或 `.dev-flow/fixes/<name>/FLOW.log` 生成完整执行日志。出问题时用这个命令复盘。

**默认：分析 + 提修复方案 + 你确认后改代码**

```
/flow-debug avatar-upload
```

Claude 会：读 FLOW.log 和所有产物 → 找出问题 → 分类（🔴 可自动修 / 🟡 需人工判断 / 🔵 环境问题）→ 提修复方案给你确认 → 确认后改代码 + 跑测试

**只分析不修**（方便粘给 GPT 二次诊断）

```
/flow-debug avatar-upload 只分析不要修
```

产出 `.dev-flow/specs/avatar-upload/DEBUG-REPORT.md`，末尾带可直接粘给 ChatGPT 的完整 prompt。

**带具体指令**

```
/flow-debug password-reset 帮我修掉 review 提的 i18n 问题
```

Claude 聚焦处理你指定的问题。

**修复规则**：
- 只改 🔴 类问题（流程/环境问题永远不自动改）
- 最多 2 轮尝试（比 /dev 的 3 轮更保守）
- 失败自动 git checkout 回滚
- 永不自动 commit

---

### `/upgrade` — 升级框架到最新版

从 GitHub 拉取 `claude-dev-flow` 最新版，智能升级本项目的 `.claude/` 目录。**保护你的本地文件和对框架文件的修改**。

**默认：拉最新 + 展示预览 + 你确认 + 升级**

```
/upgrade
```

Claude 会：clone 远端 → 对比本地 `.claude/.version` → 把框架文件分成三类（🆕 新增 / ✅ 安全覆盖 / ⚠️ 你改过）→ 列出预览 → 你改过的文件**逐个问你**（覆盖 / 跳过 / 看 diff）→ 确认后升级 + 备份你的版本到 `.claude.backup-<时间戳>/`。

**只预览不执行**（先看看要改什么）

```
/upgrade --dry-run
```

打印完整升级计划、不动任何文件。适合在正式升级前评估影响范围。

**连 README 也一起同步**（默认不动 README，因为你可能改成项目自己的）

```
/upgrade --with-readme
```

**指定其他来源**（比如你 fork 了框架）

```
/upgrade --source https://github.com/YourOrg/claude-dev-flow
```

**受保护文件**（永远不动）：
- `CLAUDE.md` / `CLAUDE.md.bak`（你的项目上下文）
- `.mcp.json`（你启用的 MCP）
- `.dev-flow/`（历史运行记录）
- `.env` / `.env.*`
- `.claude/agent-memory-local/`（agent 跨会话记忆）
- 你自己新增的 agent / command / skill（框架仓库里没有的）

**冲突策略**：框架文件你改过就**停下来问你**，绝不静默覆盖。选择覆盖时会先备份整个 `.claude/` 到 `.claude.backup-YYYYMMDD-HHMMSS/`，想找回改动随时能翻。

---

## 典型工作流

**新人第一天**：
```
/init-claude-md # 生成项目上下文
/dev 跑一个小需求验证流程 # 试水
```

**日常开发**：
```
/dev <需求> # 走完整流程
# 或
/commit # 小改动手写完后让 Claude 生成规范 commit
```

**Bug 修复**：
```
/fix <bug 描述> # 走修复流程
```

**接入新工具**：
```
/add-skill <意图> # Claude 帮你搞定配置
```

**出问题复盘**：
```
/flow-debug <名字> # 读日志 + 分析 + 可选修复
```

**升级框架**：
```
/upgrade # 拉最新 + 交互式升级
/upgrade --dry-run # 只看不改
```

---

## 使用场景

- 单人开发项目的流程规范
- 多 agent 协作的任务编排
- 开发过程的审计与追溯
- 与 Claude Code 的集成实践

## 许可证

MIT
