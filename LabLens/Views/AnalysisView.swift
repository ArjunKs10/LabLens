// Views/AnalysisView.swift
// SwiftUI UI code for displaying the Gemini analysis result or loading state.
import SwiftUI


/// Shows a loading state while Gemini is processing, then displays the explanation in a readable card-based layout
struct AnalysisView: View {
    @EnvironmentObject var pdfViewModel: PDFViewModel
    @EnvironmentObject var geminiViewModel: GeminiViewModel
    @EnvironmentObject var reportViewModel: ReportViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var hasStartedAnalysis = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let error = pdfViewModel.error {
                    ErrorView(message: error)
                } else if let error = geminiViewModel.error {
                    ErrorView(message: error)
                } else if geminiViewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing report...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if let result = geminiViewModel.analysisResult {
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
        .task(id: pdfViewModel.extractedText) {
            if !hasStartedAnalysis, let text = pdfViewModel.extractedText {
                hasStartedAnalysis = true
                await geminiViewModel.analyzeReport(extractedText: text)
            }
        }
        
        Spacer()
        Text("This is not medical advice. Always consult a qualified healthcare professional.")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding()
    }
    
    /// Delegates saving the report to the ReportViewModel
    private func saveReport() {
        if let text = pdfViewModel.extractedText, let analysis = geminiViewModel.analysisResult {
            reportViewModel.saveReport(originalText: text, analysisResult: analysis)
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
