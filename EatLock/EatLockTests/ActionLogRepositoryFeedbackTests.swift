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
        let logWithFeedback = ActionLog(content: "テストログ1", logType: .success)
        logWithFeedback.setAIFeedback("フィードバック1", preventedCalories: 100)
        
        let logWithoutFeedback = ActionLog(content: "テストログ2", logType: .other)
        
        modelContext.insert(logWithFeedback)
        modelContext.insert(logWithoutFeedback)
        try modelContext.save()
        
        // When
        let result = try repository.fetchActionLogsWithFeedback()
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, logWithFeedback.id)
    }
    
    func testFetchFeedbackHistoryWithCalories() throws {
        // Given
        let logWithCalories = ActionLog(content: "テストログ1", logType: .success)
        logWithCalories.setAIFeedback("フィードバック1", preventedCalories: 200)
        
        let logWithoutCalories = ActionLog(content: "テストログ2", logType: .success)
        logWithoutCalories.setAIFeedback("フィードバック2", preventedCalories: 0)
        
        let logWithoutFeedback = ActionLog(content: "テストログ3", logType: .other)
        
        modelContext.insert(logWithCalories)
        modelContext.insert(logWithoutCalories)
        modelContext.insert(logWithoutFeedback)
        try modelContext.save()
        
        // When
        let result = try repository.fetchFeedbackHistoryWithCalories()
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, logWithCalories.id)
        XCTAssertEqual(result.first?.preventedCalories, 200)
    }
    
    func testFetchTodaysFeedbackHistory() throws {
        // Given
        let todayLog = ActionLog(content: "今日のログ", logType: .success)
        todayLog.setAIFeedback("今日のフィードバック", preventedCalories: 150)
        
        let yesterdayLog = ActionLog(content: "昨日のログ", logType: .success)
        yesterdayLog.timestamp = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        yesterdayLog.setAIFeedback("昨日のフィードバック", preventedCalories: 100)
        
        modelContext.insert(todayLog)
        modelContext.insert(yesterdayLog)
        try modelContext.save()
        
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
        
        let recentLog = ActionLog(content: "最近のログ", logType: .success)
        recentLog.timestamp = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        recentLog.setAIFeedback("最近のフィードバック", preventedCalories: 120)
        
        let oldLog = ActionLog(content: "古いログ", logType: .success)
        oldLog.timestamp = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        oldLog.setAIFeedback("古いフィードバック", preventedCalories: 80)
        
        modelContext.insert(recentLog)
        modelContext.insert(oldLog)
        try modelContext.save()
        
        // When
        let result = try repository.fetchFeedbackHistory(from: startDate, to: endDate)
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, recentLog.id)
    }
}