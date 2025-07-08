//
//  StatsCardView.swift
//  EatLock
//
//  Created by AI Assistant on 2025/07/03.
//

import SwiftUI

struct StatsCardView: View {
    let stats: ActionLogStats
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "記録回数",
                value: "\(stats.totalLogs)",
                icon: "doc.text.fill",
                color: .green,
                accessibilityLabel: "記録回数は\(stats.totalLogs)回です"
            )
            StatCard(
                title: "防いだカロリー",
                value: "\(stats.totalPreventedCalories)",
                icon: "flame.fill",
                color: .green,
                accessibilityLabel: "防いだカロリーは\(stats.totalPreventedCalories)キロカロリーです"
            )
            StatCard(
                title: "継続日数",
                value: "\(stats.consecutiveDays)",
                icon: "calendar.badge.checkmark",
                color: .green,
                accessibilityLabel: "継続日数は\(stats.consecutiveDays)日です"
            )
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("統計情報カード")
        .accessibilityHint("記録回数、防いだカロリー、継続日数の統計を表示しています")
    }
}

// MARK: - StatCard Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let accessibilityLabel: String
    
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
                .dynamicTypeSize(.large ... .accessibility3)
            
            // ラベル
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .dynamicTypeSize(.large ... .accessibility3)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("統計情報カード")
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
        
        StatsCardView(stats: ActionLogStats(
            totalLogs: 0,
            successLogs: 0,
            totalPreventedCalories: 0,
            consecutiveDays: 0
        ))
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
        
        StatsCardView(stats: ActionLogStats(
            totalLogs: 0,
            successLogs: 0,
            totalPreventedCalories: 0,
            consecutiveDays: 0
        ))
    }
    .background(Color(.systemGray6))
    .preferredColorScheme(.dark)
}