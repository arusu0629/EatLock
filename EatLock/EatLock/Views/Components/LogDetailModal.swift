//
//  LogDetailModal.swift
//  EatLock
//
//  Created by AI Assistant on 2025/07/03.
//
//  ⚠️ DEPRECATED: This file is no longer used in the current navigation system.
//  Consider removing this file in a future update.
//  Use LogDetailView in NavigationDestination.swift instead.
//

import SwiftUI

@available(*, deprecated, message: "Use LogDetailView in NavigationDestination.swift instead")
struct LogDetailModal: View {
    let actionLog: ActionLog
    let repository: ActionLogRepository
    @Binding var isPresented: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ヘッダー情報
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(actionLog.logType.emoji)
                            .font(.largeTitle)
                        Text(actionLog.logType.displayName)
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    
                    Text(actionLog.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // ログ内容
                VStack(alignment: .leading, spacing: 8) {
                    Text("記録内容")
                        .font(.headline)
                    Text(repository.getSecureContent(for: actionLog))
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // AIフィードバック
                if let feedback = repository.getSecureAIFeedback(for: actionLog) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AIフィードバック")
                            .font(.headline)
                        Text(feedback)
                            .font(.body)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // 防いだカロリー
                if let calories = actionLog.preventedCalories {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("防いだカロリー")
                            .font(.headline)
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(calories) kcal")
                                .font(.title2)
                                .bold()
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // 感情タグ
                if !actionLog.emotionTags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("感情タグ")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(actionLog.emotionTags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.2))
                                        .foregroundColor(.purple)
                                        .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("ログ詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("閉じる") {
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    let sampleLog = ActionLog(content: "夜中にアイスクリームを食べたくなったが、水を飲んで我慢した", logType: .success)
    sampleLog.setAIFeedback("素晴らしい自制心です！水を飲むのは良い対策ですね。次回も同じ方法でトライしてみてください。", preventedCalories: 200)
    sampleLog.addEmotionTag("達成感")
    sampleLog.addEmotionTag("安心")
    
    // プレビュー用の仮のRepository
    let container = try! ModelContainer(for: ActionLog.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    let repository = ActionLogRepository(modelContext: context)
    
    return LogDetailModal(
        actionLog: sampleLog,
        repository: repository,
        isPresented: .constant(true)
    )
}