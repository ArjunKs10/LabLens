// ViewModels/GeminiViewModel.swift
// Handles all Gemini API calls and state management during the call.
import Foundation
import SwiftUI
import Combine

/// Handles all Gemini API calls
class GeminiViewModel: ObservableObject {
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
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            self.error = "Invalid API URL."
            self.isLoading = false
            return
        }
        
        let prompt = """
        You are a helpful medical report explainer. Explain each value in these blood test results in simple, friendly English. 
        For each value, mention what it measures and whether it is within a normal range. 
        If a value is out of range, you may provide general, widely accepted lifestyle or dietary information related to that metric (e.g., "General wellness guidelines suggest eating more leafy greens"), but you MUST explicitly state that this is general information and NOT medical advice. 
        Do not diagnose, prescribe, or give medical advice. 
        Format your response cleanly using Markdown, with bolding for the test names and bullet points.
        You can give advices which are non medical and are safe to be given.
        Here are the results: \(extractedText)
        """
        
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
