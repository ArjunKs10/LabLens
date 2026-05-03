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
