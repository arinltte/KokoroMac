<p align="center">
  <img src="public/KokoroMaclogo.jpg" alt="KokoroMac Logo" width="64" />
  <br />
  <h1 align="center">KokoroMac</h1>
  <p align="center">Local, Open-Weight Text-to-Speech Studio for Mac.</p>
  <p align="center">
    <a href="https://github.com/arinltte/KokoroMac/releases/latest"><img src="https://img.shields.io/github/v/release/arinltte/KokoroMac?style=flat-square&color=blue" alt="Latest Release" /></a>
    <a href="https://github.com/arinltte/KokoroMac/blob/main/LICENSE"><img src="https://img.shields.io/github/license/arinltte/KokoroMac?style=flat-square&color=green" alt="License" /></a>
    <img src="https://img.shields.io/badge/macOS-14.0%2B-blue?style=flat-square" alt="macOS" />
    <img src="https://img.shields.io/badge/100%25-Offline-brightgreen?style=flat-square" alt="Offline" />
  </p>
</p>

<p align="center">
  <a href="./README.md">English</a> | <a href="./README-ZH.md">中文文档</a>
</p>

---

## Introduction

**KokoroMac** is a native macOS desktop application that brings the power of [Kokoro TTS](https://github.com/hexgrad/kokoro) directly to your Apple Silicon Mac. It provides a beautiful, easy-to-use interface for generating high-quality speech from text completely offline. 

Powered by the state-of-the-art, open-weight 82M parameter Kokoro model, KokoroMac requires no internet connection, no API keys, and no data leaves your machine after the initial setup. Just type, generate, and export.

## ✨ Top Features

- 🚀 **100% Offline & Private**: Runs entirely on-device. Your text and generated audio never leave your Mac.
- 🧠 **Powered by Kokoro-82M**: Leverages the lightweight, open-weight TTS model for natural-sounding, high-fidelity voices.
- 🎛️ **Advanced Speech Directives**: Visual UI blocks for inserting precise pauses and IPA phoneme overrides without breaking text formatting.
- 🎨 **Beautiful Native UI**: Features a "True Dark" mode, ambient themes, and an interactive waveform player with seek and hover timestamps.
- ⚡ **Smart Resource Management**: Automatically unloads AI models from RAM after idle periods to keep your Mac running smoothly.
- 📦 **One-Click Setup**: Automatically provisions Python environments, installs dependencies, and downloads AI models on first launch.

---

## ⚙️ Requirements

KokoroMac is designed to be self-sufficient and will automatically install Python, `espeak-ng`, and all AI models during the initial setup. However, the following are required beforehand:

- **macOS 14.0 (Sonoma)** or later.
- **Apple Silicon** (M1/M2/M3/M4) Mac.
- **[Homebrew](https://brew.sh/)**: The app uses Homebrew to install Python 3.11 and `espeak-ng`. *(If missing, the setup wizard will provide the exact terminal command to install it).*
- **Internet Connection**: Only required during the very first launch to download dependencies and model weights.

---

## 📥 Installation

1. Download the latest `KokoroMac.dmg` from the [Releases page](https://github.com/arinltte/KokoroMac/releases/latest).
2. Drag `KokoroMac.app` to your Applications folder.
3. **Bypass macOS Gatekeeper**: Because the app is not notarized, macOS will block it on first launch. Open your Terminal and run:
   ```bash
   xattr -rd com.apple.quarantine /Applications/KokoroMac.app
   ```
4. Launch the app and follow the on-screen Setup Wizard.

---

## 🚀 Getting Started

1. **Type or Paste Text**: Enter your script into the Speech Text editor.
2. **Add Directives**: Use the Speech Toolbox to insert visual Pause blocks or apply Phoneme Overrides for tricky pronunciations (e.g., proper nouns).
3. **Select a Voice**: Choose from a variety of US and UK English voices.
4. **Adjust Speed**: Fine-tune the speech rate using the Speed slider (0.5x to 1.5x).
5. **Generate**: Click "Generate Speech" and listen to the output in the Audio Preview waveform player.
6. **Export**: Save your generated audio as a high-quality `.wav` file.

---

## 🔒 Data & Privacy

KokoroMac respects your privacy. All processing happens locally. No telemetry, no cloud APIs.

| Location | Contents |
| --- | --- |
| `~/.KokoroMac/Python` | Isolated Python 3.11 virtual environment and pip packages. |
| `~/.KokoroMac/Cache` | HuggingFace Hub cache containing the Kokoro-82M model weights, voices, and spaCy NLP models. |
| `~/.KokoroMac/Temp` | Temporary `.wav` files generated during playback (auto-cleaned on app launch). |
| `~/.KokoroMac/server.py` | The local FastAPI backend script that bridges the Swift UI with the Python TTS engine. |

**Uninstallation**  
To completely remove KokoroMac and all downloaded AI models/dependencies, run:
```bash
rm -rf /Applications/KokoroMac.app
rm -rf ~/.KokoroMac
```

---

## 🤝 Contributing

Contributions are welcome. Whether it's a bug report, a feature suggestion, a documentation improvement, or a pull request — all are appreciated.

**To contribute:**

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Commit your changes with a clear message.
4. Open a pull request against `main` with a description of what you changed and why.

**To report a bug or request a feature**, open an [issue](https://github.com/arinltte/latte/issues). Please include your macOS version and steps to reproduce for bug reports.

---

## 📄 License & Acknowledgements

The KokoroMac application source code is licensed under the [MIT License](./LICENSE).

This application is a graphical wrapper for the incredible [Kokoro TTS](https://github.com/hexgrad/kokoro) model and library, created by `@hexgrad` and contributors. The Kokoro model weights, Python library, and underlying audio data are licensed under the **Apache License 2.0**. 

We deeply appreciate the open-source AI community for making local inference possible.
