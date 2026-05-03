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
