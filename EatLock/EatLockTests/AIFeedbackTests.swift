import XCTest
@testable import EatLock

/// AIフィードバック機能のユニットテスト
@MainActor
final class AIFeedbackTests: XCTestCase {
    
    var aiManager: AIManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        aiManager = AIManager.shared
    }
    
    override func tearDownWithError() throws {
        aiManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - AI Manager Tests
    
    func testAIManagerInitialization() async throws {
        // AI初期化のテスト
        await aiManager.initialize()
        XCTAssertTrue(aiManager.isInitialized, "AI should be initialized")
        XCTAssertEqual(aiManager.status, .ready, "AI status should be ready")
    }
    
    func testFeedbackGenerationWithSuccessLog() async throws {
        // 成功ログに対するフィードバック生成テスト
        await aiManager.initialize()
        
        let input = "今日はアイスクリームを我慢しました"
        let result = await aiManager.generateFeedback(for: input)
        
        switch result {
        case .success(let feedback):
            XCTAssertFalse(feedback.message.isEmpty, "Feedback message should not be empty")
            XCTAssertGreaterThan(feedback.preventedCalories, 0, "Prevented calories should be positive")
            XCTAssertEqual(feedback.type, .achievement, "Feedback type should be achievement")
        case .failure(let error):
            XCTFail("Feedback generation failed: \(error)")
        }
    }
    
    func testFeedbackGenerationWithEmotionalTrigger() async throws {
        // 感情的トリガーに対するフィードバック生成テスト
        await aiManager.initialize()
        
        let input = "ストレスでイライラしています"
        let result = await aiManager.generateFeedback(for: input)
        
        switch result {
        case .success(let feedback):
            XCTAssertFalse(feedback.message.isEmpty, "Feedback message should not be empty")
            XCTAssertEqual(feedback.preventedCalories, 0, "Prevented calories should be 0 for emotional support")
            XCTAssertEqual(feedback.type, .support, "Feedback type should be support")
        case .failure(let error):
            XCTFail("Feedback generation failed: \(error)")
        }
    }
    
    func testFeedbackGenerationWithLateNightEating() async throws {
        // 深夜食に対するフィードバック生成テスト
        await aiManager.initialize()
        
        let input = "深夜にラーメンを我慢しました"
        let result = await aiManager.generateFeedback(for: input)
        
        switch result {
        case .success(let feedback):
            XCTAssertFalse(feedback.message.isEmpty, "Feedback message should not be empty")
            XCTAssertGreaterThanOrEqual(feedback.preventedCalories, 500, "Late night eating should have at least 500 calories")
            XCTAssertEqual(feedback.type, .achievement, "Feedback type should be achievement")
        case .failure(let error):
            XCTFail("Feedback generation failed: \(error)")
        }
    }
    
    func testJSONFeedbackGeneration() async throws {
        // JSON形式でのフィードバック生成テスト
        await aiManager.initialize()
        
        let input = "チョコレートケーキを我慢しました"
        let result = await aiManager.generateFeedbackAsJSON(for: input)
        
        switch result {
        case .success(let jsonString):
            XCTAssertFalse(jsonString.isEmpty, "JSON string should not be empty")
            
            // JSONのパーステスト
            let jsonData = jsonString.data(using: .utf8)!
            let feedbackResponse = try JSONDecoder().decode(AIFeedbackJSONResponse.self, from: jsonData)
            
            XCTAssertFalse(feedbackResponse.message.isEmpty, "JSON message should not be empty")
            XCTAssertGreaterThan(feedbackResponse.kcal, 0, "JSON kcal should be positive")
            XCTAssertEqual(feedbackResponse.type, "achievement", "JSON type should be achievement")
            
        case .failure(let error):
            XCTFail("JSON feedback generation failed: \(error)")
        }
    }
    
    // MARK: - Calorie Calculation Tests
    
    func testCalorieCalculationForSweets() async throws {
        // 甘い物のカロリー計算テスト
        await aiManager.initialize()
        
        let testCases = [
            ("アイスクリーム", 250),
            ("チョコレート", 200),
            ("ケーキ", 400),
            ("クッキー", 150),
            ("クリーム", 350)
        ]
        
        for (food, expectedCalories) in testCases {
            let input = "\(food)を我慢しました"
            let result = await aiManager.generateFeedback(for: input)
            
            switch result {
            case .success(let feedback):
                XCTAssertEqual(feedback.preventedCalories, expectedCalories, 
                              "Calories for \(food) should be \(expectedCalories)")
            case .failure(let error):
                XCTFail("Feedback generation failed for \(food): \(error)")
            }
        }
    }
    
    func testCalorieCalculationForFastFood() async throws {
        // ファストフードのカロリー計算テスト
        await aiManager.initialize()
        
        let testCases = [
            ("ハンバーガー", 500),
            ("ピザ", 700),
            ("ラーメン", 550),
            ("コンビニ弁当", 450)
        ]
        
        for (food, expectedCalories) in testCases {
            let input = "\(food)を我慢しました"
            let result = await aiManager.generateFeedback(for: input)
            
            switch result {
            case .success(let feedback):
                XCTAssertEqual(feedback.preventedCalories, expectedCalories, 
                              "Calories for \(food) should be \(expectedCalories)")
            case .failure(let error):
                XCTFail("Feedback generation failed for \(food): \(error)")
            }
        }
    }
    
    func testCalorieCalculationForLateNightEating() async throws {
        // 深夜食のカロリー計算テスト（1.5倍と最小500kcal）
        await aiManager.initialize()
        
        let testCases = [
            ("深夜にアイス", 500), // 250 * 1.5 = 375, but minimum is 500
            ("夜中にチョコ", 500), // 200 * 1.5 = 300, but minimum is 500
            ("深夜にケーキ", 600), // 400 * 1.5 = 600
            ("夜食でラーメン", 825) // 550 * 1.5 = 825
        ]
        
        for (input, expectedCalories) in testCases {
            let result = await aiManager.generateFeedback(for: input + "を我慢しました")
            
            switch result {
            case .success(let feedback):
                XCTAssertEqual(feedback.preventedCalories, expectedCalories, 
                              "Late night calories for \(input) should be \(expectedCalories)")
            case .failure(let error):
                XCTFail("Feedback generation failed for \(input): \(error)")
            }
        }
    }
    
    // MARK: - Message Type Tests
    
    func testAchievementMessageGeneration() async throws {
        // 達成メッセージ生成テスト
        await aiManager.initialize()
        
        let inputs = [
            "今日はお菓子を我慢しました",
            "ジュースを控えました",
            "揚げ物を断りました"
        ]
        
        for input in inputs {
            let result = await aiManager.generateFeedback(for: input)
            
            switch result {
            case .success(let feedback):
                XCTAssertEqual(feedback.type, .achievement, "Type should be achievement for: \(input)")
                XCTAssertTrue(feedback.message.contains("我慢") || 
                            feedback.message.contains("立派") || 
                            feedback.message.contains("素晴らしい") ||
                            feedback.message.contains("成功"),
                            "Achievement message should contain positive words")
            case .failure(let error):
                XCTFail("Feedback generation failed for \(input): \(error)")
            }
        }
    }
    
    func testSupportMessageGeneration() async throws {
        // サポートメッセージ生成テスト
        await aiManager.initialize()
        
        let inputs = [
            "ストレスで食べ過ぎました",
            "イライラしています",
            "不安で眠れません"
        ]
        
        for input in inputs {
            let result = await aiManager.generateFeedback(for: input)
            
            switch result {
            case .success(let feedback):
                XCTAssertEqual(feedback.type, .support, "Type should be support for: \(input)")
                XCTAssertTrue(feedback.message.contains("大丈夫") || 
                            feedback.message.contains("無理せず") || 
                            feedback.message.contains("理解") ||
                            feedback.message.contains("優しく"),
                            "Support message should contain empathetic words")
            case .failure(let error):
                XCTFail("Feedback generation failed for \(input): \(error)")
            }
        }
    }
    
    func testWarningMessageGeneration() async throws {
        // 警告メッセージ生成テスト
        await aiManager.initialize()
        
        let inputs = [
            "深夜に食べました",
            "夜中にお菓子を食べました",
            "夜食でラーメンを食べました"
        ]
        
        for input in inputs {
            let result = await aiManager.generateFeedback(for: input)
            
            switch result {
            case .success(let feedback):
                XCTAssertEqual(feedback.type, .warning, "Type should be warning for: \(input)")
                XCTAssertTrue(feedback.message.contains("注意") || 
                            feedback.message.contains("負担") || 
                            feedback.message.contains("控え") ||
                            feedback.message.contains("休息"),
                            "Warning message should contain cautionary words")
            case .failure(let error):
                XCTFail("Feedback generation failed for \(input): \(error)")
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyInputHandling() async throws {
        // 空の入力に対するテスト
        await aiManager.initialize()
        
        let result = await aiManager.generateFeedback(for: "")
        
        switch result {
        case .success(_):
            XCTFail("Empty input should fail")
        case .failure(let error):
            XCTAssertEqual(error, .inputProcessingFailed, "Empty input should return inputProcessingFailed error")
        }
    }
    
    func testUninitializedAIHandling() async throws {
        // 未初期化AIに対するテスト
        aiManager.shutdown()
        
        let result = await aiManager.generateFeedback(for: "test input")
        
        switch result {
        case .success(_):
            XCTFail("Uninitialized AI should fail")
        case .failure(let error):
            XCTAssertEqual(error, .modelNotInitialized, "Uninitialized AI should return modelNotInitialized error")
        }
    }
    
    // MARK: - Performance Tests
    
    func testFeedbackGenerationPerformance() async throws {
        // フィードバック生成のパフォーマンステスト
        await aiManager.initialize()
        
        measure {
            let expectation = XCTestExpectation(description: "Feedback generation performance")
            
            Task {
                let result = await aiManager.generateFeedback(for: "テスト用の入力です")
                switch result {
                case .success(_):
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Performance test failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}