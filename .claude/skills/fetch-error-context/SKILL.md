---
name: fetch-error-context
description: Fetch additional context for a bug — stack traces, error frequency, related issues, recent deploys. Used by bug-analyst and debugger. Degrades gracefully when no MCP is configured.
---

# Fetch Error Context

给 bug 分析和调试提供"这个 bug 多严重、什么时候开始的、相关改动有什么"的上下文。

## 能力范围

**负责**：
- 从错误文本/ID/链接扩展出完整上下文
- 聚合堆栈、频率、相关 issue、近期改动等信息

**不负责**：
- 定位根本原因（那是 debugger 的事）
- 修复代码

## 输入

任何之一：
- 错误消息文本
- GitLab issue 链接（如有）
- 一段错误日志

## 路由表

| 优先级 | 判断条件 | 实现 | 所需 MCP | 当前状态 |
|-------|---------|------|---------|---------|
| 1 | 输入为 GitLab issue URL | 调用 gitlab MCP 获取 issue 详情、评论、关联 MR | `gitlab` | ⚪ 未启用 |
| 2 | 默认（纯错误文本或无 MCP） | 原生降级：`git log` + `grep` 关键词 | 无 | ✅ 已启用 |

## 执行流程（原生降级实现）

没有 gitlab MCP 时仍然做力所能及的事：

1. **Git log 取近期改动**：
   - 跑 `git log --since="7 days ago" --oneline --name-only` via Bash
   - 列出近 7 天改动文件
2. **错误关键词 Grep**：
   - 从错误消息提取关键标识符（函数名、变量名、错误类型）
   - 在代码库 Grep 可能的触发位置
3. **交叉匹配**：
   - 近期改动 ∩ Grep 结果 = 高度疑似相关的文件

## 输出格式

```
## Error Summary
<一行错误描述>

## Source
<gitlab-issue / inline-text>

## Stack Trace
<如可获取；否则 "N/A — provided as inline text">

## Related Issues / MRs
<仅 gitlab MCP 可用时。列出关联 issue 和 MR，含状态和负责人>

## Recent Changes
基于 git log 近 7 天：
- <commit-hash> <msg> — 涉及文件：<files>

## Probable Code Locations
基于 Grep + 近期改动交叉匹配：
- `path/to/file.ts:42` — 推测理由

## Confidence
<high / medium / low> — <说明>
```

## 示例

### 示例 1：GitLab issue（MCP 已配置）
Query: `https://gitlab.company.com/team/repo/-/issues/142`
流程：路由到优先级 1 → gitlab MCP 取 issue + 关联 MR → 返回完整上下文。

### 示例 2：纯错误文本（降级）
Query: `TypeError: Cannot read property 'id' of undefined at profile/Main.vue:142`
流程：路由到优先级 2 → git log 找近期改动 → Grep 限定在 profile 相关 → 输出 confidence: medium 的推测。

## 扩展此 Skill

要接入其他监控（如果公司内部有自研告警平台）：

1. 用 `/add-skill` 让 Claude 引导你添加路由规则
2. 或手动：配置 MCP + 改路由表

详见 `.claude/docs/add-plugin-guide.md`。
