---
description: 通过扫描项目结构、检测技术栈和规范，自动生成 CLAUDE.md，只需最少的问题澄清。支持全栈/纯前端/纯后端项目，兼容任意框架。
---

You are going to generate a comprehensive `CLAUDE.md` for this project.

**重要原则**：
- **不要假设技术栈**。扫描代码库得出实际栈，而不是套用任何默认栈
- **不要假设目录结构**。前端目录叫什么、后端目录叫什么、是否 monorepo，都从扫描结果推断
- **尽量减少打扰用户**。能从代码库推断的都自己推断，只问扫不出来的问题

## Workflow

### Step 1: 识别项目类型

先判断是 `full-stack` / `frontend-only` / `backend-only` / `library` 的哪一种：

```bash
ls -la
```

**判断启发式**：

1. **扫顶层目录名**：
   - 常见前端目录名：`client/` `frontend/` `web/` `app/` `ui/` `apps/web/`
   - 常见后端目录名：`server/` `backend/` `api/` `service/` `node/` `apps/api/`
   - 如果上述都没有，只有 `src/`：可能是单层应用（前端 SPA、或后端服务、或库）

2. **扫 `package.json`**（如果只有一个）：
   - 有前端框架依赖 → frontend（或 full-stack 的前端部分）
   - 有后端框架依赖 → backend
   - 同时有 → full-stack（单 package.json 的混合项目）

3. **扫多个 `package.json`**（monorepo）：
   - 每个子目录分别判断

**结果**：明确记录下来，用作后续生成 CLAUDE.md 的"项目类型"字段。

### Step 2: 识别前端（如有）

如果 Step 1 判断有前端部分，在前端根目录扫描：

#### 框架识别

读 `package.json`，按以下优先级判断：

| 依赖关键字 | 框架 |
|-----------|------|
| `vue` | Vue（进一步看版本号：`^2` / `^3`） |
| `react` | React |
| `@angular/core` | Angular |
| `svelte` | Svelte |
| `solid-js` | Solid |
| `next` | Next.js（React 生态） |
| `nuxt` | Nuxt（Vue 生态） |
| `@remix-run/react` | Remix |

**如果都没匹配到**：问用户"前端框架是什么？"

#### 语言

- 有 `typescript` 依赖或 `tsconfig.json` → TypeScript
- 否则 → JavaScript

#### 构建/开发工具

查 `devDependencies` 和配置文件：

| 线索 | 工具 |
|------|------|
| `vite` 依赖 或 `vite.config.*` | Vite |
| `webpack` 依赖 或 `webpack.config.*` | Webpack |
| `rollup` | Rollup |
| `esbuild` | esbuild |
| `parcel` | Parcel |
| `turbopack` | Turbopack |

#### UI 库

查依赖：`element-plus` / `ant-design` / `antd` / `@mui/material` / `chakra-ui` / `naive-ui` / `vuetify` / `tailwindcss` 等。列出找到的主要 UI 相关库。

#### 状态管理

查依赖：`pinia` / `vuex` / `redux` / `@reduxjs/toolkit` / `zustand` / `mobx` / `jotai` / `recoil` 等。

#### 路由

`vue-router` / `react-router` / `react-router-dom` / `@angular/router` / 或框架内置（Next/Nuxt/Remix）。

#### 国际化

`vue-i18n` / `react-i18next` / `i18next` / `@formatjs/*` 等。如都没找到，记录"项目未显式使用 i18n"。

#### 测试工具

`vitest` / `jest` / `mocha` / `playwright` / `cypress` / `@testing-library/*` 等。

#### Lint / 格式化

`eslint` / `prettier` / `biome` / `stylelint` 及对应配置文件。

### Step 3: 识别后端（如有）

如果 Step 1 判断有后端部分，在后端根目录扫描：

#### 框架识别

读 `package.json`：

| 依赖关键字 | 框架 |
|-----------|------|
| `egg` | egg.js |
| `express` | Express |
| `@nestjs/core` | NestJS |
| `koa` | Koa |
| `fastify` | Fastify |
| `hapi` / `@hapi/hapi` | Hapi |
| `hono` | Hono |

**如果都没匹配到**：问用户"后端框架是什么？"

#### 语言

同前端逻辑。

#### 接口/通信

查：
- `server/app/proto/`、`proto/`、`protos/` 等目录 → srpc / gRPC 风格
- `.proto` 文件存在 → 同上
- `openapi.yaml` / `swagger.json` / `openapi.json` → OpenAPI
- `schema.graphql` / `@apollo/server` / `graphql` 依赖 → GraphQL
- 都没找到 → 纯 RESTful HTTP

#### 数据库/ORM

查依赖：`mysql2` / `pg` / `mongodb` / `redis` / `sequelize` / `typeorm` / `prisma` / `mongoose` 等。

#### 测试工具

同前端逻辑。

### Step 4: 识别包管理器

**强锁文件优先**：
- `pnpm-lock.yaml` → pnpm
- `yarn.lock` → yarn
- `package-lock.json` → npm
- `bun.lockb` → bun

**都存在**：问用户（很少见）。**都不存在**：默认 npm。

### Step 5: 识别常用命令

读 `package.json` 的 `scripts` 字段，识别并记录：

- **启动/开发**：通常是 `dev` / `start` / `serve`
- **构建**：通常是 `build`
- **测试**：通常是 `test` / `test:unit`
- **Lint**：通常是 `lint`
- **Typecheck**：通常是 `typecheck` / `type-check` / `tsc --noEmit`

**全栈项目**：前端和后端的命令分别记录。

### Step 6: 扫几个代表性文件推断代码规范

读取 5-10 个代表性源文件（优先业务核心文件，避免 `node_modules`、测试数据、自动生成的文件），观察：

- **命名习惯**：驼峰/下划线/kebab-case 的使用
- **接口调用模式**：是否统一走 services 层、响应体格式、错误处理方式
- **组件/模块结构**：文件大小、职责划分
- **i18n 使用**：是否所有 UI 文本走 i18n
- **注释习惯**：是否有 JSDoc、是否有复杂逻辑注释

**这些推断仅用于"提示用户确认"**，不要直接写死进 CLAUDE.md。把推断结果在 Step 7 打印给用户，让他们确认或修改。

### Step 7: 问最少必要的问题

**只问扫不出来的内容**。一次最多 3 个问题：

1. **业务领域**是什么？一句话描述（用于让未来的 AI 理解上下文）
2. 有哪些**不要碰的模块**？（比如正在重构、或其他团队维护）
3. 是否有**特殊的发布/部署流程**约束？（比如特定环境要跑特定命令）

**已经扫到的内容不要重复问**。例如：前端用 Vue 已从 `package.json` 看出来了，就不要再问"你们用什么前端框架？"。

### Step 8: 生成 CLAUDE.md

**如果 `CLAUDE.md` 已存在**：先 `cp CLAUDE.md CLAUDE.md.bak` 备份，告知用户。

然后写入新的 `CLAUDE.md`，**按项目实际情况**填入以下模板。**未扫到且用户未提供的字段标记为 `<待补充>`，不要编造**。

```markdown
# 项目上下文

## 业务领域
<Step 7 获取>

## 项目类型
- 类型：<full-stack / frontend-only / backend-only / library>
- 前端根目录：<如 client/ / frontend/ / src/ / "N/A">
- 后端根目录：<如 server/ / backend/ / api/ / "N/A">
- 是否 monorepo：<是/否>

## 技术栈

### 前端（如适用）
- 框架：<Vue 3.x / React 18 / Angular 17 / ...>
- 语言：<TypeScript / JavaScript>
- 构建工具：<Vite / Webpack / ...>
- UI 库：<element-plus / antd / tailwindcss / ...>
- 状态管理：<Pinia / Redux / ...>
- 路由：<vue-router / react-router / ...>
- 国际化：<vue-i18n / i18next / 未使用>
- 测试：<vitest / jest / ...>
- Lint：<eslint / prettier>

### 后端（如适用）
- 框架：<egg.js 3.x / Express / NestJS / ...>
- 语言：<TypeScript / JavaScript>
- 接口通信：<srpc / OpenAPI / GraphQL / RESTful>
- 接口定义文件位置：<如 server/app/proto/ / openapi.yaml / "无">
- 数据库/ORM：<mysql2 / prisma / typeorm / mongoose / ...>
- 测试：<vitest / jest / ...>
- Lint：<eslint>

### 渲染方式（仅 full-stack 项目）
<如"前端页面通过 Node 层路由渲染（非独立 SPA）" / "独立 SPA，Node 层仅提供 API" / "SSR 模式" / 等>

## 包管理
- 工具：<pnpm / npm / yarn / bun>
- 锁文件：<pnpm-lock.yaml / ...>

## 项目结构

### 前端目录（如适用）
<扫描到的实际目录树，带简要说明。典型可能包括：
- views/ — 页面
- components/ — 组件
- composables/ 或 hooks/ — 组合式函数 / hooks
- services/ 或 api/ — 接口调用
- store/ — 状态
- utils/ — 工具
按实际扫描填，不要套 Vue 的固定模板>

### 后端目录（如适用）
<扫描到的实际目录树。典型可能包括：
- controller/ 或 routes/ 或 handlers/ — 路由/控制层
- service/ — 业务逻辑
- model/ 或 dao/ 或 repositories/ — 数据层
- middleware/ — 中间件
- proto/ 或 schemas/ — 接口定义（如适用）
- utils/ — 工具
- config/ — 配置
按实际扫描填>

## 常用命令
- **启动**：<实际的 npm/pnpm/yarn 命令>
- **构建**：<...>
- **测试**：<...>
- **Lint**：<...>
- **Typecheck**：<...>
（全栈项目请分别列出前端和后端的命令，或用 monorepo 的聚合命令）

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

### 前端规范（如适用）
<按扫描到的框架和团队习惯填写。示例字段（根据实际栈选择保留）：
- 框架特定范式（如 Vue 的 Composition API 偏好 / React 的 hooks 规则 / Angular 的服务注入）
- 组件大小约束（如 Vue SFC ≤ 800 行）
- 接口调用走 services/api 层
- 所有用户可见文案走 i18n（如项目使用 i18n）
- 频繁操作加防抖/节流
- 接口超时显式设置
- 不稳定数据必须参数校验
- 接口返回数据必须兜底 + 上报
>

### 后端规范（如适用）
<按扫描到的框架和团队习惯填写。示例字段：
- 接口响应格式（如 `{ code: int, message: string, data }`）
- code 值规范（如 <0 非业务 / =0 正常 / >0 业务异常）
- 每个新接口是否需要接口定义文件（proto / OpenAPI）
- 日志级别使用规范（Error / Warning / Info / Debug）
- 日志格式（msg / input / code）
- 隐私信息禁止记录清单（手机号、住址、金融数据等）
- 监控上报要求（请求量/成功量/失败量）
- 控制层互相调用规则
- 外部调用超时和重试
- 缓存 key 管理规则
>

### 其他强制项
<根据代码扫描和用户回答填入，例如：
- 是否强制 TypeScript
- 是否有提交前 lint/typecheck 钩子
- 是否有敏感文件禁改清单
>

## Git 规范

### Commit Message 格式
<type>(<scope>): <subject>

### type
feat / fix / docs / style / refactor / perf / test / chore / revert

### scope
基于本项目结构的候选：
<按扫描到的目录/分层列出，例如：
- 前端：view / component / composable / hook / service / store / router / util / const / 或业务模块名
- 后端：controller / route / service / model / middleware / proto / schema / config / util / const
按实际调整>

### 规则
- subject ≤ 50 字符
- 中文描述优先
- 结尾不加标点

### 示例
<按本项目的 scope 候选给 3-5 个示例>

### 分支命名
- 功能：feature/<特性名>
- 修复：hotfix/<问题名>
（或按团队已有规范调整）

## 特殊约定
<Step 7 用户回答填入>

## 不要碰的模块
<Step 7 用户回答填入>

## 开发环境
<从 package.json 的 engines 字段 或 .nvmrc 或 .node-version 读；扫不到则"<待补充>"
- Node: >= XX
- 推荐包管理器: pnpm / npm / yarn>
```

### Step 9: 报告

告诉用户：
- CLAUDE.md 生成位置（项目根目录）
- 哪些字段是扫描推断得出的（列出）
- 哪些字段来自用户回答（列出）
- 哪些字段标记为 `<待补充>`，需要人工补上（列出，并说明怎么补）
- 如有备份：告知 `CLAUDE.md.bak` 位置
- 建议：review 一遍后提交到 git，后续 agent 都会读这份文档

## Rules

- **不要假设任何默认技术栈**
- **不要编造未扫描到的信息**，标 `<待补充>` 就好
- **不要重复问用户能扫出来的信息**
- 扫描时跳过 `node_modules` / `dist` / `build` / `.git` / 测试数据 / 自动生成代码
- 如果 CLAUDE.md 已存在，先备份为 `CLAUDE.md.bak` 再覆盖，并告知用户
- 模板里的 `<...>` 是占位符，生成时必须替换成实际值或明确的 `<待补充>`
- **遇到扫不出来的关键字段**（如前端框架、后端框架）就直接问用户，不要硬猜
