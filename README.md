# LabLens 🔬

LabLens is an intelligent iOS application that translates complex medical reports into simple, human-readable language. By leveraging on-device PDF extraction and the power of Google's Gemini Large Language Model, LabLens demystifies blood test results, ensuring patients can easily understand what their metrics measure and whether they are within typical normal ranges.

## ✨ Features

- **On-Device PDF Parsing:** Securely extract text from local medical PDFs directly on your device using Apple's `PDFKit`.
- **AI-Powered Explanations:** Integrated with Google's **Gemini 2.5 Flash API** to instantly translate medical jargon into friendly, easy-to-understand explanations.
- **Strict Guardrails:** Built-in safeguards explicitly prevent the AI from diagnosing or providing medical advice, offering only general wellness information alongside a persistent medical disclaimer.
- **Beautiful Markdown Rendering:** Dynamic results are formatted cleanly with headers, bold text, and bullet points using SwiftUI's native `LocalizedStringKey` rendering.
- **Persistent History:** Automatically saves past analyses using **SwiftData**, allowing users to revisit previous reports seamlessly.
- **Secure Key Management:** Hardened structure ensuring API keys are securely managed via an isolated `SecretsManager` and a `.gitignore` property list.

## 🏗️ Architecture

LabLens is built with a strictly enforced **Model-View-Controller (MVC)** architecture to ensure absolute separation of concerns:

- **Models:** Defined using `SwiftData` schemas (`@Model`) for local persistence, containing zero UI or business logic.
- **Views:** Pure `SwiftUI` declarative UI code. Views never make direct API calls or process data.
- **Controllers:** `ObservableObject` classes (e.g., `GeminiController`, `PDFController`, `ReportController`) injected into the view hierarchy via `@EnvironmentObject` to manage asynchronous business logic independently.

## 🚀 Getting Started

### Requirements
- iOS 17.0+
- Xcode 16.0+

### Installation & API Setup
1. Clone this repository: `git clone https://github.com/ArjunKs10/LabLens.git`
2. Open `LabLens.xcodeproj` in Xcode.
3. Get a free API Key from [Google AI Studio](https://aistudio.google.com/).
4. Create a new file inside the `Resources/` folder named **`Secrets.plist`**.
5. Add a new row to the Plist with the Key `GeminiAPIKey` (Type: String) and paste your Google API key as the Value.
6. Build and run the project (**Cmd + R**).

## ⚠️ Disclaimer

**LabLens does not provide medical advice.** The application is designed strictly for informational purposes to help users read and understand standard laboratory metric ranges. Always consult a qualified healthcare professional regarding any medical diagnosis or treatment.
