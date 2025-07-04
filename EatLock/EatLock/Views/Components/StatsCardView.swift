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
                StatCard(title: "記録回数", value: "\(stats.totalLogs)", color: .blue)
                StatCard(title: "防いだカロリー", value: "\(stats.totalPreventedCalories)", color: .green)
                StatCard(title: "継続日数", value: "\(stats.consecutiveDays)", color: .orange)
            }
            .padding()
        } else {
            // 統計データが利用できない場合のプレースホルダー
            HStack(spacing: 16) {
                StatCard(title: "記録回数", value: "0", color: .blue)
                StatCard(title: "防いだカロリー", value: "0", color: .green)
                StatCard(title: "継続日数", value: "0", color: .orange)
            }
            .padding()
        }
    }
}

// MARK: - StatCard Component
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

#Preview {
    VStack {
        StatsCardView(stats: ActionLogStats(
            totalLogs: 15,
            successLogs: 10,
            totalPreventedCalories: 1250,
            consecutiveDays: 5
        ))
        
        StatsCardView(stats: nil)
    }
    .background(Color(.systemGray6))
}