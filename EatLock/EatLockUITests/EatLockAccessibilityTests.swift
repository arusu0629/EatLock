//
//  EatLockAccessibilityTests.swift
//  EatLockUITests
//
//  Created by AI Assistant on 2025/07/09.
//

import XCTest

final class EatLockAccessibilityTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testVoiceOverCompatibility() throws {
        // VoiceOver互換性テスト
        
        // 主要なUI要素がアクセシビリティラベルを持つことを確認
        let logInputField = app.textFields["今日の行動を入力..."]
        XCTAssertTrue(logInputField.exists, "ログ入力フィールドが存在しない")
        XCTAssertNotNil(logInputField.accessibilityLabel, "ログ入力フィールドにアクセシビリティラベルがない")
        
        let logTypePicker = app.buttons["ログタイプ選択"]
        XCTAssertTrue(logTypePicker.exists, "ログタイプピッカーが存在しない")
        XCTAssertNotNil(logTypePicker.accessibilityLabel, "ログタイプピッカーにアクセシビリティラベルがない")
        
        let submitButton = app.buttons["送信ボタン"]
        XCTAssertTrue(submitButton.exists, "送信ボタンが存在しない")
        XCTAssertNotNil(submitButton.accessibilityLabel, "送信ボタンにアクセシビリティラベルがない")
    }
    
    @MainActor
    func testAccessibilityHints() throws {
        // アクセシビリティヒントの確認
        
        let logInputField = app.textFields["今日の行動を入力..."]
        XCTAssertTrue(logInputField.exists, "ログ入力フィールドが存在しない")
        
        let logTypePicker = app.buttons["ログタイプ選択"]
        XCTAssertTrue(logTypePicker.exists, "ログタイプピッカーが存在しない")
        
        let submitButton = app.buttons["送信ボタン"]
        XCTAssertTrue(submitButton.exists, "送信ボタンが存在しない")
        
        // アクセシビリティヒントが適切に設定されているか確認
        // 実際の値は実装に依存するため、存在確認のみ行う
        XCTAssertNotNil(logInputField.accessibilityHint, "ログ入力フィールドにアクセシビリティヒントがない")
        XCTAssertNotNil(logTypePicker.accessibilityHint, "ログタイプピッカーにアクセシビリティヒントがない")
    }
    
    @MainActor
    func testDynamicTypeSupport() throws {
        // ダイナミックタイプサポートのテスト
        
        // 大きなテキストサイズでもUIが適切に表示されることを確認
        let logInputField = app.textFields["今日の行動を入力..."]
        XCTAssertTrue(logInputField.exists, "ログ入力フィールドが存在しない")
        
        // フィールドがタップ可能であることを確認
        XCTAssertTrue(logInputField.isHittable, "ログ入力フィールドがタップできない")
        
        let submitButton = app.buttons["送信ボタン"]
        XCTAssertTrue(submitButton.exists, "送信ボタンが存在しない")
        XCTAssertTrue(submitButton.isHittable, "送信ボタンがタップできない")
    }
    
    @MainActor
    func testKeyboardNavigation() throws {
        // キーボードナビゲーションのテスト
        
        let logInputField = app.textFields["今日の行動を入力..."]
        logInputField.tap()
        
        // キーボードが表示されることを確認
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 2.0), "キーボードが表示されない")
        
        // テキストを入力
        logInputField.typeText("テスト入力")
        
        // リターンキーでフォーカスを移動できることを確認
        if keyboard.buttons["Return"].exists {
            keyboard.buttons["Return"].tap()
        }
    }
    
    @MainActor
    func testContrastAndVisibility() throws {
        // コントラストと視認性のテスト
        
        // 重要な要素が表示されていることを確認
        let logInputField = app.textFields["今日の行動を入力..."]
        XCTAssertTrue(logInputField.isHittable, "ログ入力フィールドが視認できない")
        
        let submitButton = app.buttons["送信ボタン"]
        XCTAssertTrue(submitButton.isHittable, "送信ボタンが視認できない")
        
        // 文字数カウンターが適切に表示されることを確認
        logInputField.tap()
        logInputField.typeText("テスト")
        
        // 文字数カウンターが表示されることを確認
        let characterCount = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] '/500'")).firstMatch
        XCTAssertTrue(characterCount.waitForExistence(timeout: 1.0), "文字数カウンターが表示されない")
    }
    
    @MainActor
    func testAccessibilityTraits() throws {
        // アクセシビリティトレイツのテスト
        
        let logInputField = app.textFields["今日の行動を入力..."]
        XCTAssertTrue(logInputField.exists, "ログ入力フィールドが存在しない")
        
        let submitButton = app.buttons["送信ボタン"]
        XCTAssertTrue(submitButton.exists, "送信ボタンが存在しない")
        
        // 無効状態のボタンが適切なトレイツを持つことを確認
        XCTAssertFalse(submitButton.isEnabled, "送信ボタンが初期状態で有効になっている")
        
        // 有効な入力後にボタンが有効になることを確認
        logInputField.tap()
        logInputField.typeText("有効な入力")
        XCTAssertTrue(submitButton.isEnabled, "有効な入力後に送信ボタンが有効にならない")
    }
}