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
            let container = try ModelContainer(for: Report.self)
            sharedModelContainer = container
            _reportController = StateObject(wrappedValue: ReportController(modelContext: container.mainContext))
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
