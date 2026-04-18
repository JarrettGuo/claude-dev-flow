---
name: read-requirement
description: Read a feature requirement or bug report from any source (Feishu doc, GitLab issue/MR, local file, or inline text). Auto-routes to the right adapter. Returns structured content so callers don't need to care about the source.
---

# Read Requirement

统一的需求/文档读取能力。调用方（analyst / bug-analyst）不需要关心数据来自哪里。

## 能力范围

**负责**：
- 判断输入是什么类型的源
- 调用合适的 MCP 或原生工具获取内容
- 提供统一的降级路径（MCP 缺失时明确告知用户）
- 以统一结构返回

**不负责**：
- 理解文档内容（那是 analyst 的工作）
- 总结或摘要（返回原文即可）
- OCR 或图片识别

## 输入

任何之一：
- 飞书文档 URL
- GitLab issue / MR / wiki URL
- 其他 https URL
- 本地文件路径
- 一段纯文本（inline requirement）

## 路由表（插拔点 ⭐）

按优先级依次尝试。前面不适用或不可用则降级。

| 优先级 | 判断条件 | 实现方式 | 所需 MCP | 当前状态 |
|-------|---------|---------|---------|---------|
| 1 | URL 匹配 `*.feishu.cn` / `*.larksuite.com` / `*.feishu.com` | 调用 feishu MCP 的文档读取工具 | `feishu` | ⚪ 未启用 |
| 2 | URL 匹配 `gitlab.*` 的 `/-/issues/` / `/-/merge_requests/` / `/-/wikis/` | 调用 gitlab MCP | `gitlab` | ⚪ 未启用 |
| 3 | 其他 https URL | 使用原生 WebFetch 工具 | 无 | ✅ 已启用 |
| 4 | 本地路径以 `.md` / `.txt` / `.pdf` 结尾 | 使用原生 Read 工具 | 无 | ✅ 已启用 |
| 5 | 其他内容 | 作为 inline text 直接使用 | 无 | ✅ 已启用 |

**状态图例**：✅ 已启用 / ⚪ 未启用（需配置对应 MCP）

## 执行流程

1. 分析输入，按上表从优先级 1 开始匹配条件
2. 若匹配到需要 MCP 的优先级：
   - 检查该 MCP 是否可用（对应工具是否出现在可用工具列表中）
   - 若可用，调用该 MCP 获取内容
   - 若不可用，**明确告知用户**并继续尝试下一优先级
3. 若匹配到原生工具的优先级，直接调用
4. 提取并结构化返回

## 降级规则（重要）

**绝不静默失败**。当匹配到的最高优先级 MCP 未配置时，明确告知用户：

示例话术：
> "检测到飞书文档链接（https://xxx.feishu.cn/docx/yyy），但项目未配置飞书 MCP。
>
> 选项：
> 1. 启用飞书 MCP：说 `/add-skill 启用飞书` 让我帮你配置
> 2. 现在直接将文档内容粘贴给我，我继续处理
>
> 你选哪个？"

若已降级到原生 WebFetch 但 URL 需要登录（常见于公司内网），同样明确告知。

## 输出格式

无论来源，统一结构返回：

```
## Source
<URL / 文件绝对路径 / "inline text">

## Source Type
<feishu-doc / gitlab-issue / gitlab-mr / gitlab-wiki / web / local-file / inline>

## Title
<如可提取；否则 "N/A">

## Metadata
- Last modified: <如可获取>
- Author: <如可获取>
- Other: <如有>

## Content
<原文。保留标题层级、列表、表格结构。不要总结。>

## Attachments
<图片 / 附件的 URL 列表，如有>
```

## 示例

### 示例 1：本地 markdown（已启用）
输入：`docs/requirement-user-profile.md`
流程：匹配优先级 4 → 原生 Read → 返回结构化内容。

### 示例 2：飞书文档（需启用 MCP）
输入：`https://xxx.feishu.cn/docx/abc123`
流程：匹配优先级 1 → 检测飞书 MCP → 未配置 → 提示用户 → 用户选择粘贴 → 按优先级 5 处理。

### 示例 3：GitLab issue
输入：`https://gitlab.company.com/team/repo/-/issues/42`
流程：匹配优先级 2 → 检测 gitlab MCP → 若已配置直接调用，否则提示用户。

### 示例 4：inline 文本
输入：`"需要给用户资料页加一个头像上传功能"`
流程：匹配优先级 5 → 直接作为 Content 返回。

## 扩展此 Skill

支持新源：

1. 用 `/add-skill` 让 Claude 引导你完成
2. 或手动：在路由表加一行 + 更新 `.mcp.json` + 更新 `plugins.config.md`

详见 `.claude/docs/add-plugin-guide.md`。
