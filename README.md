# AI Translator

A real-time meeting translation iOS app supporting **Chinese, Japanese, English, and Korean** — built with Apple's on-device STT and Groq's Qwen3-32B LLM.

## Features

- **Real-time speech recognition** using Apple's `SFSpeechRecognizer`
- **AI-powered translation** via [Groq API](https://console.groq.com) + Qwen3-32B
- **Text-to-speech output** using Apple's `AVSpeechSynthesizer`
- **4 languages**: 中文 / 日本語 / English / 한국어
- **TTS toggle** — mute/unmute translated speech
- **Quick direction swap** — switch source/target language instantly

## Architecture

```
Microphone → Apple STT (SFSpeechRecognizer)
           → Groq API (Qwen3-32B translation)
           → Apple TTS (AVSpeechSynthesizer)
```

Low-latency design: only the translation step goes over the network.

## Requirements

- iOS 17+
- Xcode 16+
- [Groq API Key](https://console.groq.com/keys) (free tier available)

## Setup

1. Clone the repo and open `aitranslator.xcodeproj` in Xcode
2. Set your development team in **Signing & Capabilities**
3. Build and run on a real device (STT requires a physical device)
4. Tap the **gear icon** → paste your Groq API Key → Save

## Usage

1. Select source and target language at the top
2. Tap the **mic button** to start listening
3. Speak — recognized text appears in real time
4. After a pause, translation appears and is read aloud
5. Tap **⇌** (bottom right) to swap languages for the other person
6. Tap the **speaker icon** to toggle TTS on/off

## Privacy

- Speech recognition is processed via Apple's servers (`requiresOnDeviceRecognition = false`)
- Your Groq API key is stored securely in the iOS Keychain
- No audio or text is stored locally

## License

MIT
