//
//  ActionLog.swift
//  EatLock
//
//  Created by arusu0629 on 2025/06/25.
//

import Foundation
import SwiftData

@Model
final class ActionLog {
    /// 行動ログのID（UUID）
    var id: UUID
    
    /// 行動ログのテキスト内容
    var content: String
    
    /// 暗号化されたコンテンツ（セキュリティ強化用）
    var encryptedContent: Data?
    
    /// 暗号化されたAIフィードバック（セキュリティ強化用）
    var encryptedAIFeedback: Data?
    
    /// 記録日時
    var timestamp: Date
    
    /// AIフィードバック内容
    var aiFeedback: String?
    
    /// 推定防止カロリー数
    var preventedCalories: Int?
    
    /// ログの種類（成功/失敗/その他）
    var logType: LogType
    
    /// 感情タグ（将来の拡張用）
    var emotionTags: [String]
    
    /// 作成日時（統計用）
    var createdAt: Date
    
    /// 更新日時
    var updatedAt: Date
    
    init(content: String, logType: LogType = .other) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.logType = logType
        self.emotionTags = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// ログの更新
    func updateContent(_ newContent: String) {
        self.content = newContent
        self.updatedAt = Date()
    }
    
    /// AIフィードバックの設定
    func setAIFeedback(_ feedback: String, preventedCalories: Int? = nil) {
        self.aiFeedback = feedback
        self.preventedCalories = preventedCalories
        self.updatedAt = Date()
    }
    
    /// 感情タグの追加
    func addEmotionTag(_ tag: String) {
        if !emotionTags.contains(tag) {
            emotionTags.append(tag)
            updatedAt = Date()
        }
    }
    
    /// 感情タグの削除
    func removeEmotionTag(_ tag: String) {
        emotionTags.removeAll { $0 == tag }
        updatedAt = Date()
    }
    
    /// 日付のフォーマット（表示用）
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: timestamp)
    }
    
    /// 短縮表示用のコンテンツ
    /// 注意: パフォーマンス問題のため、Repository経由での取得を推奨
    var shortContent: String {
        let contentText = secureContent
        if contentText.count > 30 {
            return String(contentText.prefix(30)) + "..."
        }
        return contentText
    }
    
    /// 今日のログかどうか
    var isToday: Bool {
        Calendar.current.isDateInToday(timestamp)
    }
    
    /// 成功ログかどうか
    var isSuccess: Bool {
        logType == .success
    }
    
    /// 暗号化されたコンテンツを復号化してセキュアなコンテンツを取得
    func getSecureContent(using key: Data) -> String? {
        guard let encryptedContent = encryptedContent else {
            return content // 暗号化されていない場合は通常のコンテンツを返す
        }
        
        do {
            return try DataSecurityManager.shared.decryptData(encryptedContent, using: key)
        } catch {
            print("復号化に失敗しました: \(error)")
            // 復号化に失敗した場合はプレーンテキストにフォールバック
            return content.isEmpty ? "復号化に失敗しました" : content
        }
    }
    
    /// 暗号化キーを使用してコンテンツを取得するコンピューテッドプロパティ
    /// 注意: パフォーマンス問題のため、Repository経由での取得を推奨
    var secureContent: String {
        // レガシーサポート: 直接アクセス時のフォールバック
        if let encryptedContent = encryptedContent {
            // 暗号化データがある場合は、データアクセス問題を防ぐため復号化を試行しない
            return "暗号化データ（Repository経由でアクセスしてください）"
        }
        return content // 暗号化されていない古いデータのみ表示
    }
    
    /// 暗号化されたAIフィードバックを復号化して取得
    func getSecureAIFeedback(using key: Data) -> String? {
        guard let encryptedAIFeedback = encryptedAIFeedback else {
            return aiFeedback // 暗号化されていない場合は通常のフィードバックを返す
        }
        
        do {
            return try DataSecurityManager.shared.decryptData(encryptedAIFeedback, using: key)
        } catch {
            print("AIフィードバックの復号化に失敗しました: \(error)")
            // 復号化に失敗した場合はプレーンテキストにフォールバック
            return (aiFeedback?.isEmpty != false) ? "復号化に失敗しました" : aiFeedback
        }
    }
    
    /// 暗号化キーを使用してAIフィードバックを取得するコンピューテッドプロパティ
    /// 注意: パフォーマンス問題のため、Repository経由での取得を推奨
    var secureAIFeedback: String? {
        // レガシーサポート: 直接アクセス時のフォールバック
        if let encryptedAIFeedback = encryptedAIFeedback {
            // 暗号化データがある場合は、データアクセス問題を防ぐため復号化を試行しない
            return "暗号化データ（Repository経由でアクセスしてください）"
        }
        return aiFeedback // 暗号化されていない古いデータのみ表示
    }
}

// MARK: - LogType Enum
enum LogType: String, CaseIterable, Codable {
    case success = "success"      // 暴飲暴食を防いだ
    case failure = "failure"      // 暴飲暴食してしまった
    case struggle = "struggle"    // 我慢中・葛藤中
    case other = "other"          // その他
    
    var displayName: String {
        switch self {
        case .success:
            return "成功"
        case .failure:
            return "失敗"
        case .struggle:
            return "葛藤中"
        case .other:
            return "その他"
        }
    }
    
    var emoji: String {
        switch self {
        case .success:
            return "✅"
        case .failure:
            return "❌"
        case .struggle:
            return "💪"
        case .other:
            return "📝"
        }
    }
}

// MARK: - ActionLog Extensions
extension ActionLog {
    /// 統計計算用の便利メソッド
    static func calculateStats(from logs: [ActionLog]) -> ActionLogStats {
        let totalLogs = logs.count
        let successLogs = logs.filter { $0.logType == .success }.count
        let totalPreventedCalories = logs.compactMap { $0.preventedCalories }.reduce(0, +)
        
        // 継続日数の計算（今日から遡って連続でログがある日数）
        let consecutiveDays = calculateConsecutiveDays(from: logs)
        
        return ActionLogStats(
            totalLogs: totalLogs,
            successLogs: successLogs,
            totalPreventedCalories: totalPreventedCalories,
            consecutiveDays: consecutiveDays
        )
    }
    
    /// 連続日数の計算
    private static func calculateConsecutiveDays(from logs: [ActionLog]) -> Int {
        let calendar = Calendar.current
        let today = Date()
        var consecutiveDays = 0
        var currentDate = today
        
        // 日付でグループ化
        let logsByDate = Dictionary(grouping: logs) { log in
            calendar.startOfDay(for: log.timestamp)
        }
        
        // 今日から遡って連続日数をカウント
        while let _ = logsByDate[calendar.startOfDay(for: currentDate)] {
            consecutiveDays += 1
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDate
        }
        
        return consecutiveDays
    }
}

// MARK: - ActionLogStats Struct
struct ActionLogStats {
    let totalLogs: Int
    let successLogs: Int
    let totalPreventedCalories: Int
    let consecutiveDays: Int
    
    var successRate: Double {
        guard totalLogs > 0 else { return 0.0 }
        return Double(successLogs) / Double(totalLogs)
    }
} 