import Foundation
import Combine
import os.log

// MARK: - AIManager

/// AI機能を管理するシングルトンクラス
@MainActor
final class AIManager: ObservableObject {
    
    // MARK: - Properties
    
    static let shared = AIManager()
    
    @Published var isInitialized = false
    @Published var isLoading = false
    @Published var lastError: AIError?
    
    private let logger = Logger(subsystem: "com.eatlock.ai", category: "AIManager")
    private let aiService: AIService
    
    // MARK: - Initialization
    
    private init() {
        self.aiService = LocalAIService()
        logger.info("AIManager initialized")
    }
    
    // MARK: - Public Methods
    
    /// AI機能を初期化
    func initialize() async {
        guard !isInitialized else {
            logger.info("AI already initialized")
            return
        }
        
        isLoading = true
        lastError = nil
        
        logger.info("Starting AI initialization")
        
        let result = await aiService.initialize()
        
        switch result {
        case .success:
            isInitialized = true
            logger.info("AI initialization successful")
        case .failure(let error):
            lastError = error
            logger.error("AI initialization failed: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// 行動ログに対するフィードバックを生成
    /// - Parameter input: ユーザーの入力テキスト
    /// - Returns: AIフィードバック結果
    func generateFeedback(for input: String) async -> Result<AIFeedback, AIError> {
        guard isInitialized else {
            logger.error("AI not initialized when generating feedback")
            return .failure(.modelNotInitialized)
        }
        
        // 入力の事前検証
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            logger.warning("Empty input provided to generateFeedback")
            return .failure(.inputProcessingFailed)
        }
        
        // 入力長の制限チェック（DoS攻撃防止）
        guard trimmedInput.count <= 200 else {
            logger.warning("Input too long: \(trimmedInput.count) characters")
            return .failure(.inputProcessingFailed)
        }
        
        logger.info("Generating feedback for input (length: \(trimmedInput.count))")
        
        let result = await aiService.generateFeedback(for: trimmedInput)
        
        switch result {
        case .success(let feedback):
            logger.info("Feedback generated successfully: type=\(feedback.type.rawValue), calories=\(feedback.preventedCalories)")
            return .success(feedback)
        case .failure(let error):
            logger.error("Feedback generation failed: \(error.localizedDescription)")
            lastError = error
            return .failure(error)
        }
    }
    
    /// 行動ログに対するフィードバックをJSON形式で生成
    /// - Parameter input: ユーザーの入力テキスト
    /// - Returns: JSON形式のフィードバック結果
    func generateFeedbackAsJSON(for input: String) async -> Result<String, AIError> {
        logger.info("Generating JSON feedback for input")
        
        let result = await generateFeedback(for: input)
        
        switch result {
        case .success(let feedback):
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted // デバッグ用の整形
                let jsonData = try encoder.encode(feedback.toJSONResponse())
                let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
                logger.info("Feedback generated as JSON successfully (size: \(jsonString.count) bytes)")
                return .success(jsonString)
            } catch {
                logger.error("Failed to encode feedback as JSON: \(error.localizedDescription)")
                return .failure(.unknownError("JSON encoding failed: \(error.localizedDescription)"))
            }
        case .failure(let error):
            logger.error("JSON feedback generation failed at feedback generation stage: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    /// AI機能を再初期化
    func reinitialize() async {
        logger.info("Reinitializing AI")
        
        aiService.unload()
        isInitialized = false
        lastError = nil
        
        await initialize()
    }
    
    /// AI機能を終了
    func shutdown() {
        logger.info("Shutting down AI")
        
        aiService.unload()
        isInitialized = false
        lastError = nil
    }
    
    // MARK: - Helper Methods
    
    /// 現在のAI状態を取得
    var status: AIStatus {
        if isLoading {
            return .loading
        } else if isInitialized {
            return .ready
        } else if lastError != nil {
            return .error
        } else {
            return .notInitialized
        }
    }
}

// MARK: - AIStatus

/// AI機能の状態
enum AIStatus {
    case notInitialized
    case loading
    case ready
    case error
    
    var description: String {
        switch self {
        case .notInitialized:
            return "未初期化"
        case .loading:
            return "読み込み中"
        case .ready:
            return "準備完了"
        case .error:
            return "エラー"
        }
    }
}