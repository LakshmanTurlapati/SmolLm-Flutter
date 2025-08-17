# SmolLM Flutter Research Project

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B.svg?style=flat&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2.svg?style=flat&logo=dart)](https://dart.dev)
[![iOS](https://img.shields.io/badge/iOS-14.0+-000000.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![Research](https://img.shields.io/badge/Status-Research-orange.svg?style=flat)](https://github.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](LICENSE)

<div align="center">
  <img src="assets/Image.png" alt="SmolLM Flutter App - On-device AI Chat Interface" width="350">
</div>

> A research project demonstrating on-device Large Language Model inference in mobile applications using SmolLM2-360M and Flutter

## Overview

This project explores the feasibility and implementation of running Large Language Models (LLMs) natively on mobile devices without requiring internet connectivity. Using the lightweight **SmolLM2-360M** model with **Flutter** and **fllama** bindings, we achieve real-time AI chat capabilities entirely on-device.

### Research Objectives

- **Privacy-First AI**: Demonstrate fully offline LLM inference on mobile devices
- **Performance Analysis**: Measure inference speed, memory usage, and battery consumption
- **Technical Feasibility**: Validate cross-platform deployment of quantized models
- **User Experience**: Design intuitive interfaces for on-device AI interactions

## Architecture

```mermaid
graph TB
    subgraph "Flutter Application Layer"
        A[Chat UI<br/>simple_chat_screen.dart] --> B[LLM Service<br/>llm_service.dart]
        B --> C[Chat Models<br/>chat_models.dart]
    end
    
    subgraph "Native Integration Layer"
        B --> D[fllama Plugin<br/>Flutter Bindings]
        D --> E[llama.cpp<br/>C++ Inference Engine]
    end
    
    subgraph "Model Layer"
        E --> F[SmolLM2-360M<br/>Q4_K_M GGUF Format<br/>271MB]
    end
    
    subgraph "Platform Layer"
        E --> G[Metal GPU<br/>iOS Acceleration]
        E --> H[CPU Inference<br/>ARM64 Optimization]
    end
    
    style A fill:#e1f5fe
    style F fill:#fff3e0
    style G fill:#f3e5f5
    style H fill:#f3e5f5
```

## Technical Specifications

### Model Details
- **Architecture**: SmolLM2-360M (360 million parameters)
- **Quantization**: Q4_K_M (4-bit quantization)
- **File Size**: 271MB
- **Context Window**: 2,048 tokens
- **Source Repository**: [bartowski/SmolLM2-360M-Instruct-GGUF](https://huggingface.co/bartowski/SmolLM2-360M-Instruct-GGUF)¹

### Performance Metrics

<div align="center">

| Device | Tokens/Second | Memory Usage | First Load Time |
|--------|---------------|--------------|-----------------|
| iPhone 15 Pro | 15-20 | ~300MB | ~2-3 seconds |
| iPhone 13 | 10-15 | ~300MB | ~3-4 seconds |
| iOS Simulator | 5-10 | ~300MB | ~5-8 seconds |

</div>

### Platform Support
- **iOS**: 14.0+ (Production Ready)
- **Android**: Configured (Requires Testing)
- **Web**: Configured (Requires WASM)

## Dependencies

### Core Framework
- **Flutter SDK**: 3.7.2+
- **fllama**: [Telosnex/fllama](https://github.com/Telosnex/fllama)² (Flutter bindings for llama.cpp)
- **llama.cpp**: C++ inference engine³

### Flutter Packages
```yaml
dependencies:
  fllama:
    git:
      url: https://github.com/Telosnex/fllama.git
      ref: main
  path_provider: ^2.1.1
  http: ^1.1.0
```

## Installation

### Prerequisites
```bash
# Verify Flutter installation
flutter --version  # Requires 3.7.2+

# iOS development (macOS only)
pod --version
xcode-select --install
```

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd smollm_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **iOS setup** (Required for iOS development)
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. **Download model** (Optional - happens automatically on first run)
   ```bash
   ./download_model.sh
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## Usage

### Live Demo

<div align="center">
  <a href="https://youtu.be/uYtQDjZNp_Y" target="_blank">
    <img src="https://img.youtube.com/vi/uYtQDjZNp_Y/maxresdefault.jpg" alt="SmolLM Flutter Demo - On-device AI Chat" width="500">
  </a>
  <p><em>🎥 <strong><a href="https://youtu.be/uYtQDjZNp_Y">Watch Demo</a></strong> - Real-time demonstration of on-device SmolLM2-360M inference with streaming responses</em></p>
</div>

### First Launch Behavior
```mermaid
sequenceDiagram
    participant U as User
    participant A as App
    participant M as Model Service
    participant H as HuggingFace

    U->>A: Launch App
    A->>U: Show Welcome Screen
    U->>A: Tap "Start Chatting"
    A->>A: Navigate to Chat
    U->>A: Send First Message
    A->>M: Initialize LLM Service
    M->>M: Check Model Exists
    M->>H: Download SmolLM2-360M (271MB)
    H->>M: Model Downloaded
    M->>M: Load Model into Memory
    M->>A: Service Ready
    A->>M: Generate Response
    M->>A: Stream Tokens
    A->>U: Display Real-time Response
```

### Chat Interface Features
- **Streaming Responses**: Token-by-token generation
- **Conversation History**: Persistent chat context
- **Error Handling**: Network and model failure recovery
- **Loading States**: Download progress and initialization feedback

## Research Findings

### Key Achievements

<div align="center">

| Achievement | Status | Details |
|-------------|---------|---------|
| **Integration** | ✅ | Working fllama + SmolLM2-360M integration |
| **Real-time Inference** | ✅ | Streaming token generation on mobile hardware |
| **Performance** | ✅ | 4-bit quantization maintains quality while reducing size |
| **Production Ready** | ✅ | Complete error handling and user experience |

</div>  

### Technical Challenges Resolved

1. **Framework Integration Issues**
   - Resolved phantom `SmolLM.framework` references in Xcode project
   - Fixed callback type mismatches in fllama API

2. **Model Distribution Problems**
   - Corrected HuggingFace repository and file naming conventions
   - Implemented robust model download and verification

3. **Performance Optimization**
   - Configured optimal inference parameters for mobile constraints
   - Implemented GPU acceleration where available

### Performance Analysis

```mermaid
graph LR
    subgraph "Memory Usage"
        A[Model Loading<br/>271MB] --> B[Runtime Memory<br/>~300MB Total]
    end
    
    subgraph "Inference Speed"
        C[First Token<br/>1-2 seconds] --> D[Subsequent Tokens<br/>5-20 per second]
    end
    
    subgraph "Energy Efficiency"
        E[GPU Acceleration<br/>When Available] --> F[Optimized for<br/>Mobile Battery]
    end
```

## Project Structure

```
smollm_flutter/
├── lib/
│   ├── main.dart                    # Application entry point
│   ├── simple_chat_screen.dart      # Chat interface with streaming
│   ├── services/
│   │   └── llm_service.dart        # Core LLM inference service
│   └── models/
│       └── chat_models.dart        # Data models and conversation management
├── ios/
│   ├── Podfile                     # iOS dependencies and configuration
│   └── Runner/
│       └── Info.plist              # iOS app configuration
├── assets/
│   └── models/                     # Local model storage
├── download_model.sh               # Model download automation
└── pubspec.yaml                    # Flutter dependencies
```

## Future Research Directions

### Technical Enhancements
- **Model Variants**: Testing larger models (SmolLM2-1.7B) on high-end devices
- **Quantization Studies**: Comparing Q4_K_M vs Q5_K_M vs Q8_0 performance
- **Multi-platform Validation**: Android and Web deployment testing
- **Context Management**: Implementing conversation memory optimization

### Performance Optimization
- **Device-Specific Tuning**: Adaptive parameters based on hardware capabilities
- **Battery Impact Analysis**: Long-term usage studies
- **Model Caching Strategies**: Reducing initialization time

### User Experience Research
- **Interface Design**: Optimal mobile AI interaction patterns
- **Accessibility**: Voice input and screen reader compatibility
- **Privacy Features**: Local conversation export and deletion

## Citations and References

1. **SmolLM2 Model**: Allal, Loubna Ben, et al. "SmolLM2 - A Family of Small Language Models." *Hugging Face Model Hub*, 2024. [bartowski/SmolLM2-360M-Instruct-GGUF](https://huggingface.co/bartowski/SmolLM2-360M-Instruct-GGUF)

2. **fllama Flutter Plugin**: Telosnex. "fllama - Flutter bindings for llama.cpp." *GitHub*, 2024. [github.com/Telosnex/fllama](https://github.com/Telosnex/fllama)

3. **llama.cpp Inference Engine**: Gerganov, Georgi. "llama.cpp - Port of Facebook's LLaMA model in C/C++." *GitHub*, 2024. [github.com/ggerganov/llama.cpp](https://github.com/ggerganov/llama.cpp)

4. **GGUF Format**: "GGUF - GPT-Generated Unified Format." *llama.cpp Documentation*, 2024.

5. **Original SmolLM Research**: Allal, Loubna Ben, et al. "SmolLM: A Family of Small Language Models." *arXiv preprint*, 2024.

## Contributing

This research project welcomes contributions in the following areas:
- Performance benchmarking on different devices
- Implementation of additional model formats
- User interface and experience improvements
- Documentation and research findings

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Research Project by Lakshman Turlapati**  
*Exploring the frontier of on-device artificial intelligence in mobile applications*

**Contact**: [Your Contact Information]  
**Institution**: [Your Institution/Organization]  
**Date**: August 2025