//
//  ActionLogRepository.swift
//  EatLock
//
//  Created by arusu0629 on 2025/06/25.
//

import Foundation
import SwiftData

/// ActionLogのデータアクセスを管理するリポジトリクラス
@Observable
class ActionLogRepository {
    private let modelContext: ModelContext
    private let dataSecurityManager: DataSecurityManager
    private let encryptionKey: Data
    
    // MARK: - Performance Optimization
    private var decryptionCache: [UUID: String] = [:]
    private var aiFeedbackCache: [UUID: String?] = [:]
    private var statsCache: (stats: ActionLogStats, timestamp: Date)?
    private let cacheTimeout: TimeInterval = 30
    private let maxCacheSize = 100
    
    // MARK: - Reactive Properties
    
    /// 現在の統計情報（リアルタイム更新）
    var currentStats: ActionLogStats = ActionLogStats(
        totalLogs: 0,
        successLogs: 0,
        totalPreventedCalories: 0,
        consecutiveDays: 0
    )
    
    /// 今日の統計情報（リアルタイム更新）
    var todaysStats: ActionLogStats = ActionLogStats(
        totalLogs: 0,
        successLogs: 0,
        totalPreventedCalories: 0,
        consecutiveDays: 0
    )
    
    /// 統計情報の更新が必要かどうかを追跡
    private var needsStatsUpdate: Bool = true
    
    /// 統計情報更新のタイマー
    private var statsUpdateTimer: Timer?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.dataSecurityManager = DataSecurityManager.shared
        self.encryptionKey = dataSecurityManager.getDeviceEncryptionKey()
        
        // 初期化時に統計情報を更新（非同期で実行）
        Task.detached(priority: .utility) {
            await self.updateStatistics()
        }
        
        // 統計情報の定期更新タイマー（バックグラウンドで実行）
        setupStatsUpdateTimer()
    }
    
    // MARK: - Statistics Update Methods
    
    /// 統計情報を更新（内部メソッド）
    private func updateStatistics() {
        // 複数のタスクが同時に実行されないように制御
        guard needsStatsUpdate else { return }
        needsStatsUpdate = false
        
        Task { @MainActor in
            do {
                // 全体の統計情報を更新
                let allStats = try calculateStatistics()
                self.currentStats = allStats
                
                // 今日の統計情報を更新
                let todayStats = try calculateTodaysStatistics()
                self.todaysStats = todayStats
                
            } catch {
                print("統計情報の更新に失敗しました: \(error)")
                // エラーの場合は再試行を許可
                self.needsStatsUpdate = true
            }
        }
    }
    
    /// 統計情報を強制的に更新
    public func refreshStatistics() {
        needsStatsUpdate = true
        updateStatistics()
    }
    
    /// 指定期間の統計情報を取得（リアルタイム更新対応）
    public func getStatistics(from startDate: Date, to endDate: Date) async throws -> ActionLogStats {
        return try calculateStatistics(from: startDate, to: endDate)
    }
    
    /// 今日の統計情報を取得（リアルタイム更新対応）
    public func getTodaysStatistics() async throws -> ActionLogStats {
        return try calculateTodaysStatistics()
    }
    
    /// 全体の統計情報を取得（リアルタイム更新対応）
    public func getAllStatistics() async throws -> ActionLogStats {
        return try calculateStatistics()
    }
    
    // MARK: - Create
    
    /// 新しい行動ログを作成（AIフィードバックを自動生成）
    @MainActor
    func createActionLogWithAIFeedback(content: String, logType: LogType = .other) async throws -> ActionLog {
        // 基本的な行動ログを作成
        let actionLog = try createActionLog(content: content, logType: logType)
        
        // AIフィードバックを生成
        await generateAIFeedback(for: actionLog)
        
        return actionLog
    }
    
    /// 新しい行動ログを作成
    func createActionLog(content: String, logType: LogType = .other) throws -> ActionLog {
        // 入力バリデーション
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw ActionLogError.validationFailed("行動ログの内容が空です")
        }
        
        guard trimmedContent.count <= 500 else {
            throw ActionLogError.validationFailed("行動ログの内容が上限（500文字）を超えています")
        }
        
        let actionLog = ActionLog(content: trimmedContent, logType: logType)
        
        // コンテンツを暗号化して、プレーンテキストをクリア
        do {
            let encryptedContent = try dataSecurityManager.encryptString(trimmedContent, using: encryptionKey)
            actionLog.encryptedContent = encryptedContent
            // 暗号化成功後、データベース保存用にプレーンテキストをクリア
            actionLog.content = ""
        } catch {
            // 暗号化に失敗した場合は、エラーをthrowして作成を中断
            throw ActionLogError.encryptionFailed(error)
        }
        
        modelContext.insert(actionLog)
        
        do {
            try modelContext.save()
            // 統計情報を更新
            needsStatsUpdate = true
            updateStatistics()
            return actionLog
        } catch {
            modelContext.rollback()
            throw ActionLogError.createFailed(error)
        }
    }
    
    // MARK: - Read
    
    /// すべての行動ログを取得（新しい順）
    func fetchAllActionLogs() throws -> [ActionLog] {
        let descriptor = FetchDescriptor<ActionLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw ActionLogError.fetchFailed(error)
        }
    }
    
    /// 今日の行動ログを取得
    func fetchTodaysActionLogs() throws -> [ActionLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw ActionLogError.fetchFailed(NSError(domain: "DateCalculationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "日付の計算に失敗しました"]))
        }
        
        let predicate = #Predicate<ActionLog> { log in
            log.timestamp >= startOfDay && log.timestamp < endOfDay
        }
        
        let descriptor = FetchDescriptor<ActionLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw ActionLogError.fetchFailed(error)
        }
    }
    
    /// 指定期間の行動ログを取得
    func fetchActionLogs(from startDate: Date, to endDate: Date) throws -> [ActionLog] {
        let predicate = #Predicate<ActionLog> { log in
            log.timestamp >= startDate && log.timestamp <= endDate
        }
        
        let descriptor = FetchDescriptor<ActionLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw ActionLogError.fetchFailed(error)
        }
    }
    
    /// 特定のログタイプの行動ログを取得
    func fetchActionLogs(ofType logType: LogType) throws -> [ActionLog] {
        let predicate = #Predicate<ActionLog> { log in
            log.logType == logType
        }
        
        let descriptor = FetchDescriptor<ActionLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw ActionLogError.fetchFailed(error)
        }
    }
    
    /// IDで特定の行動ログを取得
    func fetchActionLog(by id: UUID) throws -> ActionLog? {
        let predicate = #Predicate<ActionLog> { log in
            log.id == id
        }
        
        let descriptor = FetchDescriptor<ActionLog>(predicate: predicate)
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            throw ActionLogError.fetchFailed(error)
        }
    }
    
    // MARK: - Update
    
    /// 行動ログの内容を更新
    func updateActionLog(_ actionLog: ActionLog, content: String) throws {
        // 元のデータをバックアップ（保存失敗時の復元用）
        let originalContent = actionLog.content
        let originalEncryptedContent = actionLog.encryptedContent
        let originalUpdatedAt = actionLog.updatedAt
        
        // 先に暗号化を行い、プレーンテキストをクリア
        do {
            let encryptedContent = try dataSecurityManager.encryptString(content, using: encryptionKey)
            actionLog.encryptedContent = encryptedContent
            // 暗号化成功後、データベース保存用にプレーンテキストをクリア
            actionLog.content = ""
            actionLog.updatedAt = Date()
        } catch {
            // 暗号化に失敗した場合は、エラーをthrowして更新を中断
            throw ActionLogError.encryptionFailed(error)
        }
        
        do {
            try modelContext.save()
            // 統計情報を更新
            updateStatistics()
        } catch {
            // 保存失敗時は元のデータを復元
            actionLog.content = originalContent
            actionLog.encryptedContent = originalEncryptedContent
            actionLog.updatedAt = originalUpdatedAt
            modelContext.rollback()
            throw ActionLogError.updateFailed(error)
        }
    }
    
    /// 行動ログにAIフィードバックを設定
    func setAIFeedback(for actionLog: ActionLog, feedback: String, preventedCalories: Int? = nil) throws {
        // 元のデータをバックアップ（保存失敗時の復元用）
        let originalAIFeedback = actionLog.aiFeedback
        let originalEncryptedAIFeedback = actionLog.encryptedAIFeedback
        let originalPreventedCalories = actionLog.preventedCalories
        let originalUpdatedAt = actionLog.updatedAt
        
        // AIフィードバックを暗号化してプレーンテキストをクリア
        do {
            let encryptedFeedback = try dataSecurityManager.encryptString(feedback, using: encryptionKey)
            actionLog.encryptedAIFeedback = encryptedFeedback
            // 暗号化成功後、データベース保存用にプレーンテキストをクリア
            actionLog.aiFeedback = nil
            actionLog.preventedCalories = preventedCalories
            actionLog.updatedAt = Date()
        } catch {
            throw ActionLogError.encryptionFailed(error)
        }
        
        do {
            try modelContext.save()
            // 統計情報を更新
            updateStatistics()
        } catch {
            // 保存失敗時は元のデータを復元
            actionLog.aiFeedback = originalAIFeedback
            actionLog.encryptedAIFeedback = originalEncryptedAIFeedback
            actionLog.preventedCalories = originalPreventedCalories
            actionLog.updatedAt = originalUpdatedAt
            modelContext.rollback()
            throw ActionLogError.updateFailed(error)
        }
    }
    
    /// 行動ログのタイプを更新
    func updateLogType(for actionLog: ActionLog, logType: LogType) throws {
        actionLog.logType = logType
        actionLog.updatedAt = Date()
        
        do {
            try modelContext.save()
            // 統計情報を更新
            updateStatistics()
        } catch {
            modelContext.rollback()
            throw ActionLogError.updateFailed(error)
        }
    }
    
    // MARK: - Delete
    
    /// 特定の行動ログを削除
    func deleteActionLog(_ actionLog: ActionLog) throws {
        modelContext.delete(actionLog)
        
        do {
            try modelContext.save()
            // 統計情報を更新
            updateStatistics()
        } catch {
            modelContext.rollback()
            throw ActionLogError.deleteFailed(error)
        }
    }
    
    /// 複数の行動ログを削除
    func deleteActionLogs(_ actionLogs: [ActionLog]) throws {
        for actionLog in actionLogs {
            modelContext.delete(actionLog)
        }
        
        do {
            try modelContext.save()
            // 統計情報を更新
            updateStatistics()
        } catch {
            modelContext.rollback()
            throw ActionLogError.deleteFailed(error)
        }
    }
    
    /// 指定期間より古い行動ログを削除
    func deleteOldActionLogs(olderThan date: Date) throws {
        let predicate = #Predicate<ActionLog> { log in
            log.timestamp < date
        }
        
        let descriptor = FetchDescriptor<ActionLog>(predicate: predicate)
        
        do {
            let oldLogs = try modelContext.fetch(descriptor)
            try deleteActionLogs(oldLogs)
            // 統計情報を更新
            updateStatistics()
        } catch {
            throw ActionLogError.deleteFailed(error)
        }
    }
    
    // MARK: - Statistics
    
    /// 統計情報を計算
    func calculateStatistics() throws -> ActionLogStats {
        do {
            let allLogs = try fetchAllActionLogs()
            return ActionLog.calculateStats(from: allLogs)
        } catch {
            throw ActionLogError.statisticsCalculationFailed(error)
        }
    }
    
    /// 今日の統計情報を計算
    func calculateTodaysStatistics() throws -> ActionLogStats {
        do {
            let todaysLogs = try fetchTodaysActionLogs()
            return ActionLog.calculateStats(from: todaysLogs)
        } catch {
            throw ActionLogError.statisticsCalculationFailed(error)
        }
    }
    
    /// 期間指定での統計情報を計算
    func calculateStatistics(from startDate: Date, to endDate: Date) throws -> ActionLogStats {
        do {
            let logs = try fetchActionLogs(from: startDate, to: endDate)
            return ActionLog.calculateStats(from: logs)
        } catch {
            throw ActionLogError.statisticsCalculationFailed(error)
        }
    }
    
    // MARK: - AI Feedback Generation
    
    /// ActionLogに対してAIフィードバックを生成
    @MainActor
    func generateAIFeedback(for actionLog: ActionLog) async {
        // 暗号化されたコンテンツを取得
        let content = getSecureContent(for: actionLog)
        
        // AIフィードバックを生成
        let result = await AIManager.shared.generateFeedback(for: content)
        
        switch result {
        case .success(let feedback):
            // AIフィードバックを保存
            do {
                try setAIFeedback(for: actionLog, feedback: feedback.message, preventedCalories: feedback.preventedCalories)
            } catch {
                print("AIフィードバックの保存に失敗しました: \(error)")
            }
        case .failure(let error):
            print("AIフィードバックの生成に失敗しました: \(error)")
        }
    }
    
    /// 複数のActionLogに対してAIフィードバックを一括生成
    @MainActor
    func generateAIFeedbackBatch(for actionLogs: [ActionLog]) async {
        for actionLog in actionLogs {
            await generateAIFeedback(for: actionLog)
            // 連続リクエストを避けるため少し待機
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
    
    /// AIフィードバックが未生成のActionLogを取得
    func fetchActionLogsWithoutAIFeedback() throws -> [ActionLog] {
        let predicate = #Predicate<ActionLog> { log in
            log.aiFeedback == nil && log.encryptedAIFeedback == nil
        }
        
        let descriptor = FetchDescriptor<ActionLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw ActionLogError.fetchFailed(error)
        }
    }
    
    // MARK: - Encryption Support
    
    /// 暗号化されたコンテンツを安全に取得（キャッシュ対応）
    func getSecureContent(for actionLog: ActionLog) -> String {
        // キャッシュから取得を試行
        if let cached = decryptionCache[actionLog.id] {
            return cached
        }
        
        let content = actionLog.getSecureContent(using: encryptionKey) ?? actionLog.content
        
        // キャッシュに保存（サイズ制限付き）
        if decryptionCache.count >= maxCacheSize {
            // 古いエントリを削除
            let oldestKey = decryptionCache.keys.first
            if let key = oldestKey {
                decryptionCache.removeValue(forKey: key)
            }
        }
        decryptionCache[actionLog.id] = content
        
        return content
    }
    
    /// 暗号化されたAIフィードバックを安全に取得（キャッシュ対応）
    func getSecureAIFeedback(for actionLog: ActionLog) -> String? {
        // キャッシュから取得を試行
        if let cached = aiFeedbackCache[actionLog.id] {
            return cached
        }
        
        let feedback = actionLog.getSecureAIFeedback(using: encryptionKey)
        
        // キャッシュに保存（サイズ制限付き）
        if aiFeedbackCache.count >= maxCacheSize {
            // 古いエントリを削除
            let oldestKey = aiFeedbackCache.keys.first
            if let key = oldestKey {
                aiFeedbackCache.removeValue(forKey: key)
            }
        }
        aiFeedbackCache[actionLog.id] = feedback
        
        return feedback
    }
    
    /// 短縮表示用の安全なコンテンツを取得
    func getShortSecureContent(for actionLog: ActionLog) -> String {
        let contentText = getSecureContent(for: actionLog)
        if contentText.count > 30 {
            return String(contentText.prefix(30)) + "..."
        }
        return contentText
    }
    
    /// 複数のActionLogに対して効率的にセキュアコンテンツを取得（並列処理、バッチサイズ制限）
    func getSecureContents(for actionLogs: [ActionLog]) async -> [ActionLog: String] {
        let maxConcurrency = min(actionLogs.count, 10) // 最大10並列に制限
        
        return await withTaskGroup(of: (ActionLog, String).self, returning: [ActionLog: String].self) { group in
            var results: [ActionLog: String] = [:]
            var iterator = actionLogs.makeIterator()
            var activeTasks = 0
            
            // 初期タスクを追加
            while activeTasks < maxConcurrency, let actionLog = iterator.next() {
                group.addTask {
                    return (actionLog, self.getSecureContent(for: actionLog))
                }
                activeTasks += 1
            }
            
            // 結果を処理し、新しいタスクを追加
            for await (actionLog, content) in group {
                results[actionLog] = content
                
                // 次のタスクを追加
                if let nextActionLog = iterator.next() {
                    group.addTask {
                        return (nextActionLog, self.getSecureContent(for: nextActionLog))
                    }
                }
            }
            
            return results
        }
    }
    
    /// 複数のActionLogに対して効率的にセキュアAIフィードバックを取得（並列処理、バッチサイズ制限）
    func getSecureAIFeedbacks(for actionLogs: [ActionLog]) async -> [ActionLog: String?] {
        let maxConcurrency = min(actionLogs.count, 10) // 最大10並列に制限
        
        return await withTaskGroup(of: (ActionLog, String?).self, returning: [ActionLog: String?].self) { group in
            var results: [ActionLog: String?] = [:]
            var iterator = actionLogs.makeIterator()
            var activeTasks = 0
            
            // 初期タスクを追加
            while activeTasks < maxConcurrency, let actionLog = iterator.next() {
                group.addTask {
                    return (actionLog, self.getSecureAIFeedback(for: actionLog))
                }
                activeTasks += 1
            }
            
            // 結果を処理し、新しいタスクを追加
            for await (actionLog, feedback) in group {
                results[actionLog] = feedback
                
                // 次のタスクを追加
                if let nextActionLog = iterator.next() {
                    group.addTask {
                        return (nextActionLog, self.getSecureAIFeedback(for: nextActionLog))
                    }
                }
            }
            
            return results
        }
    }
    
    /// 暗号化キーを取得（デバッグ用）
    func getEncryptionKey() -> Data {
        return encryptionKey
    }
    
    // MARK: - Helper Methods
    
    /// 統計情報更新のタイマーを設定
    private func setupStatsUpdateTimer() {
        statsUpdateTimer?.invalidate()
        statsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.needsStatsUpdate = true
            self.updateStatistics()
        }
    }
    
    /// 全てのキャッシュをクリア
    func clearCache() {
        decryptionCache.removeAll()
        aiFeedbackCache.removeAll()
        statsCache = nil
    }
    
    /// 統計情報キャッシュを無効化
    func invalidateStatsCache() {
        statsCache = nil
    }
    
    // MARK: - Feedback History Management
    
    /// フィードバック履歴を持つActionLogを取得
    func fetchActionLogsWithFeedback() throws -> [ActionLog] {
        let predicate = #Predicate<ActionLog> { log in
            log.aiFeedback != nil || log.encryptedAIFeedback != nil
        }
        
        let descriptor = FetchDescriptor<ActionLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw ActionLogError.fetchFailed(error)
        }
    }
    
    /// 指定期間のフィードバック履歴を取得
    func fetchFeedbackHistory(from startDate: Date, to endDate: Date) throws -> [ActionLog] {
        let predicate = #Predicate<ActionLog> { log in
            log.timestamp >= startDate && log.timestamp <= endDate && (log.aiFeedback != nil || log.encryptedAIFeedback != nil)
        }
        
        let descriptor = FetchDescriptor<ActionLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw ActionLogError.fetchFailed(error)
        }
    }
    
    /// 今日のフィードバック履歴を取得
    func fetchTodaysFeedbackHistory() throws -> [ActionLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try fetchFeedbackHistory(from: startOfDay, to: endOfDay)
    }
    
    /// 防いだカロリーが記録されているフィードバック履歴を取得
    func fetchFeedbackHistoryWithCalories() throws -> [ActionLog] {
        let predicate = #Predicate<ActionLog> { log in
            log.preventedCalories != nil && log.preventedCalories! > 0
        }
        
        let descriptor = FetchDescriptor<ActionLog>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw ActionLogError.fetchFailed(error)
        }
    }
    
    deinit {
        // タイマーを無効化してメモリリークを防止
        statsUpdateTimer?.invalidate()
        statsUpdateTimer = nil
    }
}

// MARK: - ActionLogError
enum ActionLogError: LocalizedError {
    case createFailed(Error)
    case fetchFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case statisticsCalculationFailed(Error)
    case encryptionFailed(Error)
    case validationFailed(String)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .createFailed(let error):
            return "行動ログの作成に失敗しました: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "行動ログの取得に失敗しました: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "行動ログの更新に失敗しました: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "行動ログの削除に失敗しました: \(error.localizedDescription)"
        case .statisticsCalculationFailed(let error):
            return "統計情報の計算に失敗しました: \(error.localizedDescription)"
        case .encryptionFailed(let error):
            return "データの暗号化に失敗しました: \(error.localizedDescription)"
        case .validationFailed(let message):
            return message
        case .notFound:
            return "指定された行動ログが見つかりません"
        }
    }
} 