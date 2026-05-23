// Views/HomeView.swift
// SwiftUI UI code only. Delegates user actions to injected ViewModels.
import SwiftUI

import SwiftData
import UniformTypeIdentifiers

/// Home Screen — Clean welcome screen with an "Import Report" button and a list of previously analysed reports
struct HomeView: View {
    @EnvironmentObject var reportViewModel: ReportViewModel
    @EnvironmentObject var pdfViewModel: PDFViewModel
    @EnvironmentObject var geminiViewModel: GeminiViewModel
    
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
    
    /// Delegates deletion to the ReportViewModel
    private func deleteReports(offsets: IndexSet) {
        for index in offsets {
            reportViewModel.deleteReport(reports[index])
        }
    }
    
    /// Handles the PDF import result and triggers navigation via view model
    private func handleImport(result: Result<[URL], Error>) {
        do {
            guard let selectedFile: URL = try result.get().first else { return }
            
            if selectedFile.startAccessingSecurityScopedResource() {
                defer { selectedFile.stopAccessingSecurityScopedResource() }
                pdfViewModel.extractText(from: selectedFile)
                geminiViewModel.clear()
                navigateToAnalysis = true
            } else {
                pdfViewModel.error = "Permission denied to access the file."
                navigateToAnalysis = true
            }
        } catch {
            pdfViewModel.error = error.localizedDescription
            navigateToAnalysis = true
        }
    }
}
