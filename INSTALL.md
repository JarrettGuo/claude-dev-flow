# 安装指南

## 环境要求

- Node.js >= 18
- Claude Code 或兼容的 MCP 客户端
- Git（可选，用于版本管理）

## 安装步骤

### 1. 克隆或下载项目

```bash
git clone <repository-url> claude-dev-flow
cd claude-dev-flow
```

或直接下载并解压到目标目录。

### 2. 配置 MCP

项目根目录已包含 `.mcp.json` 配置文件，可根据需要调整。

### 3. 验证安装

运行示例：

```bash
# 查看 Hello World 示例
cat examples/hello-world.md
```

## 配置说明

### MCP 配置

`.mcp.json` 文件定义了 agent 协作的基本配置，包括：
- Agent 角色定义
- 任务类型映射
- 执行规则

详细配置说明见 `docs/` 目录（待补充）。

## 故障排查

### 常见问题

1. **MCP 配置未生效**
   - 检查 `.mcp.json` 格式是否正确
   - 确认客户端是否支持 MCP 协议

2. **示例无法运行**
   - 确认环境要求已满足
   - 检查文件路径是否正确

## 下一步

- 阅读 [README.md](./README.md) 了解项目概览
- 查看 `examples/` 目录学习使用方法
- 参考 `docs/` 目录深入了解框架设计（待补充）
