//
//  StatsCalculationTests.swift
//  EatLockTests
//
//  Created by AI Assistant on 2025/07/04.
//

import Testing
import Foundation
import SwiftData
@testable import EatLock

struct StatsCalculationTests {
    
    // MARK: - Test Helper Methods
    
    /// テスト用のModelContextを作成
    private func createTestModelContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: ActionLog.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }
    
    /// テスト用のActionLogを作成
    private func createTestActionLog(
        content: String,
        logType: LogType = .other,
        timestamp: Date = Date(),
        preventedCalories: Int? = nil
    ) -> ActionLog {
        let log = ActionLog(content: content, logType: logType)
        log.timestamp = timestamp
        log.preventedCalories = preventedCalories
        return log
    }
    
    // MARK: - Basic Statistics Tests
    
    @Test("空のログリストから統計を計算")
    func testEmptyLogStats() async throws {
        let stats = ActionLog.calculateStats(from: [])
        
        #expect(stats.totalLogs == 0)
        #expect(stats.successLogs == 0)
        #expect(stats.totalPreventedCalories == 0)
        #expect(stats.consecutiveDays == 0)
        #expect(stats.successRate == 0.0)
    }
    
    @Test("単一のログから統計を計算")
    func testSingleLogStats() async throws {
        let log = createTestActionLog(
            content: "テストログ",
            logType: .success,
            preventedCalories: 100
        )
        
        let stats = ActionLog.calculateStats(from: [log])
        
        #expect(stats.totalLogs == 1)
        #expect(stats.successLogs == 1)
        #expect(stats.totalPreventedCalories == 100)
        #expect(stats.consecutiveDays == 1)
        #expect(stats.successRate == 1.0)
    }
    
    @Test("複数のログから統計を計算")
    func testMultipleLogStats() async throws {
        let logs = [
            createTestActionLog(content: "成功ログ1", logType: .success, preventedCalories: 150),
            createTestActionLog(content: "失敗ログ", logType: .failure, preventedCalories: 0),
            createTestActionLog(content: "成功ログ2", logType: .success, preventedCalories: 200),
            createTestActionLog(content: "その他ログ", logType: .other, preventedCalories: 50)
        ]
        
        let stats = ActionLog.calculateStats(from: logs)
        
        #expect(stats.totalLogs == 4)
        #expect(stats.successLogs == 2)
        #expect(stats.totalPreventedCalories == 400)
        #expect(stats.successRate == 0.5)
    }
    
    // MARK: - Consecutive Days Tests
    
    @Test("連続日数の計算 - 今日のみ")
    func testConsecutiveDaysToday() async throws {
        let today = Date()
        let log = createTestActionLog(
            content: "今日のログ",
            timestamp: today
        )
        
        let stats = ActionLog.calculateStats(from: [log])
        
        #expect(stats.consecutiveDays == 1)
    }
    
    @Test("連続日数の計算 - 連続する日")
    func testConsecutiveDaysMultiple() async throws {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        let logs = [
            createTestActionLog(content: "今日のログ", timestamp: today),
            createTestActionLog(content: "昨日のログ", timestamp: yesterday),
            createTestActionLog(content: "一昨日のログ", timestamp: twoDaysAgo)
        ]
        
        let stats = ActionLog.calculateStats(from: logs)
        
        #expect(stats.consecutiveDays == 3)
    }
    
    @Test("連続日数の計算 - 途中で途切れる場合")
    func testConsecutiveDaysWithGap() async throws {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        
        let logs = [
            createTestActionLog(content: "今日のログ", timestamp: today),
            createTestActionLog(content: "昨日のログ", timestamp: yesterday),
            createTestActionLog(content: "3日前のログ", timestamp: threeDaysAgo)
        ]
        
        let stats = ActionLog.calculateStats(from: logs)
        
        #expect(stats.consecutiveDays == 2)
    }
    
    @Test("連続日数の計算 - 今日のログがない場合")
    func testConsecutiveDaysNoTodayLog() async throws {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        
        let log = createTestActionLog(
            content: "昨日のログ",
            timestamp: yesterday
        )
        
        let stats = ActionLog.calculateStats(from: [log])
        
        #expect(stats.consecutiveDays == 0)
    }
    
    // MARK: - Repository Integration Tests
    
    @Test("ActionLogRepositoryの統計計算")
    func testRepositoryStatsCalculation() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        
        // テストデータを作成
        let log1 = try repository.createActionLog(content: "成功ログ", logType: .success)
        log1.preventedCalories = 150
        let log2 = try repository.createActionLog(content: "失敗ログ", logType: .failure)
        
        // 統計を計算
        let stats = try repository.calculateStatistics()
        
        #expect(stats.totalLogs == 2)
        #expect(stats.successLogs == 1)
        #expect(stats.totalPreventedCalories == 150)
        #expect(stats.successRate == 0.5)
    }
    
    @Test("ActionLogRepositoryの今日の統計計算")
    func testRepositoryTodayStatsCalculation() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        
        // 今日のログを作成
        let todayLog = try repository.createActionLog(content: "今日のログ", logType: .success)
        todayLog.preventedCalories = 200
        
        // 昨日のログを作成
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayLog = try repository.createActionLog(content: "昨日のログ", logType: .success)
        yesterdayLog.timestamp = yesterday
        yesterdayLog.preventedCalories = 100
        
        // 今日の統計を計算
        let todayStats = try repository.calculateTodaysStatistics()
        
        #expect(todayStats.totalLogs == 1)
        #expect(todayStats.successLogs == 1)
        #expect(todayStats.totalPreventedCalories == 200)
        #expect(todayStats.successRate == 1.0)
    }
    
    @Test("ActionLogRepositoryの期間指定統計計算")
    func testRepositoryDateRangeStatsCalculation() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        let calendar = Calendar.current
        
        // 異なる日付のログを作成
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        let log1 = try repository.createActionLog(content: "今日のログ", logType: .success)
        log1.timestamp = today
        log1.preventedCalories = 100
        
        let log2 = try repository.createActionLog(content: "昨日のログ", logType: .success)
        log2.timestamp = yesterday
        log2.preventedCalories = 200
        
        let log3 = try repository.createActionLog(content: "一昨日のログ", logType: .failure)
        log3.timestamp = twoDaysAgo
        
        // 昨日から今日までの統計を計算
        let stats = try repository.calculateStatistics(from: yesterday, to: today)
        
        #expect(stats.totalLogs == 2)
        #expect(stats.successLogs == 2)
        #expect(stats.totalPreventedCalories == 300)
        #expect(stats.successRate == 1.0)
    }
    
    // MARK: - Real-time Update Tests
    
    @Test("リアルタイム統計更新 - ログ作成時")
    func testRealTimeStatsUpdateOnCreate() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        
        // 初期状態の確認
        #expect(repository.currentStats.totalLogs == 0)
        
        // ログを作成
        let _ = try repository.createActionLog(content: "テストログ", logType: .success)
        
        // 統計が更新されるまで少し待つ
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 統計が更新されたことを確認
        #expect(repository.currentStats.totalLogs == 1)
        #expect(repository.currentStats.successLogs == 1)
    }
    
    @Test("リアルタイム統計更新 - ログ削除時")
    func testRealTimeStatsUpdateOnDelete() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        
        // ログを作成
        let log = try repository.createActionLog(content: "テストログ", logType: .success)
        
        // 統計が更新されるまで少し待つ
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        #expect(repository.currentStats.totalLogs == 1)
        
        // ログを削除
        try repository.deleteActionLog(log)
        
        // 統計が更新されるまで少し待つ
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 統計が更新されたことを確認
        #expect(repository.currentStats.totalLogs == 0)
        #expect(repository.currentStats.successLogs == 0)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("防いだカロリーがnilの場合")
    func testStatsWithNilPreventedCalories() async throws {
        let logs = [
            createTestActionLog(content: "カロリー不明", logType: .success, preventedCalories: nil),
            createTestActionLog(content: "カロリー設定済み", logType: .success, preventedCalories: 100)
        ]
        
        let stats = ActionLog.calculateStats(from: logs)
        
        #expect(stats.totalLogs == 2)
        #expect(stats.successLogs == 2)
        #expect(stats.totalPreventedCalories == 100)
        #expect(stats.successRate == 1.0)
    }
    
    @Test("負の防いだカロリーの場合")
    func testStatsWithNegativePreventedCalories() async throws {
        let logs = [
            createTestActionLog(content: "負のカロリー", logType: .success, preventedCalories: -50),
            createTestActionLog(content: "正のカロリー", logType: .success, preventedCalories: 100)
        ]
        
        let stats = ActionLog.calculateStats(from: logs)
        
        #expect(stats.totalLogs == 2)
        #expect(stats.successLogs == 2)
        #expect(stats.totalPreventedCalories == 50)
        #expect(stats.successRate == 1.0)
    }
    
    @Test("大量のログでの統計計算")
    func testStatsWithLargeNumberOfLogs() async throws {
        var logs: [ActionLog] = []
        
        // 1000個のログを作成
        for i in 0..<1000 {
            let logType: LogType = i % 2 == 0 ? .success : .failure
            let preventedCalories = logType == .success ? 100 : 0
            logs.append(createTestActionLog(
                content: "ログ\(i)",
                logType: logType,
                preventedCalories: preventedCalories
            ))
        }
        
        let stats = ActionLog.calculateStats(from: logs)
        
        #expect(stats.totalLogs == 1000)
        #expect(stats.successLogs == 500)
        #expect(stats.totalPreventedCalories == 50000)
        #expect(stats.successRate == 0.5)
    }
    
    // MARK: - Performance Tests
    
    @Test("統計計算のパフォーマンステスト")
    func testStatsCalculationPerformance() async throws {
        var logs: [ActionLog] = []
        
        // 10000個のログを作成
        for i in 0..<10000 {
            logs.append(createTestActionLog(
                content: "ログ\(i)",
                logType: .success,
                preventedCalories: 100
            ))
        }
        
        // 実行時間を計測
        let startTime = Date()
        let stats = ActionLog.calculateStats(from: logs)
        let endTime = Date()
        
        let executionTime = endTime.timeIntervalSince(startTime)
        
        // 1秒以内に完了することを確認
        #expect(executionTime < 1.0)
        #expect(stats.totalLogs == 10000)
        #expect(stats.successLogs == 10000)
        #expect(stats.totalPreventedCalories == 1000000)
    }
}