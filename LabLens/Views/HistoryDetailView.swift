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
                    Text(LocalizedStringKey(report.analysisResult))
                        .font(.body)
                        .lineSpacing(6)
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
