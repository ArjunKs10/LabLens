#!/bin/bash
cd /Users/apple/Desktop/LabLens/LabLens

# Create directories
mkdir -p App Models Views Controllers Utilities Resources

# 1. Models/Report.swift
cat << 'SWIFT' > Models/Report.swift
// Models/Report.swift
// Defines the SwiftData schema for a medical report, strictly keeping data logic separated.
import Foundation
import SwiftData

/// Represents a medical report with its extracted text and Gemini analysis
@Model
final class Report {
    var id: UUID
    var dateAdded: Date
    var originalText: String
    var analysisResult: String

    init(id: UUID = UUID(), dateAdded: Date = Date(), originalText: String, analysisResult: String) {
        self.id = id
        self.dateAdded = dateAdded
        self.originalText = originalText
        self.analysisResult = analysisResult
    }
}
SWIFT

# 2. Models/GeminiAPIModels.swift
cat << 'SWIFT' > Models/GeminiAPIModels.swift
// Models/GeminiAPIModels.swift
// Defines the data models for decoding the Gemini API response.
import Foundation

struct GeminiResponse: Codable {
    let candidates: [Candidate]?
}

struct Candidate: Codable {
    let content: GeminiContent
}

struct GeminiContent: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
}
SWIFT

# 3. Controllers/PDFController.swift
cat << 'SWIFT' > Controllers/PDFController.swift
// Controllers/PDFController.swift
// Handles business logic for PDF import and text extraction.
import Foundation
import PDFKit

/// Handles PDF import and text extraction
class PDFController: ObservableObject {
    @Published var extractedText: String?
    @Published var error: String?
    
    /// Extracts text from the provided PDF file URL
    func extractText(from url: URL) {
        guard let pdfDocument = PDFDocument(url: url) else {
            DispatchQueue.main.async {
                self.error = "Could not open the PDF file."
                self.extractedText = nil
            }
            return
        }
        
        var text = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let pageText = page.string {
                text += pageText + "\n"
            }
        }
        
        DispatchQueue.main.async {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                self.error = "No extractable text found in the PDF."
                self.extractedText = nil
            } else {
                self.extractedText = text
                self.error = nil
            }
        }
    }
    
    /// Clears the current extracted text and error
    func clear() {
        extractedText = nil
        error = nil
    }
}
SWIFT

# 4. Controllers/GeminiController.swift
cat << 'SWIFT' > Controllers/GeminiController.swift
// Controllers/GeminiController.swift
// Handles all Gemini API calls and state management during the call.
import Foundation

/// Handles all Gemini API calls
class GeminiController: ObservableObject {
    @Published var isLoading = false
    @Published var analysisResult: String?
    @Published var error: String?
    
    /// Sends the extracted text to the Gemini API for explanation
    @MainActor
    func analyzeReport(extractedText: String) async {
        isLoading = true
        analysisResult = nil
        error = nil
        
        let apiKey = SecretsManager.loadAPIKey()
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            self.error = "Invalid API URL."
            self.isLoading = false
            return
        }
        
        let prompt = "You are a helpful medical report explainer. Explain each value in these blood test results in simple, friendly English. For each value mention what it measures and whether it is within a normal range. Do not diagnose or give medical advice. Here are the results: \(extractedText)"
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.error = "API request failed. Please check your API key and internet connection."
                self.isLoading = false
                return
            }
            
            let result = try JSONDecoder().decode(GeminiResponse.self, from: data)
            if let text = result.candidates?.first?.content.parts.first?.text {
                self.analysisResult = text
            } else {
                self.error = "Failed to parse API response."
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Clears the current analysis state
    func clear() {
        analysisResult = nil
        error = nil
        isLoading = false
    }
}
SWIFT

# 5. Controllers/ReportController.swift
cat << 'SWIFT' > Controllers/ReportController.swift
// Controllers/ReportController.swift
// Handles SwiftData CRUD operations keeping data logic separate from Views.
import Foundation
import SwiftData

/// Handles SwiftData CRUD operations for Reports
@MainActor
class ReportController: ObservableObject {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Saves a new report to the database
    func saveReport(originalText: String, analysisResult: String) {
        let newReport = Report(originalText: originalText, analysisResult: analysisResult)
        modelContext.insert(newReport)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save report: \(error.localizedDescription)")
        }
    }
    
    /// Deletes a report from the database
    func deleteReport(_ report: Report) {
        modelContext.delete(report)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete report: \(error.localizedDescription)")
        }
    }
}
SWIFT

# 6. Views/HomeView.swift
cat << 'SWIFT' > Views/HomeView.swift
// Views/HomeView.swift
// SwiftUI UI code only. Delegates user actions to injected Controllers.
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Home Screen — Clean welcome screen with an "Import Report" button and a list of previously analysed reports
struct HomeView: View {
    @EnvironmentObject var reportController: ReportController
    @EnvironmentObject var pdfController: PDFController
    @EnvironmentObject var geminiController: GeminiController
    
    @Query(sort: \Report.dateAdded, order: .reverse) private var reports: [Report]
    
    @State private var isImporterPresented = false
    @State private var navigateToAnalysis = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if reports.isEmpty {
                    ContentUnavailableView(
                        "No Reports",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Import a medical report to get started.")
                    )
                } else {
                    List {
                        ForEach(reports) { report in
                            NavigationLink(destination: HistoryDetailView(report: report)) {
                                VStack(alignment: .leading) {
                                    Text("Report Analysis")
                                        .font(.headline)
                                    Text(report.dateAdded.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteReports)
                    }
                }
                
                Button(action: {
                    isImporterPresented = true
                }) {
                    Label("Import Report", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("LabLens")
            .fileImporter(
                isPresented: $isImporterPresented,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .navigationDestination(isPresented: $navigateToAnalysis) {
                AnalysisView()
            }
        }
    }
    
    /// Delegates deletion to the ReportController
    private func deleteReports(offsets: IndexSet) {
        for index in offsets {
            reportController.deleteReport(reports[index])
        }
    }
    
    /// Handles the PDF import result and triggers navigation via controller
    private func handleImport(result: Result<[URL], Error>) {
        do {
            guard let selectedFile: URL = try result.get().first else { return }
            
            if selectedFile.startAccessingSecurityScopedResource() {
                defer { selectedFile.stopAccessingSecurityScopedResource() }
                pdfController.extractText(from: selectedFile)
                geminiController.clear()
                navigateToAnalysis = true
            } else {
                pdfController.error = "Permission denied to access the file."
                navigateToAnalysis = true
            }
        } catch {
            pdfController.error = error.localizedDescription
            navigateToAnalysis = true
        }
    }
}
SWIFT

# 7. Views/AnalysisView.swift
cat << 'SWIFT' > Views/AnalysisView.swift
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
                    CardView {
                        Text(result)
                            .font(.body)
                    }
                    
                    Button("Save to History") {
                        saveReport()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
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
        .onAppear {
            if !hasStartedAnalysis {
                hasStartedAnalysis = true
                if let extractedText = pdfController.extractedText {
                    Task {
                        await geminiController.analyzeReport(extractedText: extractedText)
                    }
                }
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
SWIFT

# 8. Views/HistoryDetailView.swift
cat << 'SWIFT' > Views/HistoryDetailView.swift
// Views/HistoryDetailView.swift
// SwiftUI UI code only. Shows details for a previously analyzed report.
import SwiftUI

/// Tap a past report to re-read its explanation
struct HistoryDetailView: View {
    let report: Report
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardView {
                    Text(report.analysisResult)
                        .font(.body)
                }
            }
            .padding()
        }
        .navigationTitle("Past Report")
        .navigationBarTitleDisplayMode(.inline)
        
        Spacer()
        Text("This is not medical advice. Always consult a qualified healthcare professional.")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding()
    }
}
SWIFT

# 9. Utilities/SecretsManager.swift
cat << 'SWIFT' > Utilities/SecretsManager.swift
// Utilities/SecretsManager.swift
// Business logic for securely accessing secrets.
import Foundation

/// Reads API key from Secrets.plist
struct SecretsManager {
    static func loadAPIKey() -> String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GeminiAPIKey"] as? String else {
            fatalError("Secrets.plist not found or GeminiAPIKey missing")
        }
        return key
    }
}
SWIFT

# 10. Resources/Secrets.plist
cat << 'XML' > Resources/Secrets.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>GeminiAPIKey</key>
	<string>YOUR_API_KEY_HERE</string>
</dict>
</plist>
XML

# 11. App/LabLensApp.swift
cat << 'SWIFT' > App/LabLensApp.swift
// App/LabLensApp.swift
// App entry point. Handles setup and dependency injection.
import SwiftUI
import SwiftData

@main
struct LabLensApp: App {
    let sharedModelContainer: ModelContainer
    @StateObject private var reportController: ReportController
    @StateObject private var pdfController = PDFController()
    @StateObject private var geminiController = GeminiController()

    init() {
        do {
            sharedModelContainer = try ModelContainer(for: Report.self)
            _reportController = StateObject(wrappedValue: ReportController(modelContext: sharedModelContainer.mainContext))
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(reportController)
                .environmentObject(pdfController)
                .environmentObject(geminiController)
                .modelContainer(sharedModelContainer)
        }
    }
}
SWIFT

# 12. .gitignore
cd /Users/apple/Desktop/LabLens
cat << 'GITIGNORE' > .gitignore
# Xcode
xcuserdata/
*.xcscmblueprint
*.xccheckout
build/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
*.hmap
*.ipa
*.dSYM.zip
*.dSYM
.build/
Pods/
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output
iOSInjectionProject/

# Secrets
LabLens/Resources/Secrets.plist
Secrets.plist
GITIGNORE

