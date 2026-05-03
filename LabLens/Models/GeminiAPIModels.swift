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
