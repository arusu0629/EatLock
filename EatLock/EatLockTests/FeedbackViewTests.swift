//
//  FeedbackViewTests.swift
//  EatLockTests
//
//  Created by AI Assistant on 2025/07/04.
//

import XCTest
@testable import EatLock

final class FeedbackViewTests: XCTestCase {
    
    func testFeedbackCreation() {
        // Given
        let message = "素晴らしい自制心です！"
        let preventedCalories = 250
        let type = AIFeedback.FeedbackType.achievement
        let generatedAt = Date()
        
        // When
        let feedback = AIFeedback(
            message: message,
            preventedCalories: preventedCalories,
            type: type,
            generatedAt: generatedAt
        )
        
        // Then
        XCTAssertEqual(feedback.message, message)
        XCTAssertEqual(feedback.preventedCalories, preventedCalories)
        XCTAssertEqual(feedback.type, type)
        XCTAssertEqual(feedback.generatedAt, generatedAt)
    }
    
    func testFeedbackTypeDisplayName() {
        // Given & When & Then
        XCTAssertEqual(AIFeedback.FeedbackType.encouragement.displayName, "励まし")
        XCTAssertEqual(AIFeedback.FeedbackType.achievement.displayName, "達成")
        XCTAssertEqual(AIFeedback.FeedbackType.support.displayName, "サポート")
        XCTAssertEqual(AIFeedback.FeedbackType.warning.displayName, "注意")
    }
    
    func testJSONResponseCreation() {
        // Given
        let feedback = AIFeedback(
            message: "テストメッセージ",
            preventedCalories: 150,
            type: .achievement,
            generatedAt: Date()
        )
        
        // When
        let jsonResponse = feedback.toJSONResponse()
        
        // Then
        XCTAssertEqual(jsonResponse.message, "テストメッセージ")
        XCTAssertEqual(jsonResponse.kcal, 150)
        XCTAssertEqual(jsonResponse.type, "achievement")
        XCTAssertFalse(jsonResponse.generatedAt.isEmpty)
    }
}