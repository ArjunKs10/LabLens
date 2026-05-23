// ViewModels/ReportViewModel.swift
// Handles SwiftData CRUD operations keeping data logic separate from Views.
import Foundation
import SwiftData
import SwiftUI
import Combine

/// Handles SwiftData CRUD operations for Reports
@MainActor
class ReportViewModel: ObservableObject {
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
