//
//  TitleBarView.swift
//  EatLock
//
//  Created by arusu0629 on 2025/06/25.
//

import SwiftUI

struct TitleBarView: View {
    @State private var currentDate = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            // ロゴ表示
            HStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.green)
                
                Text("EatLock")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .accessibilityLabel("EatLock アプリ")
            
            Spacer()
            
            // 日付表示とAIステータス
            HStack(spacing: 12) {
                Text(formatDate(currentDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("今日の日付: \(formatDate(currentDate))")
                
                // AIステータスインジケーター
                HStack(spacing: 4) {
                    Text("AI")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    AIStatusIndicator()
                }
                .accessibilityLabel("AI機能の状態")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .onReceive(timer) { _ in
            currentDate = Date()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "EEEE M月d日"
        return formatter.string(from: date)
    }
}

#Preview {
    TitleBarView()
        .previewLayout(.sizeThatFits)
        .padding()
}