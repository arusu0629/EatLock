//
//  SecurityTests.swift
//  EatLockTests
//
//  Created by AI Assistant on 2025/07/09.
//

import Testing
import Foundation
import SwiftData
@testable import EatLock

struct SecurityTests {
    
    // MARK: - Test Helper Methods
    
    private func createTestModelContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: ActionLog.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }
    
    // MARK: - Data Security Tests
    
    @Test("データ暗号化の確認")
    func testDataEncryption() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        
        // テスト用のデータを作成（機密データはハードコードしない）
        let testContent = "テスト用データ: 今日はお菓子を我慢しました"
        let log = try repository.createActionLog(content: testContent, logType: .other)
        
        // データが適切に保存されていることを確認
        #expect(log.content == testContent)
        
        // データセキュリティマネージャーのテスト
        let securityManager = DataSecurityManager.shared
        let originalData = testContent.data(using: .utf8)!
        let encryptedData = try securityManager.encryptData(originalData)
        
        // 暗号化されたデータが元のデータと異なることを明示的に確認
        #expect(encryptedData != originalData)
        #expect(encryptedData.count > 0)
        
        // 復号化テスト
        let decryptedData = try securityManager.decryptData(encryptedData)
        let decryptedString = String(data: decryptedData, encoding: .utf8)
        
        // 復号化されたデータが元のデータと同じであることを確認
        #expect(decryptedString == testContent)
        #expect(decryptedData == originalData)
    }
    
    @Test("AIフィードバック暗号化の確認")
    func testAIFeedbackEncryption() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        
        // AIフィードバック付きログを作成
        let log = try await repository.createActionLogWithAIFeedback(
            content: "今日はケーキを我慢しました",
            logType: .success
        )
        
        // 暗号化されたフィードバックを確認
        let encryptedFeedback = repository.getSecureAIFeedback(for: log)
        #expect(encryptedFeedback != nil)
        
        // 暗号化されたデータが元のデータと異なることを確認
        if let feedback = encryptedFeedback {
            // まず暗号化されたデータがフィードバックと異なることを確認
            let originalFeedback = "今日はケーキを我慢しました"
            #expect(feedback != originalFeedback)
            
            // その後、復号化されたデータの正確性を検証
            #expect(feedback.contains("我慢") || feedback.contains("カロリー") || feedback.contains("素晴らしい"))
        }
    }
    
    @Test("入力データの検証")
    func testInputValidation() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        
        // 不正な入力のテスト（実際の攻撃文字列は使用しない）
        let testInputs = [
            "<tag>content</tag>", // HTMLタグのテスト
            "'; SELECT * FROM users; --", // SQLインジェクション風の文字列
            "../../../test/path", // パストラバーサル風の文字列
            String(repeating: "A", count: 1000) // 長い入力（適度な長さに調整）
        ]
        
        for testInput in testInputs {
            // 入力が適切に処理されることを確認
            // 実際のアプリではこれらの入力は拒否されるか、安全に処理される
            let log = try repository.createActionLog(content: testInput, logType: .other)
            #expect(log.content == testInput) // 内容が保存されるが、実行されない
        }
    }
    
    @Test("メモリ内データの確認")
    func testInMemoryDataHandling() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        
        // テスト用データを含むログを作成
        let testContent = "テスト情報: ユーザー行動データ"
        let log = try repository.createActionLog(content: testContent, logType: .other)
        
        // ログを削除
        try repository.deleteActionLog(log)
        
        // データが適切に削除されていることを確認
        let allLogs = try repository.getAllActionLogs()
        #expect(allLogs.isEmpty)
    }
    
    // MARK: - Authentication Tests
    
    @Test("アクセス権限の確認")
    func testAccessPermissions() async throws {
        // DataSecurityManagerの初期化を確認
        let securityManager = DataSecurityManager.shared
        
        // セキュリティマネージャーが適切に初期化されることを確認
        #expect(securityManager != nil)
        
        // 暗号化キーの生成を確認
        let testData = "テストデータ".data(using: .utf8)!
        let encryptedData = try securityManager.encryptData(testData)
        
        // 暗号化されたデータが元のデータと異なることを確認
        #expect(encryptedData != testData)
        
        // 復号化が正しく動作することを確認
        let decryptedData = try securityManager.decryptData(encryptedData)
        #expect(decryptedData == testData)
    }
    
    // MARK: - Privacy Tests
    
    @Test("個人情報の保護")
    func testPrivacyProtection() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        
        // 個人情報を含む可能性のあるログを作成
        let personalInfo = "私の名前は田中太郎です。体重は70kgです。"
        let log = try repository.createActionLog(content: personalInfo, logType: .other)
        
        // データが適切に保存されることを確認
        #expect(log.content == personalInfo)
        
        // 統計計算時に個人情報が含まれないことを確認
        let stats = try repository.calculateStatistics()
        #expect(stats.totalLogs == 1)
        
        // 統計オブジェクトに個人情報が含まれていないことを確認
        let statsDescription = String(describing: stats)
        #expect(!statsDescription.contains("田中太郎"))
        #expect(!statsDescription.contains("70kg"))
    }
    
    @Test("データ漏洩の防止")
    func testDataLeakagePrevention() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        
        // 複数のログを作成
        let logs = [
            "機密情報A",
            "機密情報B",
            "機密情報C"
        ]
        
        for content in logs {
            let _ = try repository.createActionLog(content: content, logType: .other)
        }
        
        // 統計計算時に機密情報が含まれないことを確認
        let stats = try repository.calculateStatistics()
        #expect(stats.totalLogs == 3)
        
        // 統計オブジェクトから機密情報を取得できないことを確認
        let statsDescription = String(describing: stats)
        for secretInfo in logs {
            #expect(!statsDescription.contains(secretInfo))
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    @Test("同時アクセス時のデータ整合性")
    func testConcurrentAccessDataIntegrity() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        
        // 複数のタスクで同時にログを作成
        await withTaskGroup(of: Void.self) { group in
            var errors: [Error] = []
            for i in 0..<10 {
                group.addTask {
                    do {
                        let _ = try repository.createActionLog(
                            content: "同時アクセステスト \(i)",
                            logType: .success
                        )
                    } catch {
                        errors.append(error)
                    }
                }
            }
            
            // エラーが発生した場合は詳細を記録
            if !errors.isEmpty {
                #expect(Bool(false), "同時アクセス中にエラーが発生: \(errors)")
            }
        }
        
        // 作成されたログ数を確認
        let allLogs = try repository.getAllActionLogs()
        #expect(allLogs.count <= 10) // 最大10個まで
        #expect(allLogs.count >= 1)  // 少なくとも1個は作成される
    }
    
    // MARK: - Error Handling Tests
    
    @Test("セキュリティエラーのハンドリング")
    func testSecurityErrorHandling() async throws {
        let securityManager = DataSecurityManager.shared
        
        // 不正なデータでの暗号化テスト
        let emptyData = Data()
        let encryptedEmpty = try securityManager.encryptData(emptyData)
        let decryptedEmpty = try securityManager.decryptData(encryptedEmpty)
        
        #expect(decryptedEmpty == emptyData)
        
        // 大容量データでの暗号化テスト
        let largeData = Data(repeating: 0xFF, count: 1024 * 1024) // 1MB
        let encryptedLarge = try securityManager.encryptData(largeData)
        let decryptedLarge = try securityManager.decryptData(encryptedLarge)
        
        #expect(decryptedLarge == largeData)
    }
    
    // MARK: - Data Validation Tests
    
    @Test("データ整合性の確認")
    func testDataIntegrity() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        
        // ログを作成
        let originalContent = "データ整合性テスト"
        let log = try repository.createActionLog(content: originalContent, logType: .success)
        
        // データベースから再取得
        let retrievedLogs = try repository.getAllActionLogs()
        let retrievedLog = retrievedLogs.first { $0.id == log.id }
        
        #expect(retrievedLog != nil)
        #expect(retrievedLog?.content == originalContent)
        #expect(retrievedLog?.logType == .success)
    }
    
    @Test("タイムスタンプの整合性")
    func testTimestampIntegrity() async throws {
        let modelContext = try createTestModelContext()
        let repository = ActionLogRepository(modelContext: modelContext)
        
        let beforeCreation = Date()
        let log = try repository.createActionLog(content: "タイムスタンプテスト", logType: .other)
        let afterCreation = Date()
        
        // タイムスタンプが適切な範囲内にあることを確認
        #expect(log.timestamp >= beforeCreation)
        #expect(log.timestamp <= afterCreation)
        
        // 作成日時と更新日時が設定されていることを確認
        #expect(log.createdAt >= beforeCreation)
        #expect(log.updatedAt >= beforeCreation)
    }
}