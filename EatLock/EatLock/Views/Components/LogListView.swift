//
//  LogListView.swift
//  EatLock
//
//  Created by AI Assistant on 2025/07/03.
//

import SwiftUI

struct LogListView: View {
    let actionLogs: [ActionLog]
    let repository: ActionLogRepository
    let onDelete: (IndexSet) -> Void
    private let router = NavigationRouter.shared
    
    // 日付でグループ化されたログ
    private var groupedLogs: [(date: Date, logs: [ActionLog])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: actionLogs) { log in
            calendar.startOfDay(for: log.timestamp)
        }
        
        return grouped.map { (key, value) in
            (date: key, logs: value.sorted { $0.timestamp > $1.timestamp })
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        if actionLogs.isEmpty {
            // 空状態の表示
            VStack(spacing: 16) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("まだログがありません")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("下の入力欄から行動ログを記録してみましょう")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 200)
            .accessibilityLabel("行動ログが空です。下の入力欄から記録を開始してください。")
        } else {
            List {
                ForEach(groupedLogs, id: \.date) { group in
                    Section {
                        ForEach(group.logs) { log in
                            ActionLogRow(log: log, repository: repository)
                                .onTapGesture {
                                    router.presentSheet(.logDetail(log))
                                }
                                .accessibilityLabel(actionLogAccessibilityLabel(for: log))
                        }
                        .onDelete { indexSet in
                            // 特定の日付グループ内での削除に対応
                            let logsToDelete = indexSet.map { group.logs[$0] }
                            let globalIndices = IndexSet(logsToDelete.compactMap { logToDelete in
                                actionLogs.firstIndex(where: { $0.id == logToDelete.id })
                            })
                            onDelete(globalIndices)
                        }
                    } header: {
                        DateHeaderView(date: group.date)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .accessibilityLabel("行動ログ一覧")
        }
    }
    
    // MARK: - Accessibility Helper
    private func actionLogAccessibilityLabel(for log: ActionLog) -> String {
        let content = repository.getSecureContent(for: log)
        let timeString = DateFormatter.timeFormatter.string(from: log.timestamp)
        var label = "\(log.logType.displayName)のログ、\(timeString)、\(content)"
        
        if let calories = log.preventedCalories {
            label += "、\(calories)キロカロリー防止"
        }
        
        if let feedback = repository.getSecureAIFeedback(for: log) {
            label += "、AIフィードバック: \(feedback)"
        }
        
        return label
    }
}

// MARK: - DateHeaderView Component
struct DateHeaderView: View {
    let date: Date
    
    var body: some View {
        HStack {
            Text(formattedDate)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(dayOfWeek)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityLabel("\(formattedDate), \(dayOfWeek)")
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "今日"
        } else if calendar.isDateInYesterday(date) {
            return "昨日"
        } else {
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - ActionLogRow Component
struct ActionLogRow: View {
    let log: ActionLog
    let repository: ActionLogRepository
    
    var body: some View {
        HStack(spacing: 12) {
            // アイコン
            Text(log.logType.emoji)
                .font(.title2)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color(.systemGray6))
                )
            
            // メインコンテンツ
            VStack(alignment: .leading, spacing: 4) {
                // 時刻とカロリー情報
                HStack {
                    Text(timeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let calories = log.preventedCalories {
                        Text("\(calories) kcal")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                
                // ログ内容
                Text(repository.getSecureContent(for: log))
                    .font(.body)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // AIフィードバック
                if let feedback = repository.getSecureAIFeedback(for: log) {
                    Text(feedback)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // タップ領域を全体に拡張
    }
    
    private var timeString: String {
        DateFormatter.timeFormatter.string(from: log.timestamp)
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

#Preview {
    let sampleLogs = [
        ActionLog(content: "夜中にアイスクリームを食べたくなったが、水を飲んで我慢した", logType: .success),
        ActionLog(content: "お昼にデザートを我慢できなかった", logType: .failure),
        ActionLog(content: "今とてもポテトチップスが食べたい", logType: .struggle),
        ActionLog(content: "朝食後のデザートをやめることができた", logType: .success),
        ActionLog(content: "友達とのランチで食べ過ぎてしまった", logType: .failure)
    ]
    
    // 異なる日付を設定してグループ化をテスト
    let calendar = Calendar.current
    sampleLogs[0].timestamp = Date() // 今日
    sampleLogs[1].timestamp = Date() // 今日
    sampleLogs[2].timestamp = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date() // 昨日
    sampleLogs[3].timestamp = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date() // 昨日
    sampleLogs[4].timestamp = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date() // 一昨日
    
    // サンプルデータにAIフィードバックを追加
    sampleLogs[0].setAIFeedback("素晴らしい自制心です！水を飲むのは良い方法ですね。", preventedCalories: 200)
    sampleLogs[1].setAIFeedback("大丈夫です。次回は必ず成功しましょう！")
    sampleLogs[2].setAIFeedback("その気持ちはよく分かります。深呼吸をしてみましょう。")
    sampleLogs[3].setAIFeedback("朝からとても良いスタートですね！", preventedCalories: 150)
    sampleLogs[4].setAIFeedback("友達との時間も大切です。バランスを取りながら頑張りましょう。")
    
    // プレビュー用の仮のRepository
    let container = try! ModelContainer(for: ActionLog.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    let repository = ActionLogRepository(modelContext: context)
    
    return LogListView(
        actionLogs: sampleLogs,
        repository: repository,
        onDelete: { _ in
            print("Delete action triggered")
        }
    )
    .padding()
}