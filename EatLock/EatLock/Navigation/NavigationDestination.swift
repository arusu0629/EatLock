//
//  NavigationDestination.swift
//  EatLock
//
//  Created by NavigationSystem on 2025/06/25.
//

import SwiftUI
import SwiftData

/// ナビゲーション先を定義するenum
/// 型安全なナビゲーション管理を提供
enum NavigationDestination: Hashable {
    case home
    case logDetail(ActionLog)
    case settings
    case statistics
    case tutorial
}

/// NavigationDestinationのビュー生成拡張
extension NavigationDestination {
    @ViewBuilder
    func destination(repository: ActionLogRepository) -> some View {
        switch self {
        case .home:
            ContentView()
        case .logDetail(let log):
            LogDetailModalView(log: log, repository: repository)
        case .settings:
            SettingsView()
        case .statistics:
            StatisticsView()
        case .tutorial:
            TutorialView()
        }
    }
}

/// セキュアなログ詳細ビュー
/// ActionLogRepositoryのセキュアメソッドを使用してユーザーデータを保護
/// ActionLogRowと一貫した日付フォーマット（log.formattedDate）を使用
struct LogDetailView: View {
    let log: ActionLog
    let repository: ActionLogRepository
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ヘッダー情報
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(log.logType.emoji)
                            .font(.largeTitle)
                        Text(log.logType.displayName)
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    
                    Text(log.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // ログ内容
                VStack(alignment: .leading, spacing: 8) {
                    Text("記録内容")
                        .font(.headline)
                    Text(repository.getSecureContent(for: log))
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // AIフィードバック
                if let feedback = repository.getSecureAIFeedback(for: log) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.blue)
                            Text("AIフィードバック")
                                .font(.headline)
                        }
                        Text(feedback)
                            .font(.body)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
                
                // 防いだカロリー（強調表示）
                if let calories = log.preventedCalories {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("防いだカロリー")
                            .font(.headline)
                        HStack {
                            Image(systemName: "flame.fill")
                                .font(.title)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(calories) kcal")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("節約できました！")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                                )
                        )
                    }
                }
                
                // 感情タグ
                if !log.emotionTags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("感情タグ")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(log.emotionTags, id: \.self) { tag in
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
        .navigationTitle("記録詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

#Preview("LogDetailView") {
    let sampleLog = ActionLog(content: "夜中にアイスクリームを食べたくなったが、水を飲んで我慢した", logType: .success)
    sampleLog.setAIFeedback("素晴らしい自制心です！水を飲むのは良い対策ですね。次回も同じ方法でトライしてみてください。", preventedCalories: 200)
    sampleLog.addEmotionTag("達成感")
    sampleLog.addEmotionTag("安心")
    
    // プレビュー用の仮のRepository
    let container = try! ModelContainer(for: ActionLog.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    let repository = ActionLogRepository(modelContext: context)
    
    return LogDetailView(log: sampleLog, repository: repository)
        .modelContainer(container)
}

/// 設定画面（将来的な拡張用）
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("設定")
                .font(.title)
                .padding()
            
            Text("将来的な機能拡張の準備として作成されました")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

/// 統計画面（将来的な拡張用）
struct StatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("統計")
                .font(.title)
                .padding()
            
            Text("将来的な機能拡張の準備として作成されました")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .navigationTitle("統計")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}

/// チュートリアル画面（将来的な拡張用）
struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("チュートリアル")
                .font(.title)
                .padding()
            
            Text("将来的な機能拡張の準備として作成されました")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .navigationTitle("チュートリアル")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}