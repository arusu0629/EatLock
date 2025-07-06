import Foundation
import os.log

// MARK: - AIEngine

/// AI推論エンジン - 高度なエラーハンドリング、タイムアウト、パフォーマンス測定機能を提供
@MainActor
final class AIEngine: ObservableObject {
    
    // MARK: - Properties
    
    static let shared = AIEngine()
    
    @Published var isInitialized = false
    @Published var isProcessing = false
    @Published var lastError: AIEngineError?
    @Published var performanceMetrics: PerformanceMetrics?
    
    private let logger = Logger(subsystem: "com.eatlock.ai", category: "AIEngine")
    private let aiService: AIService
    private let timeoutDuration: TimeInterval = 10.0
    private let performanceMonitor = PerformanceMonitor()
    
    // MARK: - Initialization
    
    private init() {
        // 既存の AIService を使用
        self.aiService = LocalAIService()
        logger.info("AIEngine initialized")
    }
    
    // MARK: - Public Methods
    
    /// AI推論エンジンを初期化
    func initialize() async {
        guard !isInitialized else {
            logger.info("AIEngine already initialized")
            return
        }
        
        isProcessing = true
        lastError = nil
        
        logger.info("Starting AIEngine initialization")
        
        do {
            let result = try await withTimeout(timeoutDuration) {
                await aiService.initialize()
            }
            
            switch result {
            case .success:
                isInitialized = true
                logger.info("AIEngine initialization successful")
            case .failure(let error):
                lastError = .serviceError(error)
                logger.error("AIEngine initialization failed: \(error.localizedDescription)")
            }
            
        } catch {
            lastError = .timeout
            logger.error("AIEngine initialization timed out")
        }
        
        isProcessing = false
    }
    
    /// フィードバックを生成（メイン機能）
    /// - Parameter text: 入力テキスト
    /// - Returns: AIフィードバック結果
    func generateFeedback(text: String) async -> Result<AIFeedback, AIEngineError> {
        guard isInitialized else {
            let error = AIEngineError.notInitialized
            logger.error("AIEngine not initialized")
            lastError = error
            return .failure(error)
        }
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let error = AIEngineError.invalidInput
            logger.error("Invalid input provided")
            lastError = error
            return .failure(error)
        }
        
        isProcessing = true
        lastError = nil
        
        logger.info("Starting feedback generation")
        
        // パフォーマンス測定開始
        performanceMonitor.startMeasurement()
        
        do {
            let result = try await withTimeout(timeoutDuration) {
                await aiService.generateFeedback(for: text)
            }
            
            // パフォーマンス測定終了
            let metrics = performanceMonitor.endMeasurement()
            performanceMetrics = metrics
            
            // ログにパフォーマンス情報を記録
            logger.info("Feedback generation completed - Duration: \(metrics.formattedDuration), Memory: \(metrics.formattedMemoryUsage)")
            
            switch result {
            case .success(let feedback):
                logger.info("Feedback generated successfully")
                isProcessing = false
                return .success(feedback)
            case .failure(let error):
                let engineError = AIEngineError.serviceError(error)
                lastError = engineError
                logger.error("Feedback generation failed: \(error.localizedDescription)")
                isProcessing = false
                return .failure(engineError)
            }
            
        } catch {
            // タイムアウト処理
            let engineError = AIEngineError.timeout
            lastError = engineError
            logger.error("Feedback generation timed out")
            isProcessing = false
            return .failure(engineError)
        }
    }
    
    /// AIエンジンを再初期化
    func reinitialize() async {
        logger.info("Reinitializing AIEngine")
        
        shutdown()
        await initialize()
    }
    
    /// AIエンジンを終了
    func shutdown() {
        logger.info("Shutting down AIEngine")
        
        aiService.unload()
        isInitialized = false
        isProcessing = false
        lastError = nil
        performanceMetrics = nil
    }
    
    // MARK: - Status Properties
    
    /// 現在のエンジン状態
    var status: AIEngineStatus {
        if isProcessing {
            return .processing
        } else if isInitialized {
            return .ready
        } else if lastError != nil {
            return .error
        } else {
            return .notInitialized
        }
    }
    
    /// 利用可能かどうか
    var isAvailable: Bool {
        return isInitialized && !isProcessing
    }
}

// MARK: - AIEngineError

/// AIエンジン固有のエラー
enum AIEngineError: Error, LocalizedError {
    case notInitialized
    case invalidInput
    case timeout
    case serviceError(AIError)
    case resourceExhausted
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "AIエンジンが初期化されていません"
        case .invalidInput:
            return "無効な入力が提供されました"
        case .timeout:
            return "処理がタイムアウトしました"
        case .serviceError(let aiError):
            return "AIサービスエラー: \(aiError.localizedDescription)"
        case .resourceExhausted:
            return "リソースが不足しています"
        case .cancelled:
            return "処理がキャンセルされました"
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .notInitialized, .timeout, .resourceExhausted:
            return true
        case .invalidInput, .cancelled:
            return false
        case .serviceError:
            return true
        }
    }
}

// MARK: - AIEngineStatus

/// AIエンジンの状態
enum AIEngineStatus {
    case notInitialized
    case processing
    case ready
    case error
    
    var description: String {
        switch self {
        case .notInitialized:
            return "未初期化"
        case .processing:
            return "処理中"
        case .ready:
            return "準備完了"
        case .error:
            return "エラー"
        }
    }
}

// MARK: - PerformanceMetrics

/// パフォーマンス測定結果
struct PerformanceMetrics {
    /// 処理時間（ミリ秒）
    let duration: Double
    /// メモリ使用量（MB）
    let memoryUsage: Double
    /// 測定開始時刻
    let startTime: Date
    /// 測定終了時刻
    let endTime: Date
    
    var formattedDuration: String {
        return String(format: "%.2fms", duration)
    }
    
    var formattedMemoryUsage: String {
        return String(format: "%.2fMB", memoryUsage)
    }
}

// MARK: - PerformanceMonitor

/// パフォーマンス監視クラス
private final class PerformanceMonitor {
    private var startTime: Date?
    private var startMemory: Double?
    private let logger = Logger(subsystem: "com.eatlock.ai", category: "PerformanceMonitor")
    
    func startMeasurement() {
        startTime = Date()
        startMemory = getCurrentMemoryUsage()
        logger.debug("Performance measurement started")
    }
    
    func endMeasurement() -> PerformanceMetrics {
        let endTime = Date()
        let endMemory = getCurrentMemoryUsage()
        
        let duration = (endTime.timeIntervalSince(startTime ?? endTime)) * 1000 // ミリ秒
        let memoryUsage = max(0, endMemory - (startMemory ?? 0))
        
        logger.debug("Performance measurement completed: \(duration)ms, \(memoryUsage)MB")
        
        return PerformanceMetrics(
            duration: duration,
            memoryUsage: memoryUsage,
            startTime: startTime ?? endTime,
            endTime: endTime
        )
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // MB
        } else {
            logger.warning("Failed to get memory usage")
            return 0.0
        }
    }
}

// MARK: - Timeout Utility

/// タイムアウト付きの非同期処理
private func withTimeout<T>(
    _ timeout: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(for: .seconds(timeout))
            throw AIEngineError.timeout
        }
        
        guard let result = try await group.next() else {
            throw AIEngineError.timeout
        }
        
        group.cancelAll()
        return result
    }
}