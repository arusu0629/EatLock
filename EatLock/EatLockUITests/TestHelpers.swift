//
//  TestHelpers.swift
//  EatLockUITests
//
//  Created by AI Assistant on 2025/07/09.
//

import XCTest

/// UIテスト用の共通ヘルパーメソッド
class TestHelpers {
    
    /// 非同期待機用のヘルパーメソッド
    /// - Parameters:
    ///   - duration: 待機時間（秒）
    ///   - timeout: タイムアウト時間（秒）
    ///   - description: 待機の説明
    static func waitAsync(duration: TimeInterval, timeout: TimeInterval = 2.0, description: String = "Async wait", file: StaticString = #file, line: UInt = #line) {
        let expectation = XCTestExpectation(description: description)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            expectation.fulfill()
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: max(timeout, duration + 1.0))
        if result != .completed {
            XCTFail("Async wait timed out", file: file, line: line)
        }
    }
    
    /// UI要素が存在することを確認するヘルパーメソッド
    /// - Parameters:
    ///   - element: 確認するUI要素
    ///   - timeout: タイムアウト時間（秒）
    ///   - message: 失敗時のメッセージ
    /// - Returns: 要素が存在するかどうか
    static func waitForElementToExist(_ element: XCUIElement, timeout: TimeInterval = 3.0, message: String = "") -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    /// フィードバック要素の存在を確認するヘルパーメソッド
    /// - Parameters:
    ///   - app: XCUIApplication
    ///   - timeout: タイムアウト時間（秒）
    /// - Returns: フィードバックが表示されているかどうか
    static func waitForFeedback(in app: XCUIApplication, timeout: TimeInterval = 5.0) -> Bool {
        let feedbackPredicate = NSPredicate(format: "label CONTAINS[c] 'エラー' OR label CONTAINS[c] '保存' OR label CONTAINS[c] 'カロリー' OR label CONTAINS[c] '素晴らしい' OR label CONTAINS[c] '我慢'")
        let feedbackElement = app.staticTexts.containing(feedbackPredicate).firstMatch
        return feedbackElement.waitForExistence(timeout: timeout)
    }
    
    /// キーボードの表示を確認するヘルパーメソッド
    /// - Parameters:
    ///   - app: XCUIApplication
    ///   - timeout: タイムアウト時間（秒）
    /// - Returns: キーボードが表示されているかどうか
    static func waitForKeyboard(in app: XCUIApplication, timeout: TimeInterval = 3.0) -> Bool {
        let keyboard = app.keyboards.firstMatch
        return keyboard.waitForExistence(timeout: timeout)
    }
    
    /// 文字数カウンターの表示を確認するヘルパーメソッド
    /// - Parameters:
    ///   - app: XCUIApplication
    ///   - timeout: タイムアウト時間（秒）
    /// - Returns: 文字数カウンターが表示されているかどうか
    static func waitForCharacterCounter(in app: XCUIApplication, timeout: TimeInterval = 2.0) -> Bool {
        let counterElement = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] '/500'")).firstMatch
        return counterElement.waitForExistence(timeout: timeout)
    }
    
    /// ログリストにアイテムが追加されることを確認するヘルパーメソッド
    /// - Parameters:
    ///   - app: XCUIApplication
    ///   - content: 探すログの内容
    ///   - timeout: タイムアウト時間（秒）
    /// - Returns: ログアイテムが表示されているかどうか
    static func waitForLogItem(in app: XCUIApplication, content: String, timeout: TimeInterval = 3.0) -> Bool {
        let logItem = app.staticTexts[content]
        return logItem.waitForExistence(timeout: timeout)
    }
    
    /// アプリの状態を確認するヘルパーメソッド
    /// - Parameter app: XCUIApplication
    /// - Returns: アプリがフォアグラウンドで実行されているかどうか
    static func isAppRunning(_ app: XCUIApplication) -> Bool {
        return app.state == .runningForeground
    }
    
    /// UI要素のアクセシビリティを確認するヘルパーメソッド
    /// - Parameters:
    ///   - element: 確認するUI要素
    ///   - checkLabel: ラベルの存在を確認するかどうか
    ///   - checkHint: ヒントの存在を確認するかどうか
    /// - Returns: アクセシビリティ設定が適切かどうか
    static func checkAccessibility(for element: XCUIElement, checkLabel: Bool = true, checkHint: Bool = true) -> Bool {
        guard element.exists else { return false }
        
        if checkLabel && element.accessibilityLabel?.isEmpty != false {
            return false
        }
        
        if checkHint && element.accessibilityHint?.isEmpty != false {
            return false
        }
        
        return true
    }
    
    /// 最小アクセシビリティサイズを満たすかどうか確認するヘルパーメソッド
    /// - Parameter element: 確認するUI要素
    /// - Returns: 最小サイズ（44x44ポイント）を満たすかどうか
    static func meetsMinimumAccessibilitySize(_ element: XCUIElement) -> Bool {
        let frame = element.frame
        return frame.width >= 44 && frame.height >= 44
    }
    
    /// 堅牢なUI要素操作（エラーハンドリング付き）
    /// - Parameters:
    ///   - element: 操作するUI要素
    ///   - action: 実行するアクション
    ///   - maxRetries: 最大リトライ回数
    ///   - retryDelay: リトライ間隔（秒）
    /// - Returns: 操作が成功したかどうか
    static func performRobustAction(on element: XCUIElement, action: () -> Void, maxRetries: Int = 3, retryDelay: TimeInterval = 0.5) -> Bool {
        for attempt in 1...maxRetries {
            if element.exists && element.isHittable {
                action()
                return true
            }
            
            if attempt < maxRetries {
                waitAsync(duration: retryDelay, description: "Retry delay for attempt \(attempt)")
            }
        }
        return false
    }
    
    /// 安全なテキスト入力（エラーハンドリング付き）
    /// - Parameters:
    ///   - textField: テキストフィールド
    ///   - text: 入力するテキスト
    ///   - clearFirst: 最初にクリアするかどうか
    /// - Returns: 入力が成功したかどうか
    static func safeTextInput(to textField: XCUIElement, text: String, clearFirst: Bool = true) -> Bool {
        return performRobustAction(on: textField, action: {
            if clearFirst {
                textField.clearText()
            }
            textField.typeText(text)
        })
    }
    
    /// 複数の条件を満たすまで待機する
    /// - Parameters:
    ///   - conditions: 満たすべき条件の配列
    ///   - timeout: タイムアウト時間
    /// - Returns: すべての条件が満たされたかどうか
    static func waitForMultipleConditions(_ conditions: [() -> Bool], timeout: TimeInterval = 5.0) -> Bool {
        let expectation = XCTestExpectation(description: "Wait for multiple conditions")
        var conditionsMet = false
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            let allConditionsMet = conditions.allSatisfy { $0() }
            if allConditionsMet {
                conditionsMet = true
                expectation.fulfill()
                timer.invalidate()
            }
        }
        
        let testCase = XCTestCase()
        let result = testCase.wait(for: [expectation], timeout: timeout)
        timer.invalidate()
        
        return conditionsMet && result == .completed
    }
}

/// XCUIElement拡張でテキストクリア機能を提供
extension XCUIElement {
    /// テキストフィールドの内容をクリアする
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        self.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
    
    /// テキストフィールドに安全にテキストを入力する
    /// - Parameter text: 入力するテキスト
    func safeTypeText(_ text: String) {
        self.tap()
        self.clearText()
        self.typeText(text)
    }
}