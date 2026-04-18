---
description: Auto-generate CLAUDE.md by scanning the Vue3 + egg.js project structure, detecting conventions, and asking minimal clarifying questions.
---

You are going to generate a comprehensive `CLAUDE.md` for this Vue3 + egg.js project.

## Workflow

### Step 1: Scan the project

Use Glob + Read to detect:

**项目结构**
- 确认是否 `client/` + `server/` 双目录结构
- 前端目录结构（pages/components/composables/services/...）
- Node 层目录结构（controller/service/model/proto/...）

**前端配置** (`client/package.json`)
- Vue 版本
- TypeScript 版本
- 构建工具（Vite / Webpack）
- UI 库（element-plus / ant-design-vue / 自研）
- 状态管理（Pinia / Vuex）
- 路由（vue-router）
- i18n 工具（vue-i18n）
- 测试工具（vitest）
- Lint 工具

**Node 层配置** (`server/package.json`, `server/config/`)
- egg.js 版本
- TypeScript 配置
- 使用的插件
- srpc 客户端库
- 日志库、监控库

**srpc & proto**
- 列出 `server/app/proto/` 下的 proto 文件
- 识别主要的 srpc 服务

**命令**
- 读 `package.json` 的 scripts，识别：启动、构建、测试、lint、typecheck 命令

**约定**
- 扫描 5-10 个代表性文件，识别命名约定、错误处理模式、接口调用方式等

### Step 2: Ask minimal clarifying questions

Only ask things that **cannot be inferred from scanning**:
- 业务领域是什么？
- 是否有特殊的代码评审重点？
- 是否有敏感的"别碰"模块？
- 是否有特殊的发布/部署流程约束？

一次最多问 3 个问题。

### Step 3: Generate CLAUDE.md

Write to `CLAUDE.md` at project root using this template:

```markdown
# 项目上下文

## 业务领域
<从用户回答获取>

## 技术栈

### 前端 (client/)
- Vue <version> + TypeScript
- 构建工具：<detected>
- UI 库：<detected>
- 状态管理：<detected>
- 路由：<detected>
- 国际化：<detected>
- 测试：<detected>

### Node 层 (server/)
- egg.js <version> + TypeScript
- srpc 客户端：<detected>
- 日志：<detected>
- 监控：<detected>

### 渲染方式
前端页面通过 Node 层路由渲染（非独立 SPA）。

## 项目结构

### client/
<扫描到的目录树，带简要说明>

### server/
<扫描到的目录树，带简要说明>

## 常用命令
- **启动（前后端）**: `<detected>`
- **前端构建**: `<detected>`
- **Node 层测试**: `<detected>`
- **Lint**: `<detected>`
- **Typecheck**: `<detected>`
- **单元测试**: `<detected>`

## srpc 服务
识别到的 proto 文件：
- `<file>` — <purpose, inferred from content>

## 团队代码规范（强制遵守）

### 必须项
- 文件用 UTF-8 无 BOM、\n 换行
- 单文件 ≤ 2000 行（Vue 组件 ≤ 800）
- 单函数 ≤ 50 行，参数 ≤ 5 个
- 4 空格缩进，单引号，分号结尾
- 大括号悬挂式、必须包裹
- 禁止魔法数字
- 异常类以 Error 结尾
- 箭头函数（除 this 场景）

### 前端必须项
- 所有接口调用 .catch() + 异常日志上报
- 所有用户可见文案走 i18n
- 频繁操作加防抖/节流
- 接口超时显式设置
- 不稳定数据必须参数校验
- 接口返回数据必须兜底 + 上报
- 用 composables，不用 EventBus

### Node 层必须项
- 接口响应格式：`{ code: int, message: string, data }`
- code < 0（非业务）/ = 0（正常）/ > 0（业务异常）
- 应返回数组时无数据返 []
- 每个新接口需 proto
- 每个接口需请求量/成功量/失败量上报
- 日志不含隐私信息
- Controller 间不互调
- 外部调用超时 ≤ 1s，内部 ≤ 500ms
- 重试 ≤ 3 次且幂等

## 代码分层

### 前端
- `src/pages/<menu>/views/` — 展示页面
- `src/pages/<menu>/components/` — 页面内组件
- `src/pages/<menu>/composables/` — 页面内组合式函数
- `src/pages/<menu>/services/` — 页面内接口
- `src/pages/<menu>/constants/` — 页面内常量
- `src/pages/<menu>/store/` — 页面内状态
- `src/components/` — 项目级公共组件
- `src/composables/` — 项目级组合式函数
- `src/services/` — 项目级公共接口
- `src/utils/` — 项目级工具

### Node 层
- `controller/` — 参数校验 + 转发（**不能互相调用**）
- `service/` — 业务逻辑
- `model/` — 数据访问
- `middleware/` — 中间件
- `extend/` — 依赖 ctx 的方法
- `utils/` — 纯逻辑工具
- `proto/` — srpc 接口描述
- `constants/` — 业务常量
- `config/` — 启动配置

类名**不带分层后缀**（Error 类除外）。

## Git Commit 规范

### 格式
```
<type>(<scope>): <subject>
```

### type
- `feat` / `fix` / `docs` / `style` / `refactor` / `perf` / `test` / `chore` / `revert`

### 示例
```
fix(model): creatAt 字段缺失
feat(controller): 用户查询接口开发
refactor(composable): 抽离表单校验逻辑
```

### 规则
- subject ≤ 50 字符
- 中文描述优先
- 结尾不加标点

### 分支
- 功能：`feature/<特性名>`
- 修复：`hotfix/<问题名>`

## 特殊约定
<从用户回答填入>

## 不要碰的模块
<从用户回答填入>

## 开发环境
- Node ≥ 22.16
- Vue ≥ 3.5
- 推荐 pnpm
```

### Step 4: Report

告诉用户：
- CLAUDE.md 生成位置
- 哪些信息是扫描得到的
- 哪些信息需要手工补充
- 建议 review 后提交到 git

## Rules

- **Do NOT invent information** —— 无法检测且用户没回答的，标记 `<待补充>`
- 扫描要全面但不要读取测试数据或构建产物
- 如果 CLAUDE.md 已存在，先备份为 `CLAUDE.md.bak` 再覆盖，并告知用户
