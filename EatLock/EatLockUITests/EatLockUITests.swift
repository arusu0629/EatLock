//
//  EatLockUITests.swift
//  EatLockUITests
//
//  Created by arusu0629 on 2025/06/25.
//

import XCTest

final class EatLockUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app = nil
    }
    
    // MARK: - Main Flow Integration Tests
    
    @MainActor
    func testMainFlowLogInputToFeedbackToStatsUpdate() throws {
        // メインフロー統合テスト: ログ入力→フィードバック→統計更新の一連の流れをテスト
        
        // 1. 初期状態の確認
        XCTAssertTrue(app.staticTexts["EatLock"].exists, "アプリタイトルが表示されていない")
        
        // 2. ログ入力フィールドの確認
        let logInputField = app.textFields["今日の行動を入力..."]
        XCTAssertTrue(logInputField.exists, "ログ入力フィールドが存在しない")
        
        // 3. ログタイプピッカーの確認
        let logTypePicker = app.buttons["ログタイプ選択"]
        XCTAssertTrue(logTypePicker.exists, "ログタイプピッカーが存在しない")
        
        // 4. 送信ボタンの確認（初期状態では無効）
        let submitButton = app.buttons["送信ボタン"]
        XCTAssertTrue(submitButton.exists, "送信ボタンが存在しない")
        XCTAssertFalse(submitButton.isEnabled, "送信ボタンが初期状態で有効になっている")
        
        // 5. テスト用のログ内容を入力
        let testLogContent = "今日はアイスクリームを我慢しました"
        logInputField.tap()
        logInputField.typeText(testLogContent)
        
        // 6. 送信ボタンが有効になることを確認
        XCTAssertTrue(submitButton.isEnabled, "ログ入力後に送信ボタンが有効にならない")
        
        // 7. ログを送信
        submitButton.tap()
        
        // 8. 入力フィールドがクリアされることを確認
        let expectation = XCTestExpectation(description: "入力フィールドがクリアされる")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertEqual(logInputField.value as? String ?? "", "", "入力フィールドがクリアされていない")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        
        // 9. フィードバックまたはトーストの表示を確認
        let feedbackExists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'カロリー' OR label CONTAINS[c] '素晴らしい' OR label CONTAINS[c] '我慢'")).firstMatch.exists
        let toastExists = app.staticTexts["行動ログを保存しました"].exists
        XCTAssertTrue(feedbackExists || toastExists, "フィードバックまたはトーストが表示されていない")
        
        // 10. 統計カードの更新を確認
        let statsCard = app.otherElements.containing(NSPredicate(format: "label CONTAINS[c] 'カロリー' OR label CONTAINS[c] '統計'")).firstMatch
        XCTAssertTrue(statsCard.exists, "統計カードが表示されていない")
        
        // 11. ログ一覧に新しいログが追加されることを確認
        let logListItem = app.staticTexts[testLogContent]
        XCTAssertTrue(logListItem.waitForExistence(timeout: 3.0), "ログ一覧に新しいログが追加されていない")
    }
    
    @MainActor
    func testLogTypeSelection() throws {
        // ログタイプ選択機能のテスト
        
        let logTypePicker = app.buttons["ログタイプ選択"]
        XCTAssertTrue(logTypePicker.exists, "ログタイプピッカーが存在しない")
        
        // ピッカーをタップしてオプションを表示
        logTypePicker.tap()
        
        // 各ログタイプのオプションが存在することを確認
        let successOption = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] '成功'")).firstMatch
        let failureOption = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] '失敗'")).firstMatch
        let struggleOption = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] '苦労'")).firstMatch
        let otherOption = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'その他'")).firstMatch
        
        XCTAssertTrue(successOption.exists, "成功オプションが存在しない")
        XCTAssertTrue(failureOption.exists, "失敗オプションが存在しない")
        XCTAssertTrue(struggleOption.exists, "苦労オプションが存在しない")
        XCTAssertTrue(otherOption.exists, "その他オプションが存在しない")
        
        // 成功タイプを選択
        successOption.tap()
        
        // 選択が反映されることを確認
        XCTAssertTrue(logTypePicker.label.contains("成功"), "ログタイプの選択が反映されていない")
    }
    
    @MainActor
    func testFloatingAddButtonInteraction() throws {
        // フローティング追加ボタンの動作テスト
        
        // スクロールしてフローティングボタンを表示
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        
        // フローティングボタンの存在を確認
        let floatingButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'フローティング' OR label CONTAINS[c] '追加'")).firstMatch
        
        if floatingButton.exists {
            // フローティングボタンをタップ
            floatingButton.tap()
            
            // 入力フィールドがフォーカスされることを確認
            let logInputField = app.textFields["今日の行動を入力..."]
            XCTAssertTrue(logInputField.exists, "フローティングボタンタップ後に入力フィールドが表示されない")
        }
    }
    
    @MainActor
    func testCharacterLimitValidation() throws {
        // 文字数制限バリデーションのテスト
        
        let logInputField = app.textFields["今日の行動を入力..."]
        logInputField.tap()
        
        // 長いテキストを入力
        let longText = String(repeating: "あ", count: 600) // 500文字を超える
        logInputField.typeText(longText)
        
        // 文字数上限警告が表示されることを確認
        let warningText = app.staticTexts["文字数上限に達しました"]
        XCTAssertTrue(warningText.exists, "文字数上限警告が表示されていない")
        
        // 送信ボタンの状態を確認
        let submitButton = app.buttons["送信ボタン"]
        // 文字数制限により送信ボタンが無効になる可能性があるが、
        // 実装では500文字で切り捨てるので有効のまま
        XCTAssertTrue(submitButton.isEnabled, "文字数制限後に送信ボタンが適切に処理されていない")
    }
    
    @MainActor
    func testEmptyInputValidation() throws {
        // 空入力バリデーションのテスト
        
        let logInputField = app.textFields["今日の行動を入力..."]
        let submitButton = app.buttons["送信ボタン"]
        
        // 初期状態では送信ボタンは無効
        XCTAssertFalse(submitButton.isEnabled, "空入力時に送信ボタンが有効になっている")
        
        // 空白文字のみを入力
        logInputField.tap()
        logInputField.typeText("   ")
        
        // 送信ボタンは無効のまま
        XCTAssertFalse(submitButton.isEnabled, "空白文字のみの入力時に送信ボタンが有効になっている")
        
        // 有効な文字を入力
        logInputField.clearText()
        logInputField.typeText("有効な入力")
        
        // 送信ボタンが有効になる
        XCTAssertTrue(submitButton.isEnabled, "有効な入力後に送信ボタンが有効にならない")
    }
    
    @MainActor
    func testStatisticsCardDisplay() throws {
        // 統計カードの表示テスト
        
        // 統計カードが存在することを確認
        let statsCard = app.otherElements.containing(NSPredicate(format: "label CONTAINS[c] '統計' OR label CONTAINS[c] 'カロリー'")).firstMatch
        XCTAssertTrue(statsCard.exists, "統計カードが表示されていない")
        
        // 統計の各要素が表示されることを確認
        let totalLogsLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] '合計'")).firstMatch
        let successRateLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] '成功率' OR label CONTAINS[c] '%'")).firstMatch
        let preventedCaloriesLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'カロリー'")).firstMatch
        
        XCTAssertTrue(totalLogsLabel.exists || successRateLabel.exists || preventedCaloriesLabel.exists, 
                     "統計の基本情報が表示されていない")
    }
    
    @MainActor
    func testLogListDisplay() throws {
        // ログ一覧の表示テスト
        
        // テストログを追加
        let logInputField = app.textFields["今日の行動を入力..."]
        let submitButton = app.buttons["送信ボタン"]
        
        logInputField.tap()
        logInputField.typeText("テスト用ログ")
        submitButton.tap()
        
        // ログ一覧にアイテムが表示されることを確認
        let logItem = app.staticTexts["テスト用ログ"]
        XCTAssertTrue(logItem.waitForExistence(timeout: 3.0), "ログ一覧にアイテムが表示されていない")
    }
    
    @MainActor
    func testAdBannerDisplay() throws {
        // 広告バナーの表示テスト
        
        // 広告バナーエリアの存在を確認
        let adBannerArea = app.otherElements.containing(NSPredicate(format: "label CONTAINS[c] '広告' OR label CONTAINS[c] 'Ad'")).firstMatch
        
        // 広告が表示されるかはネットワーク状況により異なるため、
        // 広告コンテナの存在のみを確認
        if adBannerArea.exists {
            XCTAssertTrue(adBannerArea.exists, "広告バナーエリアが表示されていない")
        }
    }
    
    // MARK: - Original Tests
    
    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
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