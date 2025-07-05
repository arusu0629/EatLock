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
    @State private var router = NavigationRouter.shared
    
    var body: some View {
        List {
            ForEach(actionLogs) { log in
                ActionLogRow(log: log, repository: repository)
                    .onTapGesture {
                        router.presentSheet(.logDetail(log))
                    }
            }
            .onDelete(perform: onDelete)
        }
    }
}

// MARK: - ActionLogRow Component
struct ActionLogRow: View {
    let log: ActionLog
    let repository: ActionLogRepository
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(log.logType.emoji)
                Text(log.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let calories = log.preventedCalories {
                    Text("\(calories) kcal")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Text(repository.getSecureContent(for: log))
                .font(.body)
            
            if let feedback = repository.getSecureAIFeedback(for: log) {
                Text(feedback)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // タップ領域を全体に拡張
    }
}

#Preview {
    let sampleLogs = [
        ActionLog(content: "夜中にアイスクリームを食べたくなったが、水を飲んで我慢した", logType: .success),
        ActionLog(content: "お昼にデザートを我慢できなかった", logType: .failure),
        ActionLog(content: "今とてもポテトチップスが食べたい", logType: .struggle)
    ]
    
    // サンプルデータにAIフィードバックを追加
    sampleLogs[0].setAIFeedback("素晴らしい自制心です！", preventedCalories: 200)
    sampleLogs[1].setAIFeedback("大丈夫です。次回は必ず成功しましょう！")
    sampleLogs[2].setAIFeedback("その気持ちはよく分かります。深呼吸をしてみましょう。")
    
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
}