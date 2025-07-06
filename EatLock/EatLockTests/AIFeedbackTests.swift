import XCTest
@testable import EatLock

/// AIフィードバック機能のユニットテスト
@MainActor
final class AIFeedbackTests: XCTestCase {
    
    // MARK: - Properties
    
    private var aiManager: AIManager!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        aiManager = AIManager.shared
    }
    
    override func tearDownWithError() throws {
        aiManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Test Utilities
    
    private func setupAI() async {
        await aiManager.initialize()
    }
    
    private func assertFeedbackGeneration(
        for input: String,
        expectedType: AIFeedback.FeedbackType,
        expectedMinCalories: Int = 0,
        expectedMaxCalories: Int = Int.max,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let result = await aiManager.generateFeedback(for: input)
        
        switch result {
        case .success(let feedback):
            XCTAssertFalse(feedback.message.isEmpty, "Feedback message should not be empty", file: file, line: line)
            XCTAssertEqual(feedback.type, expectedType, "Feedback type should be \(expectedType)", file: file, line: line)
            XCTAssertGreaterThanOrEqual(feedback.preventedCalories, expectedMinCalories, "Prevented calories should be at least \(expectedMinCalories)", file: file, line: line)
            XCTAssertLessThanOrEqual(feedback.preventedCalories, expectedMaxCalories, "Prevented calories should be at most \(expectedMaxCalories)", file: file, line: line)
        case .failure(let error):
            XCTFail("Feedback generation failed for '\(input)': \(error)", file: file, line: line)
        }
    }
    
    private func assertJSONFeedbackGeneration(
        for input: String,
        expectedType: String,
        expectedMinCalories: Int = 0,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let result = await aiManager.generateFeedbackAsJSON(for: input)
        
        switch result {
        case .success(let jsonString):
            XCTAssertFalse(jsonString.isEmpty, "JSON string should not be empty", file: file, line: line)
            
            do {
                let jsonData = jsonString.data(using: .utf8)!
                let feedbackResponse = try JSONDecoder().decode(AIFeedbackJSONResponse.self, from: jsonData)
                
                XCTAssertFalse(feedbackResponse.message.isEmpty, "JSON message should not be empty", file: file, line: line)
                XCTAssertGreaterThanOrEqual(feedbackResponse.kcal, expectedMinCalories, "JSON kcal should be at least \(expectedMinCalories)", file: file, line: line)
                XCTAssertEqual(feedbackResponse.type, expectedType, "JSON type should be \(expectedType)", file: file, line: line)
            } catch {
                XCTFail("Failed to decode JSON: \(error)", file: file, line: line)
            }
        case .failure(let error):
            XCTFail("JSON feedback generation failed for '\(input)': \(error)", file: file, line: line)
        }
    }
    
    private func assertCaloriesForFood(
        _ food: String,
        expectedCalories: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let input = "\(food)を我慢しました"
        let result = await aiManager.generateFeedback(for: input)
        
        switch result {
        case .success(let feedback):
            XCTAssertEqual(feedback.preventedCalories, expectedCalories, 
                          "Calories for \(food) should be \(expectedCalories)", file: file, line: line)
        case .failure(let error):
            XCTFail("Feedback generation failed for \(food): \(error)", file: file, line: line)
        }
    }
    
    private func assertMessageContains(
        _ input: String,
        expectedKeywords: [String],
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let result = await aiManager.generateFeedback(for: input)
        
        switch result {
        case .success(let feedback):
            let messageContainsKeyword = expectedKeywords.contains { keyword in
                feedback.message.contains(keyword)
            }
            XCTAssertTrue(messageContainsKeyword, 
                         "Message should contain one of: \(expectedKeywords)", file: file, line: line)
        case .failure(let error):
            XCTFail("Feedback generation failed for '\(input)': \(error)", file: file, line: line)
        }
    }
    
    // MARK: - AI Manager Tests
    
    func testAIManagerInitialization() async throws {
        await setupAI()
        XCTAssertTrue(aiManager.isInitialized, "AI should be initialized")
        XCTAssertEqual(aiManager.status, .ready, "AI status should be ready")
    }
    
    func testFeedbackGenerationWithSuccessLog() async throws {
        await setupAI()
        await assertFeedbackGeneration(
            for: "今日はアイスクリームを我慢しました",
            expectedType: .achievement,
            expectedMinCalories: 1
        )
    }
    
    func testFeedbackGenerationWithEmotionalTrigger() async throws {
        await setupAI()
        await assertFeedbackGeneration(
            for: "ストレスでイライラしています",
            expectedType: .support,
            expectedMinCalories: 0,
            expectedMaxCalories: 0
        )
    }
    
    func testFeedbackGenerationWithLateNightEating() async throws {
        await setupAI()
        await assertFeedbackGeneration(
            for: "深夜にラーメンを我慢しました",
            expectedType: .achievement,
            expectedMinCalories: 500
        )
    }
    
    func testJSONFeedbackGeneration() async throws {
        await setupAI()
        await assertJSONFeedbackGeneration(
            for: "チョコレートケーキを我慢しました",
            expectedType: "achievement",
            expectedMinCalories: 1
        )
    }
    
    // MARK: - Calorie Calculation Tests
    
    func testCalorieCalculationForSweets() async throws {
        await setupAI()
        
        let testCases: [(String, Int)] = [
            ("アイスクリーム", 250),
            ("チョコレート", 200),
            ("ケーキ", 400),
            ("クッキー", 150),
            ("クリーム", 350)
        ]
        
        for (food, expectedCalories) in testCases {
            await assertCaloriesForFood(food, expectedCalories: expectedCalories)
        }
    }
    
    func testCalorieCalculationForFastFood() async throws {
        await setupAI()
        
        let testCases: [(String, Int)] = [
            ("ハンバーガー", 500),
            ("ピザ", 700),
            ("ラーメン", 550),
            ("コンビニ弁当", 450)
        ]
        
        for (food, expectedCalories) in testCases {
            await assertCaloriesForFood(food, expectedCalories: expectedCalories)
        }
    }
    
    func testCalorieCalculationForLateNightEating() async throws {
        await setupAI()
        
        let testCases: [(String, Int)] = [
            ("深夜にアイスを我慢しました", 500), // 250 * 1.5 = 375, but minimum is 500
            ("夜中にチョコを我慢しました", 500), // 200 * 1.5 = 300, but minimum is 500
            ("深夜にケーキを我慢しました", 600), // 400 * 1.5 = 600
            ("夜食でラーメンを我慢しました", 825) // 550 * 1.5 = 825
        ]
        
        for (input, expectedCalories) in testCases {
            await assertCaloriesForFood(input.replacingOccurrences(of: "を我慢しました", with: ""), expectedCalories: expectedCalories)
        }
    }
    
    // MARK: - Message Type Tests
    
    func testAchievementMessageGeneration() async throws {
        await setupAI()
        
        let inputs = [
            "今日はお菓子を我慢しました",
            "ジュースを控えました",
            "揚げ物を断りました"
        ]
        
        for input in inputs {
            await assertFeedbackGeneration(for: input, expectedType: .achievement, expectedMinCalories: 1)
            await assertMessageContains(input, expectedKeywords: ["我慢", "立派", "素晴らしい", "成功"])
        }
    }
    
    func testSupportMessageGeneration() async throws {
        await setupAI()
        
        let inputs = [
            "ストレスで食べ過ぎました",
            "イライラしています",
            "不安で眠れません"
        ]
        
        for input in inputs {
            await assertFeedbackGeneration(for: input, expectedType: .support, expectedMinCalories: 0, expectedMaxCalories: 0)
            await assertMessageContains(input, expectedKeywords: ["大丈夫", "無理せず", "理解", "優しく"])
        }
    }
    
    func testWarningMessageGeneration() async throws {
        await setupAI()
        
        let inputs = [
            "深夜に食べました",
            "夜中にお菓子を食べました",
            "夜食でラーメンを食べました"
        ]
        
        for input in inputs {
            await assertFeedbackGeneration(for: input, expectedType: .warning, expectedMinCalories: 0, expectedMaxCalories: 0)
            await assertMessageContains(input, expectedKeywords: ["注意", "負担", "控え", "休息"])
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyInputHandling() async throws {
        await setupAI()
        
        let result = await aiManager.generateFeedback(for: "")
        
        switch result {
        case .success(_):
            XCTFail("Empty input should fail")
        case .failure(let error):
            XCTAssertEqual(error, .inputProcessingFailed, "Empty input should return inputProcessingFailed error")
        }
    }
    
    func testUninitializedAIHandling() async throws {
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
        await setupAI()
        
        measure {
            let expectation = XCTestExpectation(description: "Feedback generation performance")
            
            Task {
                await assertFeedbackGeneration(
                    for: "テスト用の入力です",
                    expectedType: .encouragement
                )
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}