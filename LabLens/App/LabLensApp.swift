// App/LabLensApp.swift
// App entry point. Handles setup and dependency injection.
import SwiftUI
import SwiftData

@main
struct LabLensApp: App {
    let sharedModelContainer: ModelContainer
    @StateObject private var reportViewModel: ReportViewModel
    @StateObject private var pdfViewModel = PDFViewModel()
    @StateObject private var geminiViewModel = GeminiViewModel()

    init() {
        do {
            let container = try ModelContainer(for: Report.self)
            sharedModelContainer = container
            _reportViewModel = StateObject(wrappedValue: ReportViewModel(modelContext: container.mainContext))
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(reportViewModel)
                .environmentObject(pdfViewModel)
                .environmentObject(geminiViewModel)
                .modelContainer(sharedModelContainer)
        }
    }
}
