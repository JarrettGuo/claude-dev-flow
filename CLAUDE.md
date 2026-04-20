# 项目上下文

## 业务领域
AI/Developer Tools — Claude Code 开发流程框架，规范多 agent 协作开发。

## 项目类型
- 类型：library
- 说明：本项目是 Claude Code CLI 的流程框架，不是 Web 应用。无前端/后端代码，纯配置和文档。

## 技术栈

### 核心
- 运行时：Node.js >= 22
- 协议：MCP（Model Context Protocol）
- 语言：JavaScript（框架配置和文档均为 .md / .json / .sh）

### 框架结构
| 目录 | 用途 |
|------|------|
| `.claude/commands/` | slash command 实现（dev / fix / review / commit 等，共 9 个） |
| `.claude/agents/` | 多 agent 协作角色定义（共 8 个） |
| `.claude/skills/` | 可复用能力单元（共 8 个） |
| `.claude/docs/` | 框架规范文档 |
| `.claude/hooks/` | Claude Code hooks（flow-log.sh） |
| `.claude/settings.json` | Claude Code 项目级配置 |
| `.claude/mcp.json` | MCP 服务器和 agent 角色定义 |
| `.claude/.version` | 框架版本号 |

### 依赖管理
- 工具：npm / pnpm / yarn（均可用）
- 锁文件：无（纯配置文件项目，无 npm 依赖）

## 项目结构

```
claude-dev-flow/
├── .claude/               # 框架核心配置
│   ├── agents/            # agent 定义
│   │   ├── analyst.md     # 需求分析
│   │   ├── architect.md   # 架构设计
│   │   ├── bug-analyst.md # Bug 分析
│   │   ├── debugger.md    # 调试
│   │   ├── flow-debugger.md # Flow 复盘
│   │   ├── implementer-be.md # 后端实现
│   │   ├── implementer-fe.md # 前端实现
│   │   └── reviewer.md    # 代码审查
│   ├── commands/          # slash command 实现
│   │   ├── dev.md         # /dev 功能开发流程
│   │   ├── fix.md        # /fix Bug 修复流程
│   │   ├── review.md      # /review 审查
│   │   ├── commit.md      # /commit 提交
│   │   ├── flow-debug.md  # /flow-debug Flow 复盘
│   │   ├── upgrade.md      # /upgrade 升级
│   │   ├── add-skill.md   # /add-skill 添加技能
│   │   ├── remove-skill.md # /remove-skill 移除技能
│   │   └── init-claude-md.md # /init-claude-md 初始化
│   ├── docs/              # 框架规范文档
│   │   ├── framework-rules.md # 框架规则
│   │   ├── output-style.md    # 输出风格
│   │   └── plugins.config.md  # 插件配置
│   ├── hooks/             # Claude Code hooks
│   │   └── flow-log.sh   # 自动记录 subagent 进出
│   ├── skills/            # skill 定义
│   │   ├── flow-log/         # 日志记录
│   │   ├── format-commit/    # commit 格式化
│   │   ├── progress-display/  # 进度显示
│   │   ├── read-requirement/  # 需求读取
│   │   ├── search-codebase/   # 代码搜索
│   │   ├── fetch-error-context/ # 错误上下文
│   │   ├── commit-split/      # commit 拆分
│   │   └── remove-skill/      # 技能移除
│   ├── settings.json      # Claude Code 配置
│   ├── mcp.json          # MCP 服务器和 agent 定义
│   └── .version          # 框架版本
├── .dev-flow/            # /dev 和 /fix 运行记录
│   ├── specs/            # 功能开发记录
│   └── fixes/            # Bug 修复记录
├── examples/              # 示例文件
├── README.md             # 项目说明
└── CLAUDE.md             # 本文档
```

## 代码规范

### 通用规范（跨栈强制）
- 文件 UTF-8 无 BOM、\n 换行
- 命名：有意义的英文 + 数字 + 下划线
- 变量驼峰、常量 UPPER_SNAKE_CASE、布尔值 is/can/has/should 开头
- CRUD 动词前缀：add/del/update/get/getXxxList/count
- 函数以动词命名
- 异常类以 Error 结尾
- 禁止魔法数字
- 单函数 ≤ 50 行，参数 ≤ 5 个
- if 嵌套 ≤ 4 层，for ≤ 3 层

### 框架特有规范
- Command 和 Agent 必须遵守 `.claude/docs/framework-rules.md`
- 终端输出必须遵守 `.claude/docs/output-style.md`
- 所有技术栈假设从 `CLAUDE.md` 读取，不得硬编码
- FLOW.log 默认只写文件不输出到终端；设置 `FLOW_LOG_STDERR=1` 可开启终端输出

## Git 规范

### Commit Message 格式
```
<type>(<scope>): <subject>
```

### type
feat / fix / docs / style / refactor / perf / test / chore / revert

### scope 候选
| scope | 适用场景 |
|-------|---------|
| command | slash command 实现 |
| agent | agent 定义 |
| skill | 能力单元 |
| docs | 文档 |
| core | 核心配置 |

### 规则
- subject ≤ 50 字符
- 中文描述优先
- 结尾不加标点

### 示例
```
feat(command): 新增 /init-claude-md 命令
fix(skill): 修复 flow-log 在某些 edge case 下丢失条目
docs(docs): 补充 framework-rules.md 的栈外执行约束
```

### 分支命名
- 功能：feature/<特性名>
- 修复：hotfix/<问题名>

### 强制规则
- **绝不自动 commit**
- **绝不 force push**
- merge 必须 `--no-ff`

## 特殊约定

### /dev 和 /fix 流程
- 全程写入 `.dev-flow/specs/<feature>/FLOW.log` 或 `.dev-flow/fixes/<bug>/FLOW.log`
- 每个阶段有确认门，需用户显式确认后才继续
- 只给 commit 建议，不自动 commit
- `.dev-flow/.current-flow` 文件标记当前 flow，流程结束后删除

### MCP 配置
- MCP 服务器定义在 `.claude/mcp.json`
- Agent 角色定义在 `.claude/mcp.json` 的 agents 字段
- 添加新 MCP 用 `/add-skill`，不要手动修改 mcp.json

### 日志记录规范
- 默认 `>> "$LOG"` 只写文件
- `FLOW_LOG_STDERR=1` 环境变量开启终端输出
- 所有 agent 和 command 必须遵守 `flow-log` skill 的写入模式

## 不要碰的模块
- `.dev-flow/` — 历史运行记录
- `.claude/agent-memory-local/` — agent 跨会话记忆
- `.claude/settings.local.json` — 用户本地配置

## 开发环境
- Node: >= 22
- 推荐包管理器：pnpm（也可使用 npm 或 yarn）
