<p align="center">
  <img src="public/KokoroMaclogo.jpg" alt="KokoroMac Logo" width="64" />
  <br />
  <h1 align="center">KokoroMac</h1>
  <p align="center">适用于 Mac 的本地化、开放权重文本转语音工作室。</p>
  <p align="center">
    <a href="https://github.com/arinltte/KokoroMac/releases/latest"><img src="https://img.shields.io/github/v/release/arinltte/KokoroMac?style=flat-square&color=blue" alt="最新版本" /></a>
    <a href="https://github.com/arinltte/KokoroMac/blob/main/LICENSE"><img src="https://img.shields.io/github/license/arinltte/KokoroMac?style=flat-square&color=green" alt="许可证" /></a>
    <img src="https://img.shields.io/badge/macOS-14.0%2B-blue?style=flat-square" alt="macOS" />
    <img src="https://img.shields.io/badge/100%25-离线-brightgreen?style=flat-square" alt="离线" />
  </p>
</p>

<p align="center">
  <a href="./README.md">English</a> | <a href="./README-ZH.md">中文文档</a>
</p>

## 简介

KokoroMac 是一款原生 macOS 桌面应用程序，将 [Kokoro TTS](https://github.com/hexgrad/kokoro) 的强大功能直接带到您的 Apple Silicon Mac 上。它提供了一个美观且易于使用的界面，让您能够完全离线地从文本生成高质量语音。

由最先进的、拥有 8200 万参数的开放权重 Kokoro 模型驱动，KokoroMac 在初始设置后无需互联网连接，无需 API 密钥，且没有任何数据会离开您的设备。只需输入、生成并导出即可。

## ✨ 核心特性

*   🚀 **100% 离线与隐私保护：** 完全在设备端运行。您的文本和生成的音频永远不会离开您的 Mac。
*   🧠 **由 Kokoro-82M 驱动：** 利用轻量级、开放权重的 TTS 模型，提供自然、高保真的语音。
*   ⏸️ **数学级精准停顿：** 提供可视化 UI 模块以插入精确的停顿（短、中、长）。后端会裁剪 AI 衰减音频并拼接精确的数字静音，实现完美的有声书节奏控制。
*   🗣️ **自定义音素发音 (Phoneme Overrides)：** 使用国际音标 (IPA) 强制指定生僻词或专有名词的准确发音，且不会破坏文本格式。
*   🎨 **美观的原生 UI：** 具备“纯黑 (True Dark)”模式、环境主题，以及带有拖拽进度和悬停时间戳功能的交互式波形播放器。
*   ⚡ **智能资源管理：** 在闲置一段时间后自动从 RAM 中卸载 AI 模型，确保您的 Mac 保持流畅运行。
*   📦 **一键设置与静默更新：** 自动配置 Python 环境、安装依赖项并下载 AI 模型。升级到新版本时会自动迁移后端脚本，无需使用终端命令。

## ⚙️ 系统要求

KokoroMac 被设计为自给自足的应用，会在初始设置期间自动安装 Python、`espeak-ng` 以及所有 AI 模型。但是， beforehand 需要满足以下条件：

*   **macOS 14.0 (Sonoma)** 或更高版本。
*   **Apple Silicon (M1/M2/M3/M4)** Mac。
*   **[Homebrew](https://brew.sh/)：** 该应用使用 Homebrew 来安装 Python 3.11 和 `espeak-ng`。（如果缺失，设置向导将提供用于安装它的确切终端命令）。
*   **互联网连接：** 仅在首次启动时需要，用于下载依赖项和模型权重。

## 📥 安装指南

1.  从 [Releases 页面](https://github.com/arinltte/KokoroMac/releases/latest) 下载最新的 `KokoroMac.dmg`。
2.  将 `KokoroMac.app` 拖入“应用程序”文件夹。
3.  **绕过 macOS 门禁 (Gatekeeper)：** 由于该应用未经过公证 (notarized)，macOS 会在首次启动时拦截它。请打开“终端”并运行以下命令：
    ```bash
    xattr -rd com.apple.quarantine /Applications/KokoroMac.app
    ```
4.  启动应用并按照屏幕上的“设置向导”进行操作。

## 🚀 快速开始

1.  **输入或粘贴文本：** 在“语音文本”编辑器中输入您的脚本。
2.  **添加控制指令：** 使用“语音工具箱”插入可视化的停顿模块（0.5秒、1.0秒、2.0秒），或为复杂发音应用“音素覆盖”。
3.  **选择声音：** 从多种美国和英国英语声音中进行选择。
4.  **调整语速：** 使用语速滑块（0.5x 至 1.5x）微调语音速率。
5.  **生成：** 点击“生成语音”，并在“音频预览”波形播放器中试听输出效果。
6.  **导出：** 将生成的音频保存为高质量的 `.wav` 文件。

## 🔒 数据与隐私

KokoroMac 尊重您的隐私。所有处理均在本地进行。没有遥测数据，没有云端 API。

| 位置 | 内容 |
| :--- | :--- |
| `~/.KokoroMac/Python` | 隔离的 Python 3.11 虚拟环境和 pip 包。 |
| `~/.KokoroMac/Cache` | HuggingFace Hub 缓存，包含 Kokoro-82M 模型权重、声音库和 spaCy NLP 模型。 |
| `~/.KokoroMac/Temp` | 播放期间生成的临时 `.wav` 文件（在应用启动时自动清理）。 |
| `~/.KokoroMac/server.py` | 本地 FastAPI 后端脚本，用于桥接 Swift UI 与 Python TTS 引擎。 |

## 卸载方法

要完全移除 KokoroMac 及所有下载的 AI 模型/依赖项，请运行：
```bash
rm -rf /Applications/KokoroMac.app
rm -rf ~/.KokoroMac
```

## 🤝 贡献指南

欢迎贡献。无论是错误报告、功能建议、文档改进还是 Pull Request，我们都不胜感激。

贡献方式：
1.  Fork 该仓库。
2.  创建功能分支：`git checkout -b feature/your-feature-name`
3.  提交您的更改并附上清晰的提交信息。
4.  针对 `main` 分支发起 Pull Request，并说明您更改的内容及原因。

要报告错误或请求新功能，请提交 [issue](https://github.com/arinltte/KokoroMac/issues)。对于错误报告，请包含您的 macOS 版本和重现步骤。

## 📄 许可证与致谢

KokoroMac 应用程序源代码基于 [MIT 许可证](./LICENSE) 授权。

*   **核心 TTS 引擎：** 本应用是令人惊叹的 [Kokoro TTS](https://github.com/hexgrad/kokoro) 模型和库的图形化封装，由 `@hexgrad` 及贡献者创建。Kokoro 模型权重、Python 库及底层音频数据基于 Apache License 2.0 授权。
*   **音频拼接与停顿管线：** v0.4.0 中集成的数学级停顿计时、音频裁剪和后端拼接的架构方法，深受 [nazdridoy/kokoro-tts](https://github.com/nazdridoy/kokoro-tts) 中记录的社区方案启发。

我们深深感谢开源 AI 社区让本地推理成为可能。
