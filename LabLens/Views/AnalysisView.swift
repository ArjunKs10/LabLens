// Views/AnalysisView.swift
// SwiftUI UI code for displaying the Gemini analysis result or loading state.
import SwiftUI


/// Shows a loading state while Gemini is processing, then displays the explanation in a readable card-based layout
struct AnalysisView: View {
    @EnvironmentObject var pdfController: PDFController
    @EnvironmentObject var geminiController: GeminiController
    @EnvironmentObject var reportController: ReportController
    
    @Environment(\.dismiss) private var dismiss
    @State private var hasStartedAnalysis = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let error = pdfController.error {
                    ErrorView(message: error)
                } else if let error = geminiController.error {
                    ErrorView(message: error)
                } else if geminiController.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing report...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if let result = geminiController.analysisResult {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .font(.title)
                                .foregroundColor(.accentColor)
                            Text("Your Analysis")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal)
                        
                        CardView {
                            // Render Markdown properly
                            Text(LocalizedStringKey(result))
                                .font(.body)
                                .lineSpacing(6)
                        }
                        
                        Button(action: {
                            saveReport()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                Text("Save to History")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(16)
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                } else {
                    Text("Preparing analysis...")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: pdfController.extractedText) {
            if !hasStartedAnalysis, let text = pdfController.extractedText {
                hasStartedAnalysis = true
                await geminiController.analyzeReport(extractedText: text)
            }
        }
        
        Spacer()
        Text("This is not medical advice. Always consult a qualified healthcare professional.")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding()
    }
    
    /// Delegates saving the report to the ReportController
    private func saveReport() {
        if let text = pdfController.extractedText, let analysis = geminiController.analysisResult {
            reportController.saveReport(originalText: text, analysisResult: analysis)
        }
    }
}

struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Error")
                .font(.headline)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
