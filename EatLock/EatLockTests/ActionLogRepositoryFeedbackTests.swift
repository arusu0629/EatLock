//
//  ActionLogRepositoryFeedbackTests.swift
//  EatLockTests
//
//  Created by AI Assistant on 2025/07/04.
//

import XCTest
import SwiftData
@testable import EatLock

final class ActionLogRepositoryFeedbackTests: XCTestCase {
    
    var repository: ActionLogRepository!
    var modelContext: ModelContext!
    
    override func setUp() {
        super.setUp()
        
        // In-memory database for testing
        let container = try! ModelContainer(
            for: ActionLog.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        modelContext = ModelContext(container)
        repository = ActionLogRepository(modelContext: modelContext)
    }
    
    override func tearDown() {
        repository = nil
        modelContext = nil
        super.tearDown()
    }
    
    func testFetchActionLogsWithFeedback() throws {
        // Given
        let logWithFeedback = try repository.createActionLog(content: "テストログ1", logType: .success)
        try repository.setAIFeedback(for: logWithFeedback, feedback: "フィードバック1", preventedCalories: 100)
        
        let logWithoutFeedback = try repository.createActionLog(content: "テストログ2", logType: .other)
        
        // When
        let result = try repository.fetchActionLogsWithFeedback()
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, logWithFeedback.id)
    }
    
    func testFetchFeedbackHistoryWithCalories() throws {
        // Given
        let logWithCalories = try repository.createActionLog(content: "テストログ1", logType: .success)
        try repository.setAIFeedback(for: logWithCalories, feedback: "フィードバック1", preventedCalories: 200)
        
        let logWithoutCalories = try repository.createActionLog(content: "テストログ2", logType: .success)
        try repository.setAIFeedback(for: logWithoutCalories, feedback: "フィードバック2", preventedCalories: 0)
        
        let logWithoutFeedback = try repository.createActionLog(content: "テストログ3", logType: .other)
        
        // When
        let result = try repository.fetchFeedbackHistoryWithCalories()
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, logWithCalories.id)
        XCTAssertEqual(result.first?.preventedCalories, 200)
    }
    
    func testFetchTodaysFeedbackHistory() throws {
        // Given
        let todayLog = try repository.createActionLog(content: "今日のログ", logType: .success)
        try repository.setAIFeedback(for: todayLog, feedback: "今日のフィードバック", preventedCalories: 150)
        
        let yesterdayLog = try repository.createActionLog(content: "昨日のログ", logType: .success)
        yesterdayLog.timestamp = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        try modelContext.save() // timestamp変更後に保存
        try repository.setAIFeedback(for: yesterdayLog, feedback: "昨日のフィードバック", preventedCalories: 100)
        
        // When
        let result = try repository.fetchTodaysFeedbackHistory()
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, todayLog.id)
    }
    
    func testFetchFeedbackHistoryByDateRange() throws {
        // Given
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()
        
        let recentLog = try repository.createActionLog(content: "最近のログ", logType: .success)
        recentLog.timestamp = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        try modelContext.save() // timestamp変更後に保存
        try repository.setAIFeedback(for: recentLog, feedback: "最近のフィードバック", preventedCalories: 120)
        
        let oldLog = try repository.createActionLog(content: "古いログ", logType: .success)
        oldLog.timestamp = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        try modelContext.save() // timestamp変更後に保存
        try repository.setAIFeedback(for: oldLog, feedback: "古いフィードバック", preventedCalories: 80)
        
        // When
        let result = try repository.fetchFeedbackHistory(from: startDate, to: endDate)
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, recentLog.id)
    }
}