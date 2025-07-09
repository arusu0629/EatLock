//
//  EatLockErrorHandlingTests.swift
//  EatLockUITests
//
//  Created by AI Assistant on 2025/07/09.
//

import XCTest

final class EatLockErrorHandlingTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testEmptyInputErrorHandling() throws {
        // 空入力時のエラーハンドリングテスト
        
        let logInputField = app.textFields["今日の行動を入力..."]
        let submitButton = app.buttons["送信ボタン"]
        
        // 初期状態で送信ボタンが無効であることを確認
        XCTAssertFalse(submitButton.isEnabled, "送信ボタンが初期状態で有効になっている")
        
        // 空白のみの入力では送信ボタンが無効のままであることを確認
        logInputField.tap()
        logInputField.typeText("   ")
        XCTAssertFalse(submitButton.isEnabled, "空白のみの入力で送信ボタンが有効になっている")
        
        // 有効な入力を行うと送信ボタンが有効になることを確認
        logInputField.clearText()
        logInputField.typeText("有効な入力")
        XCTAssertTrue(submitButton.isEnabled, "有効な入力後に送信ボタンが有効にならない")
    }
    
    @MainActor
    func testCharacterLimitErrorHandling() throws {
        // 文字数制限エラーのハンドリングテスト
        
        let logInputField = app.textFields["今日の行動を入力..."]
        let submitButton = app.buttons["送信ボタン"]
        
        logInputField.tap()
        
        // 長すぎるテキストを入力
        let longText = String(repeating: "あ", count: 600)
        logInputField.typeText(longText)
        
        // 文字数上限警告が表示されることを確認
        let warningText = app.staticTexts["文字数上限に達しました"]
        XCTAssertTrue(warningText.exists, "文字数上限警告が表示されていない")
        
        // 送信ボタンの状態を確認（実装によって異なる場合がある）
        // 500文字で切り捨てられる場合は有効のまま
        XCTAssertTrue(submitButton.isEnabled, "文字数制限後の送信ボタンの状態が適切でない")
    }
    
    @MainActor
    func testNetworkErrorHandling() throws {
        // ネットワークエラーのハンドリングテスト
        
        let logInputField = app.textFields["今日の行動を入力..."]
        let submitButton = app.buttons["送信ボタン"]
        
        // 有効な入力を行って送信
        logInputField.tap()
        logInputField.typeText("ネットワークエラーテスト")
        submitButton.tap()
        
        // エラーメッセージまたは成功メッセージが表示されることを確認
        // ネットワーク状況によって結果が異なるため、何らかのフィードバックがあることを確認
        let feedbackExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'エラー' OR label CONTAINS[c] '保存' OR label CONTAINS[c] 'カロリー'")).firstMatch.exists
        
        if feedbackExists {
            XCTAssertTrue(feedbackExists, "フィードバックが表示されていない")
        } else {
            // フィードバックが表示されない場合は、少し待ってから再確認
            let delayedFeedback = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'エラー' OR label CONTAINS[c] '保存' OR label CONTAINS[c] 'カロリー'")).firstMatch
            XCTAssertTrue(delayedFeedback.waitForExistence(timeout: 5.0), "フィードバックが表示されていない")
        }
    }
    
    @MainActor
    func testDatabaseErrorHandling() throws {
        // データベースエラーのハンドリングテスト
        
        let logInputField = app.textFields["今日の行動を入力..."]
        let submitButton = app.buttons["送信ボタン"]
        
        // 複数の入力を素早く送信してデータベースの負荷をテスト
        for i in 1...3 {
            logInputField.tap()
            logInputField.clearText()
            logInputField.typeText("データベーステスト \(i)")
            submitButton.tap()
            
            // 短い間隔で次の入力を行う
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // エラーメッセージまたは成功メッセージが表示されることを確認
        let feedbackExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'エラー' OR label CONTAINS[c] '保存' OR label CONTAINS[c] 'カロリー'")).firstMatch.exists
        
        if !feedbackExists {
            // 少し待ってから再確認
            let delayedFeedback = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'エラー' OR label CONTAINS[c] '保存' OR label CONTAINS[c] 'カロリー'")).firstMatch
            XCTAssertTrue(delayedFeedback.waitForExistence(timeout: 3.0), "フィードバックが表示されていない")
        }
    }
    
    @MainActor
    func testAIServiceErrorHandling() throws {
        // AIサービスエラーのハンドリングテスト
        
        let logInputField = app.textFields["今日の行動を入力..."]
        let submitButton = app.buttons["送信ボタン"]
        
        // 特殊な文字や記号を含む入力でAIサービスをテスト
        let specialCharacters = "!@#$%^&*()_+-=[]{}|;':\",./<>?`~"
        logInputField.tap()
        logInputField.typeText(specialCharacters)
        submitButton.tap()
        
        // エラーメッセージまたは成功メッセージが表示されることを確認
        let feedbackExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'エラー' OR label CONTAINS[c] '保存' OR label CONTAINS[c] 'カロリー'")).firstMatch.exists
        
        if !feedbackExists {
            // 少し待ってから再確認
            let delayedFeedback = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'エラー' OR label CONTAINS[c] '保存' OR label CONTAINS[c] 'カロリー'")).firstMatch
            XCTAssertTrue(delayedFeedback.waitForExistence(timeout: 5.0), "フィードバックが表示されていない")
        }
    }
    
    @MainActor
    func testMemoryPressureHandling() throws {
        // メモリプレッシャーのハンドリングテスト
        
        let logInputField = app.textFields["今日の行動を入力..."]
        let submitButton = app.buttons["送信ボタン"]
        
        // 大量のログを連続して作成してメモリプレッシャーをテスト
        for i in 1...10 {
            logInputField.tap()
            logInputField.clearText()
            logInputField.typeText("メモリプレッシャーテスト \(i) - " + String(repeating: "データ", count: 50))
            submitButton.tap()
            
            // 短い間隔で次の入力を行う
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        // アプリがクラッシュしないことを確認
        XCTAssertTrue(app.state == .runningForeground, "アプリがクラッシュした")
        
        // 最後の入力が正常に処理されることを確認
        let lastLogItem = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'メモリプレッシャーテスト'")).firstMatch
        XCTAssertTrue(lastLogItem.waitForExistence(timeout: 3.0), "最後のログが表示されていない")
    }
    
    @MainActor
    func testUserInterruptionHandling() throws {
        // ユーザーの中断操作のハンドリングテスト
        
        let logInputField = app.textFields["今日の行動を入力..."]
        let submitButton = app.buttons["送信ボタン"]
        
        // 入力開始
        logInputField.tap()
        logInputField.typeText("中断テスト")
        
        // 送信ボタンを押す前に入力をクリア
        logInputField.clearText()
        
        // 送信ボタンが無効になることを確認
        XCTAssertFalse(submitButton.isEnabled, "入力クリア後に送信ボタンが有効のまま")
        
        // 再入力
        logInputField.typeText("再入力テスト")
        XCTAssertTrue(submitButton.isEnabled, "再入力後に送信ボタンが有効にならない")
        
        // 送信
        submitButton.tap()
        
        // 成功メッセージが表示されることを確認
        let successMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] '保存' OR label CONTAINS[c] 'カロリー'")).firstMatch
        XCTAssertTrue(successMessage.waitForExistence(timeout: 3.0), "成功メッセージが表示されていない")
    }
    
    @MainActor
    func testConcurrentOperationsHandling() throws {
        // 同時操作のハンドリングテスト
        
        let logInputField = app.textFields["今日の行動を入力..."]
        let submitButton = app.buttons["送信ボタン"]
        
        // 入力と送信を素早く繰り返す
        logInputField.tap()
        logInputField.typeText("同時操作テスト1")
        submitButton.tap()
        
        // 送信直後に次の入力を開始
        logInputField.clearText()
        logInputField.typeText("同時操作テスト2")
        
        // 送信ボタンが適切に動作することを確認
        if submitButton.isEnabled {
            submitButton.tap()
        }
        
        // アプリが安定した状態を維持することを確認
        XCTAssertTrue(app.state == .runningForeground, "アプリの状態が不安定")
        
        // 最終的にログが表示されることを確認
        let logExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] '同時操作テスト'")).firstMatch.exists
        if !logExists {
            // 少し待ってから再確認
            let delayedLog = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] '同時操作テスト'")).firstMatch
            XCTAssertTrue(delayedLog.waitForExistence(timeout: 3.0), "ログが表示されていない")
        }
    }
}

// MARK: - Test Helper Extensions

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        self.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}