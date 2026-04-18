---
name: format-commit
description: Generate a standards-compliant git commit message following the team's Angular-simplified convention. Used by /commit command and at the end of /dev and /fix flows.
---

# Format Commit

按团队规范生成 commit message。**不执行 commit**，只输出文案。

## 能力范围

**负责**：
- 根据 `git diff` 分析改动
- 按团队格式 `<type>(<scope>): <subject>` 输出
- 检测红旗（混杂改动、调试代码残留等）
- 在前后端都改时建议拆分提交

**不负责**：
- 执行 `git commit`（由用户自己跑）
- 推送代码（`git push` 由用户决定）

## 输入

- 可选：用户提供的改动提示（如 "主要是修头像上传的 bug"）
- 总是：通过 Bash 自取 `git status` 和 `git diff --staged`（若无暂存则 `git diff`）

## Team Convention

### 格式
```
<type>(<scope>): <subject>
```

### type（必须，只能用以下之一）
- `feat` — 新功能
- `fix` — 修复 bug
- `docs` — 仅修改文档
- `style` — 仅修改空格、格式、缩进，不改代码逻辑
- `refactor` — 重构，无新功能无 bug 修复
- `perf` — 性能/体验优化
- `test` — 测试用例
- `chore` — 构建流程、依赖库、工具
- `revert` — 回滚

### scope（可选）
影响范围。常见值：

前端：`view` / `component` / `composable` / `service` / `store` / `router` / `util` / `const`，或模块名
Node 层：`controller` / `service` / `model` / `middleware` / `router` / `proto` / `config` / `extend` / `util` / `const`

### subject（必须）
- ≤ 50 字符（**严格**）
- 中文描述优先
- 结尾**不加**句号或其他标点
- 动词开头

### 示例
```
fix(model): creatAt 字段缺失
feat(controller): 用户查询接口开发
refactor(composable): 抽离表单校验逻辑
perf(view): 列表渲染添加虚拟滚动
```

## 执行流程

1. **读 diff**：
   - 先 `git status`
   - 再 `git diff --staged`；若暂存区空，`git diff`
   - 若两者都空，告诉用户"无改动"并终止
2. **分析改动性质**：
   - 是新功能？bug 修复？重构？格式化？依赖更新？
   - 是单一类型还是混杂？
3. **推断 scope**：
   - 改动集中在 `client/` 还是 `server/`？
   - 集中在哪个分层？
   - 是否涉及单一业务模块？
4. **检测红旗**（见下）
5. **生成建议**：主推荐 + 1-2 个备选
6. **若前后端都改**：额外建议拆分提交

## 红旗检测

以下情况必须警告用户：

1. **混杂多类改动**（feat + fix + refactor 同时出现在一个 diff 里）
   → 建议：拆成多次提交
2. **暂存区与工作区不一致**
   → 若 staged 和 unstaged 都有，提示用户 `git add -p` 分块
3. **调试代码残留**：
   - `console.log(`、`console.debug(`、`debugger`、`// TODO: remove`、`// FIXME`
   → 建议清理后再提交
4. **注释掉的代码块**（多行 `//` 或 `/* */` 包住的代码）
   → 团队规范禁止遗留
5. **未使用的变量/import**（从 diff 表面可见的）
   → 团队规范禁止

## 输出格式

```
## 变更分析
<一两句话总结改了什么>

## 推荐 commit message

<type>(<scope>): <subject>

## 备选方案

1. <type>(<scope>): <subject-A>
2. <type>(<scope>): <subject-B>

## 提交命令

git commit -m "<type>(<scope>): <subject>"

## 如果涉及前后端两层（仅在此情况出现）

建议拆分：

# 1. 先提交 Node 层
git reset
git add server/
git commit -m "<be-type>(<be-scope>): <be-subject>"

# 2. 再提交前端
git add client/
git commit -m "<fe-type>(<fe-scope>): <fe-subject>"

## ⚠️ 注意事项（仅在检测到红旗时出现）
<警告列表>
```

## Rules

- **绝不编造改动** —— 只基于实际 diff
- **绝不输出超过 50 字符的 subject** —— 超了必须精简
- **绝不自动执行 `git commit`** —— 只输出命令
- **绝不在 subject 结尾加标点**
- **绝不混用 type** —— 一次 commit 一个主要意图
- **绝不拿分支名或年月加进 subject** —— 团队规范不要求这些

## 扩展此 Skill

这个 skill 目前完全基于内置工具（Bash + 文本分析），没有外部依赖。

若未来要接入 Gitmoji、Conventional Commits 严格校验器、或公司内部的 commit 规范校验 MCP，可在路由表加对应实现。

当前路由表：

| 优先级 | 判断条件 | 实现 | 所需 MCP | 状态 |
|-------|---------|------|---------|------|
| 1 | 默认 | 本 skill 内置逻辑 | 无 | ✅ |

详见 `.claude/docs/add-plugin-guide.md`。
