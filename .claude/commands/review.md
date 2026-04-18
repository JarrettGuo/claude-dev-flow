---
description: Run adversarial review on uncommitted changes or a specific file, without the full dev flow.
argument-hint: [file-path or empty for git diff]
---

Invoke `@reviewer` on: $ARGUMENTS

## 规则

如果未提供参数，审查当前未提交改动：
- 先跑 `git diff --staged`
- 若无暂存内容，跑 `git diff`
- 若两者都空，告诉用户"无改动可 review"

如果提供了文件路径，审查该文件对照团队规范。

展示 reviewer 的完整报告。

## 使用场景

- 自己写了一段代码想快速确认是否符合规范
- `/dev` 或 `/fix` 走完之后想再过一遍
- 集成进 pre-commit 前的自检
