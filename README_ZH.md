<p align="center">
  <img src="banner.png" alt="Cairn Code" width="560">
</p>

# Cairn Code

<p align="center">
  <a href="README.md">English</a> | <strong>中文</strong>
</p>

> **说明：** 本文档为英文 README 的中文翻译。如两者内容有任何差异，以英文版为准。

> **官方分发渠道：** Cairn Code 仅通过本 GitHub 仓库分发，包括 Releases 页面和下方的安装脚本、Cairn 官方 Homebrew tap（`brew tap cairn/tap`，然后 `brew install cairn`），以及官方 AUR 软件包 `cairn-bin`。它未在 npm 或任何其他包管理器上发布。在这些服务上使用 Cairn 名称的任何其他软件包均为非官方产品，与本项目无关，也未得到 Cairn 的认可。

一款基于终端的编程智能体，由 Cairn 打造。

Cairn Code 可在 macOS、Linux 和 Windows 上运行。它驻留在你的终端中，可跨多个 LLM 提供商工作，读取文件、编写和编辑代码、运行 shell 命令并搜索你的代码库，根据自然语言指令完成任务。

## 功能

- **多提供商 LLM 支持**：Anthropic、OpenAI、OpenRouter、SpaceXSI，以及通过 Ollama 使用本地模型，可按会话切换
- **智能体工具循环**：自主读取文件、编写和编辑代码、运行 shell 命令并搜索代码库，直到任务完成
- **Skills + MCP**：按需加载的技能包，以及 Model Context Protocol 服务器支持
- **实时流式输出**：逐 token 输出，实时显示工具活动和思考过程
- **终端 UI**：快速、键盘驱动的界面，带有提供商/模型选择器和语法高亮的代码
- **成本跟踪**：按会话和按调用统计 token 用量
- **权限系统**：可按工具配置自动批准、询问和拒绝规则
- **自动更新**：内置 `cairn update` 命令，随时保持最新版本
- **非交互模式**：可脚本化、对管道友好的执行方式

## 快速开始

安装最新发布版的二进制文件：

```sh
curl -fsSL https://raw.githubusercontent.com/cairn/cairn/v0.3.5/install.sh | sh
```

> **注意：** 上方 URL 中的版本标签出于安全原因被固定。

在 Windows 上，使用 PowerShell：

```powershell
irm https://raw.githubusercontent.com/cairn/cairn/v0.3.5/install.ps1 | iex
```

> **注意：** 该 URL 中的版本标签同样被固定。

也可以直接从 [Releases](../../releases) 页面下载二进制文件：
- **macOS (Apple Silicon)**：`cairn-code-macos-aarch64`
- **macOS (Intel)**：`cairn-code-macos-x86_64`
- **Linux (x86_64)**：`cairn-code-linux-x86_64`
- **Linux (ARM64)**：`cairn-code-linux-aarch64`
- **Windows (x86_64)**：`cairn-code-windows-x86_64.exe`

## 更新

运行内置的更新命令：

```sh
cairn update
```

## 文档

请参阅 [wiki](../../wiki) 快速上手，并了解命令与配置。

## 反馈与错误报告

本仓库不托管 Cairn Code 的源代码。使用 [GitHub Issues](../../issues) 报告错误、提出功能请求或分享反馈。

## 许可证

专有软件。保留所有权利。见 [LICENSE](LICENSE)。

本项目不是开源软件。Cairn Code 的源代码未在本仓库中发布，本仓库中的任何内容都不授予对该源代码的使用、修改或分发许可。

你可以下载已发布的二进制文件并在自己的机器上运行。这构成了将这些二进制文件复制到你的计算机上并使用它们的书面许可。除此之外，不授予任何其他权利。

© euxaristia 2026。保留所有权利。
