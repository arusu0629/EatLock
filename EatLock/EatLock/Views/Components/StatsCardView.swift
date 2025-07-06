//
//  StatsCardView.swift
//  EatLock
//
//  Created by AI Assistant on 2025/07/03.
//

import SwiftUI

struct StatsCardView: View {
    let stats: ActionLogStats?
    
    var body: some View {
        if let stats = stats {
            HStack(spacing: 16) {
                StatCard(
                    title: "記録回数",
                    value: "\(stats.totalLogs)",
                    icon: "doc.text.fill",
                    color: .green
                )
                StatCard(
                    title: "防いだカロリー",
                    value: "\(stats.totalPreventedCalories)",
                    icon: "flame.fill",
                    color: .green
                )
                StatCard(
                    title: "継続日数",
                    value: "\(stats.consecutiveDays)",
                    icon: "calendar.badge.checkmark",
                    color: .green
                )
            }
            .padding()
        } else {
            // 統計データが利用できない場合のプレースホルダー
            HStack(spacing: 16) {
                StatCard(
                    title: "記録回数",
                    value: "0",
                    icon: "doc.text.fill",
                    color: .green
                )
                StatCard(
                    title: "防いだカロリー",
                    value: "0",
                    icon: "flame.fill",
                    color: .green
                )
                StatCard(
                    title: "継続日数",
                    value: "0",
                    icon: "calendar.badge.checkmark",
                    color: .green
                )
            }
            .padding()
        }
    }
}

// MARK: - StatCard Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // アイコン
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            
            // 値
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            // ラベル
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityHint("統計情報")
    }
}

#Preview {
    VStack(spacing: 20) {
        StatsCardView(stats: ActionLogStats(
            totalLogs: 15,
            successLogs: 10,
            totalPreventedCalories: 1250,
            consecutiveDays: 5
        ))
        
        StatsCardView(stats: nil)
    }
    .background(Color(.systemGray6))
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    VStack(spacing: 20) {
        StatsCardView(stats: ActionLogStats(
            totalLogs: 15,
            successLogs: 10,
            totalPreventedCalories: 1250,
            consecutiveDays: 5
        ))
        
        StatsCardView(stats: nil)
    }
    .background(Color(.systemGray6))
    .preferredColorScheme(.dark)
}