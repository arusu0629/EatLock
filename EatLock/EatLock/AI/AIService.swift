import Foundation
import CoreML
import os.log

// MARK: - AIService Protocol

/// AI推論サービスのプロトコル
protocol AIService {
    /// AIモデルの初期化状態
    var isInitialized: Bool { get }
    
    /// AIモデルを初期化
    func initialize() async -> Result<Void, AIError>
    
    /// 行動ログに対してAIフィードバックを生成
    /// - Parameter input: ユーザーの入力テキスト
    /// - Returns: AIフィードバック結果
    func generateFeedback(for input: String) async -> Result<AIFeedback, AIError>
    
    /// AIモデルをアンロード
    func unload()
}

// MARK: - AIFeedback Model

/// AIフィードバック結果
struct AIFeedback {
    /// フィードバックメッセージ
    let message: String
    
    /// 推定された防いだカロリー数（0以上）
    let preventedCalories: Int
    
    /// フィードバックの種類
    let type: FeedbackType
    
    /// 生成日時
    let generatedAt: Date
    
    enum FeedbackType {
        case encouragement  // 励まし
        case achievement    // 達成
        case support       // サポート
        case warning       // 注意
    }
}

// MARK: - AIError

/// AI処理関連のエラー
enum AIError: Error, LocalizedError {
    case modelNotFound
    case modelInitializationFailed
    case modelNotInitialized
    case inputProcessingFailed
    case predictionFailed
    case resourceNotAvailable
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "AIモデルが見つかりません"
        case .modelInitializationFailed:
            return "AIモデルの初期化に失敗しました"
        case .modelNotInitialized:
            return "AIモデルが初期化されていません"
        case .inputProcessingFailed:
            return "入力の処理に失敗しました"
        case .predictionFailed:
            return "予測の実行に失敗しました"
        case .resourceNotAvailable:
            return "リソースが利用できません"
        case .unknownError(let message):
            return "不明なエラー: \(message)"
        }
    }
}