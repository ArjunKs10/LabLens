// Controllers/PDFController.swift
// Handles business logic for PDF import and text extraction.
import Foundation
import PDFKit
import SwiftUI
import Combine

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
