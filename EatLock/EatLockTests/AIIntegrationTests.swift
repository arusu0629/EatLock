import XCTest
import SwiftData
@testable import EatLock

/// AIフィードバック機能とActionLogRepositoryの統合テスト
@MainActor
final class AIIntegrationTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: ActionLogRepository!
    var aiManager: AIManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // テスト用のモデルコンテナを作成
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: ActionLog.self, configurations: config)
        modelContext = modelContainer.mainContext
        
        // リポジトリとAIマネージャーを初期化
        repository = ActionLogRepository(modelContext: modelContext)
        aiManager = AIManager.shared
    }
    
    override func tearDownWithError() throws {
        repository = nil
        aiManager = nil
        modelContainer = nil
        modelContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Test Utilities
    
    private func setupAI() async throws {
        await aiManager.initialize()
        
        // AI初期化の検証
        guard aiManager.isInitialized else {
            throw XCTestError(.failureWhileWaiting, userInfo: [
                "description": "AI initialization failed in integration test - cannot proceed"
            ])
        }
    }
    
    // MARK: - Integration Tests
    
    func testCreateActionLogWithAIFeedback() async throws {
        // AIフィードバック付きでActionLogを作成するテスト
        try await setupAI()
        
        let content = "今日はチョコレートケーキを我慢しました"
        let actionLog = try await repository.createActionLogWithAIFeedback(content: content, logType: .success)
        
        XCTAssertNotNil(actionLog, "ActionLog should be created")
        XCTAssertEqual(actionLog.logType, .success, "LogType should be success")
        
        // 暗号化されたコンテンツを確認
        let decryptedContent = repository.getSecureContent(for: actionLog)
        XCTAssertEqual(decryptedContent, content, "Decrypted content should match original: '\(content)'")
        
        // AIフィードバックが生成されているかを確認
        let aiFeedback = repository.getSecureAIFeedback(for: actionLog)
        XCTAssertNotNil(aiFeedback, "AI feedback should be generated for content: '\(content)'")
        XCTAssertFalse(aiFeedback?.isEmpty ?? true, "AI feedback should not be empty")
        
        // カロリー計算が正しく行われているかを確認
        XCTAssertNotNil(actionLog.preventedCalories, "Prevented calories should be calculated")
        XCTAssertGreaterThan(actionLog.preventedCalories ?? 0, 0, "Prevented calories should be positive for success log")
    }
    
    func testManualAIFeedbackGeneration() async throws {
        // 手動でAIフィードバックを生成するテスト
        try await setupAI()
        
        // 基本的なActionLogを作成
        let content = "深夜にアイスクリームを我慢しました"
        let actionLog = try repository.createActionLog(content: content, logType: .success)
        
        // 手動でAIフィードバックを生成
        await repository.generateAIFeedback(for: actionLog)
        
        // フィードバックが保存されているかを確認
        let aiFeedback = repository.getSecureAIFeedback(for: actionLog)
        XCTAssertNotNil(aiFeedback, "AI feedback should be generated for manual request")
        XCTAssertFalse(aiFeedback?.isEmpty ?? true, "AI feedback should not be empty")
        
        // 深夜食の場合、カロリーが500以上になっているかを確認
        XCTAssertNotNil(actionLog.preventedCalories, "Prevented calories should be calculated for late night eating")
        XCTAssertGreaterThanOrEqual(actionLog.preventedCalories ?? 0, 500, 
                                   "Late night eating should have at least 500 calories, got: \(actionLog.preventedCalories ?? 0)")
    }
    
    func testBatchAIFeedbackGeneration() async throws {
        // 複数のActionLogに対してAIフィードバックを一括生成するテスト
        try await setupAI()
        
        let testContents = [
            "今日はお菓子を我慢しました",
            "ジュースを控えました",
            "揚げ物を断りました",
            "深夜にラーメンを我慢しました",
            "ストレスでイライラしています"
        ]
        
        // 複数のActionLogを作成
        var actionLogs: [ActionLog] = []
        for (index, content) in testContents.enumerated() {
            let actionLog = try repository.createActionLog(content: content, logType: .success)
            actionLogs.append(actionLog)
        }
        
        XCTAssertEqual(actionLogs.count, testContents.count, "All action logs should be created")
        
        // 一括でAIフィードバックを生成
        await repository.generateAIFeedbackBatch(for: actionLogs)
        
        // すべてのログにフィードバックが生成されているかを確認
        for (index, actionLog) in actionLogs.enumerated() {
            let aiFeedback = repository.getSecureAIFeedback(for: actionLog)
            XCTAssertNotNil(aiFeedback, "AI feedback should be generated for log \(index): '\(testContents[index])'")
            XCTAssertFalse(aiFeedback?.isEmpty ?? true, "AI feedback should not be empty for log \(index)")
        }
    }
    
    func testFeedbackGenerationWithEmotionalTrigger() async throws {
        // 感情的トリガーのあるログに対するフィードバック生成テスト
        try await setupAI()
        
        let emotionalContent = "ストレスでイライラして食べ過ぎました"
        let actionLog = try await repository.createActionLogWithAIFeedback(content: emotionalContent, logType: .failure)
        
        // フィードバックが生成されているかを確認
        let aiFeedback = repository.getSecureAIFeedback(for: actionLog)
        XCTAssertNotNil(aiFeedback, "AI feedback should be generated for emotional content")
        
        // サポートメッセージが含まれているかを確認
        let supportKeywords = ["理解", "大丈夫", "無理せず", "優しく", "感情"]
        let containsSupportKeyword = supportKeywords.contains { keyword in
            aiFeedback?.lowercased().contains(keyword.lowercased()) ?? false
        }
        XCTAssertTrue(containsSupportKeyword, 
                     "Support message should be generated for emotional triggers. Message: '\(aiFeedback ?? "nil")'")
        
        // 感情的トリガーの場合、カロリーは0になることを確認
        XCTAssertEqual(actionLog.preventedCalories ?? -1, 0, 
                      "Emotional trigger should have 0 prevented calories, got: \(actionLog.preventedCalories ?? -1)")
    }
    
    func testStatisticsUpdateWithAIFeedback() async throws {
        // AIフィードバック付きログ作成後の統計情報更新テスト
        try await setupAI()
        
        let initialStats = try await repository.getAllStatistics()
        
        // 成功ログを作成
        let successContent = "今日はケーキを我慢しました"
        let successLog = try await repository.createActionLogWithAIFeedback(content: successContent, logType: .success)
        
        // 統計情報を更新
        repository.refreshStatistics()
        
        let updatedStats = try await repository.getAllStatistics()
        
        // 統計情報が更新されているかを確認
        XCTAssertEqual(updatedStats.totalLogs, initialStats.totalLogs + 1, 
                      "Total logs should increase by 1 (from \(initialStats.totalLogs) to \(updatedStats.totalLogs))")
        XCTAssertEqual(updatedStats.successLogs, initialStats.successLogs + 1, 
                      "Success logs should increase by 1 (from \(initialStats.successLogs) to \(updatedStats.successLogs))")
        XCTAssertGreaterThan(updatedStats.totalPreventedCalories, initialStats.totalPreventedCalories, 
                           "Total prevented calories should increase (from \(initialStats.totalPreventedCalories) to \(updatedStats.totalPreventedCalories))")
    }
    
    func testFeedbackGenerationWithDifferentLogTypes() async throws {
        // 異なるログタイプに対するフィードバック生成テスト
        try await setupAI()
        
        let testCases = [
            ("success", "今日はお菓子を我慢しました", LogType.success),
            ("failure", "ストレスでお菓子を食べてしまいました", LogType.failure),
            ("struggle", "お菓子を食べたい気持ちと戦っています", LogType.struggle),
            ("other", "今日の食事について記録します", LogType.other)
        ]
        
        for (description, content, logType) in testCases {
            let actionLog = try await repository.createActionLogWithAIFeedback(content: content, logType: logType)
            
            // フィードバックが生成されているかを確認
            let aiFeedback = repository.getSecureAIFeedback(for: actionLog)
            XCTAssertNotNil(aiFeedback, "AI feedback should be generated for \(description)")
            XCTAssertFalse(aiFeedback?.isEmpty ?? true, "AI feedback should not be empty for \(description)")
        }
    }
    
    func testEncryptionAndDecryption() async throws {
        // 暗号化と復号化のテスト
        try await setupAI()
        
        let originalContent = "秘密の内容：今日はアイスクリームを我慢しました"
        let actionLog = try await repository.createActionLogWithAIFeedback(content: originalContent, logType: .success)
        
        // 暗号化されたコンテンツが設定されているかを確認
        XCTAssertNotNil(actionLog.encryptedContent, "Encrypted content should be set")
        XCTAssertTrue(actionLog.content.isEmpty, "Plain text content should be cleared")
        
        // 復号化が正しく行われるかを確認
        let decryptedContent = repository.getSecureContent(for: actionLog)
        XCTAssertEqual(decryptedContent, originalContent, "Decrypted content should match original")
        
        // AIフィードバックも暗号化されているかを確認
        XCTAssertNotNil(actionLog.encryptedAIFeedback, "Encrypted AI feedback should be set")
        XCTAssertNil(actionLog.aiFeedback, "Plain text AI feedback should be cleared")
        
        // AIフィードバックの復号化が正しく行われるかを確認
        let decryptedFeedback = repository.getSecureAIFeedback(for: actionLog)
        XCTAssertNotNil(decryptedFeedback, "AI feedback should be decrypted")
        XCTAssertFalse(decryptedFeedback?.isEmpty ?? true, "Decrypted AI feedback should not be empty")
    }
    
    func testWithoutAIFeedbackQuery() async throws {
        // AIフィードバック未生成のログを取得するテスト
        try await setupAI()
        
        // 基本的なActionLogを作成（AIフィードバックなし）
        let actionLog1 = try repository.createActionLog(content: "テスト1", logType: .success)
        let actionLog2 = try repository.createActionLog(content: "テスト2", logType: .success)
        
        // AIフィードバック付きのActionLogを作成
        let _ = try await repository.createActionLogWithAIFeedback(content: "テスト3", logType: .success)
        
        // AIフィードバック未生成のログを取得
        let logsWithoutFeedback = try repository.fetchActionLogsWithoutAIFeedback()
        
        // 2つのログが取得されることを確認
        XCTAssertEqual(logsWithoutFeedback.count, 2, "Should find 2 logs without AI feedback")
        
        // 正しいログが取得されているかを確認
        let logIds = logsWithoutFeedback.map { $0.id }
        XCTAssertTrue(logIds.contains(actionLog1.id), "Should contain actionLog1")
        XCTAssertTrue(logIds.contains(actionLog2.id), "Should contain actionLog2")
    }
    
    func testPerformanceWithLargeDataset() async throws {
        // 大量データでのパフォーマンステスト
        try await setupAI()
        
        let numberOfLogs = 50
        var actionLogs: [ActionLog] = []
        
        // 大量のログを作成
        for i in 0..<numberOfLogs {
            let content = "テストログ\(i)：今日はお菓子を我慢しました"
            let actionLog = try repository.createActionLog(content: content, logType: .success)
            actionLogs.append(actionLog)
        }
        
        // バッチ処理でAIフィードバックを生成
        let startTime = Date()
        await repository.generateAIFeedbackBatch(for: actionLogs)
        let endTime = Date()
        
        let processingTime = endTime.timeIntervalSince(startTime)
        print("Processing time for \(numberOfLogs) logs: \(processingTime) seconds")
        
        // すべてのログにフィードバックが生成されているかを確認
        for actionLog in actionLogs {
            let aiFeedback = repository.getSecureAIFeedback(for: actionLog)
            XCTAssertNotNil(aiFeedback, "AI feedback should be generated for all logs")
        }
        
        // 処理時間が妥当な範囲内かを確認（1ログあたり最大1秒）
        XCTAssertLessThan(processingTime, Double(numberOfLogs), "Processing should be efficient")
    }
}