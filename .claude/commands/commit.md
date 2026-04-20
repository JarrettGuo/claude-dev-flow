---
description: 为当前改动生成符合团队规范的 commit 消息，遵循 Angular 简化版约定。支持 --split 参数智能分组大改动为多个逻辑 commit。
argument-hint: [--split] [optional hint about the change]
---

根据用户是否传入 `--split` 参数选择流程。

User's arguments: $ARGUMENTS

## 参数解析

从 `$ARGUMENTS` 判断：

- 如果包含 `--split` → 走 **分组模式**（调用 `commit-split` skill）
- 否则 → 走 **单 commit 模式**（调用 `format-commit` skill，原流程）

## 模式 A：单 commit 模式（默认）

触发条件：`$ARGUMENTS` 不含 `--split`

使用 `format-commit` skill 分析改动并生成单个 commit message。

### 执行步骤

1. 通过 Bash 读取 `git status` 和 `git diff --staged`（若空则 `git diff`）
2. 按 `format-commit` skill 的逻辑分析
3. 输出：
   - 变更分析
   - 推荐 commit message
   - 备选方案
   - 提交命令
   - 红旗警告（如有）

## 模式 B：分组模式（`--split`）

触发条件：`$ARGUMENTS` 含 `--split`

使用 `commit-split` skill 把改动分成多组逻辑独立的 commit 建议。

### 执行步骤

1. 通过 Bash 读取 `git status` 和 `git diff`
2. 如果改动为空，告诉用户"没有改动可以 commit"并退出
3. 如果改动文件 < 3 个，建议用户走单 commit 模式（提示："改动太少，建议用 `/commit`（不带 --split）"）
4. 否则按 `commit-split` skill 的逻辑：
   - 按 CLAUDE.md 目录约定 / 启发式规则 / 一级目录 三级降级分组
   - AI 语义审视分组合理性
   - 为每组调用 `format-commit` 生成 commit message
   - 输出结构化方案（每组：message + 文件清单 + git add + git commit 命令）
5. 提示用户按顺序执行每组命令

### 分组模式额外提示

- 分组数 1 组：改动集中，建议走单 commit 模式
- 分组数 2-6 组：正常分组输出
- 分组数 > 6 组：说明改动太碎，建议用户先 squash 或检查是否混杂了多个独立功能

## Rules

遵守 `.claude/docs/framework-rules.md` 的全部约定。重点：

- 绝不自动 commit、不 force push
- 遵守 `.claude/docs/output-style.md` 的输出风格（少说废话、合并预检、不要自述）
- 不修改用户确认范围外的文件

本命令特有规则（两个模式都适用）：

- 绝不自动执行 `git add` 或 `git commit`，只输出命令让用户自己跑
- 绝不 `git push`
- commit subject 绝不超过 50 字符
- commit subject 结尾绝不加标点
- 若 diff 完全为空，告诉用户"没有改动可以 commit"并退出
- 分组模式下每组 subject 仍遵循 50 字符上限
