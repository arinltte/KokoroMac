<p align="center">
  <img src="public/KokoroMaclogo.jpg" alt="KokoroMac Logo" width="64" />
  <br />
  <h1 align="center">KokoroMac</h1>
  <p align="center">专为 Mac 打造的本地、开源权重文本转语音工作室。</p>
  <p align="center">
    <a href="https://github.com/arinltte/KokoroMac/releases/latest"><img src="https://img.shields.io/github/v/release/arinltte/KokoroMac?style=flat-square&color=blue" alt="Latest Release" /></a>
    <a href="https://github.com/arinltte/KokoroMac/blob/main/LICENSE"><img src="https://img.shields.io/github/license/arinltte/KokoroMac?style=flat-square&color=green" alt="License" /></a>
    <img src="https://img.shields.io/badge/macOS-14.0%2B-blue?style=flat-square" alt="macOS" />
    <img src="https://img.shields.io/badge/100%25-离线运行-brightgreen?style=flat-square" alt="Offline" />
  </p>
</p>

<p align="center">
  <a href="./README.md">English</a> | <a href="./README-ZH.md">中文文档</a>
</p>
由Qwen3.7-MAX翻译，如有错误敬请谅解。

---

## 简介

**KokoroMac** 是一款原生 macOS 桌面应用，将 [Kokoro TTS](https://github.com/hexgrad/kokoro) 的强大功能直接带到您的 Apple Silicon Mac 上。它提供了美观且易用的界面，让您能够完全离线生成高质量语音。

基于最先进的 82M 参数开源权重 Kokoro 模型，KokoroMac 无需联网、无需 API 密钥，且在初始设置后，您的任何数据都不会离开本机。只需输入、生成并导出。

## ✨ 核心特性

- 🚀 **100% 离线与隐私保护**：完全在设备端运行。您的文本和生成的音频绝不会离开您的 Mac。
- 🧠 **基于 Kokoro-82M**：利用轻量级开源 TTS 模型，提供自然、高保真的语音效果。
- 🎛️ **高级语音指令**：通过可视化 UI 模块精准插入停顿和 IPA 音标覆盖，且不破坏文本格式。
- 🎨 **美观的原生 UI**：支持“纯黑”模式、环境主题，以及带有拖拽和悬停时间戳的交互式波形播放器。
- ⚡ **智能资源管理**：在空闲期间自动从内存中卸载 AI 模型，确保 Mac 流畅运行。
- 📦 **一键设置**：首次启动时自动配置 Python 环境、安装依赖并下载 AI 模型。

---

## ⚙️ 环境要求

KokoroMac 具备自给自足的设计，会在初始设置时自动安装 Python、`espeak-ng` 及所有 AI 模型。但在此之前，您需要满足以下条件：

- **macOS 14.0 (Sonoma)** 或更高版本。
- **Apple Silicon** (M1/M2/M3/M4) 芯片的 Mac。
- **[Homebrew](https://brew.sh/)**：应用使用 Homebrew 来安装 Python 3.11 和 `espeak-ng`。*（若未安装，设置向导会提供准确的终端安装命令）*。
- **网络连接**：仅在首次启动以下载依赖项和模型权重时需要。

---

## 📥 安装指南

1. 从 [Releases 页面](https://github.com/arinltte/KokoroMac/releases/latest) 下载最新的 `KokoroMac.dmg`。
2. 将 `KokoroMac.app` 拖入“应用程序”文件夹。
3. **绕过 macOS 门禁 (Gatekeeper)**：由于应用未经公证，macOS 会在首次启动时拦截。请打开“终端”并运行：
   ```bash
   xattr -rd com.apple.quarantine /Applications/KokoroMac.app
   ```
4. 启动应用并跟随屏幕上的设置向导。

---

## 🚀 快速入门

1. **输入或粘贴文本**：在文本编辑器中输入您的文稿。
2. **添加指令**：使用“语音工具箱”插入可视化的“停顿”模块，或为特殊发音（如专有名词）应用“音标覆盖”。
3. **选择声音**：从多种美式和英式英语声音中进行选择。
4. **调整语速**：使用语速滑块（0.5x 至 1.5x）微调朗读速度。
5. **生成**：点击“生成语音”，并在“音频预览”波形播放器中试听。
6. **导出**：将生成的音频保存为高质量的 `.wav` 文件。

---

## 🔒 数据与隐私

KokoroMac 尊重您的隐私。所有处理均在本地完成，无遥测，无云端 API。

| 路径 | 内容说明 |
| --- | --- |
| `~/.KokoroMac/Python` | 隔离的 Python 3.11 虚拟环境及 pip 包。 |
| `~/.KokoroMac/Cache` | HuggingFace Hub 缓存，包含 Kokoro-82M 模型权重、声音及 spaCy NLP 模型。 |
| `~/.KokoroMac/Temp` | 播放期间生成的临时 `.wav` 文件（应用启动时自动清理）。 |
| `~/.KokoroMac/server.py` | 连接 Swift UI 与 Python TTS 引擎的本地 FastAPI 后端脚本。 |

**完全卸载**  
若要彻底移除 KokoroMac 及所有下载的 AI 模型/依赖项，请运行：
```bash
rm -rf /Applications/KokoroMac.app
rm -rf ~/.KokoroMac
```

---

## 🤝 参与贡献

欢迎任何形式的贡献。无论是提交 Bug 报告、功能建议、改进文档还是提交 Pull Request，我们都深表感谢。

**贡献步骤：**

1. Fork 本仓库。
2. 创建功能分支：`git checkout -b feature/your-feature-name`
3. 提交更改并附上清晰的提交信息。
4. 向 `main` 分支发起 Pull Request，并描述您的更改内容及原因。

**报告 Bug 或请求新功能**，请前往 [Issues](https://github.com/arinltte/KokoroMac/issues) 页面。提交 Bug 报告时，请附上您的 macOS 版本及复现步骤。

---

## 📄 许可证与致谢

KokoroMac 应用程序源代码基于 [MIT 许可证](./LICENSE) 开源。

本应用是杰出的 [Kokoro TTS](https://github.com/hexgrad/kokoro) 模型与库的图形界面包裹器，该模型由 `@hexgrad` 及贡献者们创建。Kokoro 模型权重、Python 库及底层音频数据均基于 **Apache License 2.0** 许可。

我们向让本地推理成为可能的开源 AI 社区致以最深的谢意。