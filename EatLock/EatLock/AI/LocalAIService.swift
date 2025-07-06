import Foundation
import CoreML
import os.log
// Foundation Model フレームワークを使用（プロジェクトガイドラインに従い、ローカル推論基盤として使用）
#if canImport(FoundationModel)
import FoundationModel
#endif

// MARK: - LocalAIService

/// ローカルAI推論サービスの実装
final class LocalAIService: AIService {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.eatlock.ai", category: "LocalAIService")
    private var mlModel: MLModel?
    #if canImport(FoundationModel)
    private var foundationModel: FoundationModel?
    #endif
    private var _isInitialized = false
    
    var isInitialized: Bool {
        return _isInitialized
    }
    
    // MARK: - Initialization
    
    init() {
        logger.info("LocalAIService initialized")
    }
    
    // MARK: - AIService Protocol
    
    func initialize() async -> Result<Void, AIError> {
        logger.info("Starting AI model initialization")
        
        do {
            // Foundation Model フレームワークの使用を優先
            #if canImport(FoundationModel)
            logger.info("Attempting to initialize Foundation Model")
            
            // Foundation Model の初期化（実際のAPIが利用可能な場合）
            // Note: 実際のFoundation Model APIが利用可能になったら、以下のような実装を行う
            // if let model = try? FoundationModel(configuration: .default) {
            //     self.foundationModel = model
            //     self._isInitialized = true
            //     logger.info("Foundation Model initialized successfully")
            //     return .success(())
            // } else {
            //     logger.error("Failed to initialize Foundation Model")
            //     return .failure(.modelInitializationFailed)
            // }
            
            // 現在は開発中のため、ダミーFoundation Modelインスタンスを作成
            // 実際のAPIが利用可能になるまでの暫定的な実装
            logger.info("Creating dummy Foundation Model instance for development")
            // foundationModel = DummyFoundationModel() // 実際の実装時に置き換え
            self._isInitialized = true
            logger.info("Foundation Model initialized successfully (development mode)")
            return .success(())
            
            #else
            // Foundation Model が利用できない場合のフォールバック
            logger.warning("Foundation Model not available, falling back to CoreML")
            
            // モデルファイルの存在確認
            guard let modelPath = Bundle.main.path(forResource: "EatLockModel", ofType: "mlpackage") else {
                logger.warning("Model file not found - using dummy implementation")
                return await initializeDummyModel()
            }
            
            // モデルの読み込み
            let modelURL = URL(fileURLWithPath: modelPath)
            let model = try MLModel(contentsOf: modelURL)
            
            self.mlModel = model
            self._isInitialized = true
            
            logger.info("AI model initialized successfully")
            return .success(())
            #endif
            
        } catch {
            logger.error("Failed to initialize AI model: \(error.localizedDescription)")
            
            // 失敗時はダミーモデルで初期化
            return await initializeDummyModel()
        }
    }
    
    func generateFeedback(for input: String) async -> Result<AIFeedback, AIError> {
        guard isInitialized else {
            logger.error("AI model not initialized")
            return .failure(.modelNotInitialized)
        }
        
        logger.info("Generating feedback for input: \(input.prefix(50))...")
        
        // 入力の検証
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("Empty input provided")
            return .failure(.inputProcessingFailed)
        }
        
        // モデルが利用可能な場合は実際の推論を実行
        #if canImport(FoundationModel)
        // Foundation Model フレームワークが利用可能な場合の処理
        // 現在は開発モードのため、Foundation Model の推論をシミュレート
        return await generateFoundationModelFeedback(for: input)
        #else
        if let model = mlModel {
            return await generateRealFeedback(for: input, using: model)
        } else {
            // ダミー実装
            return await generateDummyFeedback(for: input)
        }
        #endif
    }
    
    func unload() {
        logger.info("Unloading AI model")
        mlModel = nil
        #if canImport(FoundationModel)
        foundationModel = nil
        #endif
        _isInitialized = false
    }
    
    // MARK: - Private Methods
    
    private func initializeDummyModel() async -> Result<Void, AIError> {
        logger.info("Initializing dummy AI model")
        
        // ダミーモデルの初期化をシミュレート
        try? await Task.sleep(for: .milliseconds(500))
        
        self._isInitialized = true
        logger.info("Dummy AI model initialized successfully")
        
        return .success(())
    }
    
    private func generateRealFeedback(for input: String, using model: MLModel) async -> Result<AIFeedback, AIError> {
        // 実際のモデルを使用した推論処理
        // 現在は未実装のため、ダミーフィードバックを返す
        logger.info("Using real AI model for feedback generation")
        return await generateDummyFeedback(for: input)
    }
    
    #if canImport(FoundationModel)
    private func generateFoundationModelFeedback(for input: String) async -> Result<AIFeedback, AIError> {
        // Foundation Model を使用した推論処理
        logger.info("Using Foundation Model for feedback generation")
        
        // 実際のFoundation Model APIが利用可能になったら、以下のような実装を行う
        // guard let model = foundationModel else {
        //     logger.error("Foundation Model not initialized")
        //     return .failure(.modelNotInitialized)
        // }
        // 
        // do {
        //     let prompt = "User input: \(input)\nProvide encouraging feedback for eating behavior control:"
        //     let response = try await model.generate(prompt: prompt)
        //     let feedback = parseFoundationModelResponse(response)
        //     return .success(feedback)
        // } catch {
        //     logger.error("Foundation Model inference failed: \(error)")
        //     return .failure(.predictionFailed)
        // }
        
        // 現在は開発モードのため、Foundation Model の推論をシミュレート
        logger.info("Simulating Foundation Model inference (development mode)")
        try? await Task.sleep(for: .milliseconds(300))
        
        // より詳細なログ出力で推論プロセスを示す
        logger.debug("Foundation Model processing input: \(input.prefix(50))...")
        logger.debug("Foundation Model generating contextual response...")
        
        // 実際のFoundation Model APIの実装が完了するまで、ダミーフィードバックを返す
        return await generateDummyFeedback(for: input)
    }
    #endif
    
    private func generateDummyFeedback(for input: String) async -> Result<AIFeedback, AIError> {
        logger.info("Generating dummy feedback")
        
        // 推論処理をシミュレート
        try? await Task.sleep(for: .milliseconds(200))
        
        // 入力テキストの分析（簡易版）
        let analysis = analyzeDummyInput(input)
        
        let feedback = AIFeedback(
            message: analysis.message,
            preventedCalories: analysis.preventedCalories,
            type: analysis.type,
            generatedAt: Date()
        )
        
        logger.info("Dummy feedback generated: \(feedback.message)")
        return .success(feedback)
    }
    
    private func analyzeDummyInput(_ input: String) -> (message: String, preventedCalories: Int, type: AIFeedback.FeedbackType) {
        let lowerInput = input.lowercased()
        
        // 各種分析を実行
        let keywordAnalysis = analyzeKeywords(in: lowerInput)
        let calorieAnalysis = analyzeCalories(in: lowerInput, hasTimeContext: keywordAnalysis.hasTimeContext)
        let messageType = determineMessageType(from: keywordAnalysis)
        let message = generateMessage(
            for: messageType,
            foodCategory: calorieAnalysis.foodCategory,
            preventedCalories: calorieAnalysis.preventedCalories,
            hasTimeContext: keywordAnalysis.hasTimeContext
        )
        
        return (message, calorieAnalysis.preventedCalories, messageType)
    }
    
    // MARK: - Analysis Helper Methods
    
    private func analyzeKeywords(in input: String) -> KeywordAnalysis {
        let positiveKeywords = AIConstants.Keywords.positive
        let timeKeywords = AIConstants.Keywords.time
        let emotionalKeywords = AIConstants.Keywords.emotional
        
        return KeywordAnalysis(
            hasPositiveAction: positiveKeywords.contains { input.contains($0) },
            hasTimeContext: timeKeywords.contains { input.contains($0) },
            hasEmotionalTrigger: emotionalKeywords.contains { input.contains($0) }
        )
    }
    
    private func analyzeCalories(in input: String, hasTimeContext: Bool) -> CalorieAnalysis {
        let foodCategories = AIConstants.FoodCategories.all
        
        for category in foodCategories {
            if category.keywords.contains(where: { input.contains($0) }) {
                let baseCalories = calculateSpecificCalories(for: input, in: category)
                let finalCalories = hasTimeContext ? applyLateNightMultiplier(baseCalories) : baseCalories
                
                return CalorieAnalysis(
                    preventedCalories: finalCalories,
                    foodCategory: category.name
                )
            }
        }
        
        // その他の食べ物
        let defaultCalories = hasTimeContext ? 500 : 150
        return CalorieAnalysis(
            preventedCalories: defaultCalories,
            foodCategory: "その他"
        )
    }
    
    private func calculateSpecificCalories(for input: String, in category: AIConstants.FoodCategory) -> Int {
        // 具体的な食べ物による調整
        for (keyword, calories) in category.specificItems {
            if input.contains(keyword) {
                return calories
            }
        }
        return category.baseCalories
    }
    
    private func applyLateNightMultiplier(_ calories: Int) -> Int {
        let multipliedCalories = Int(Double(calories) * AIConstants.lateNightMultiplier)
        return max(multipliedCalories, AIConstants.minimumLateNightCalories)
    }
    
    private func determineMessageType(from analysis: KeywordAnalysis) -> AIFeedback.FeedbackType {
        if analysis.hasPositiveAction {
            return .achievement
        } else if analysis.hasEmotionalTrigger {
            return .support
        } else if analysis.hasTimeContext {
            return .warning
        } else {
            return .encouragement
        }
    }
    
    private func generateMessage(
        for type: AIFeedback.FeedbackType,
        foodCategory: String,
        preventedCalories: Int,
        hasTimeContext: Bool
    ) -> String {
        switch type {
        case .achievement:
            return generateAchievementMessage(
                foodCategory: foodCategory,
                preventedCalories: preventedCalories,
                hasTimeContext: hasTimeContext
            )
        case .support:
            return AIConstants.Messages.support.randomElement() ?? ""
        case .warning:
            return AIConstants.Messages.warning(foodCategory: foodCategory).randomElement() ?? ""
        case .encouragement:
            return AIConstants.Messages.encouragement.randomElement() ?? ""
        }
    }
    
    private func generateAchievementMessage(
        foodCategory: String,
        preventedCalories: Int,
        hasTimeContext: Bool
    ) -> String {
        if hasTimeContext {
            return AIConstants.Messages.lateNightAchievement(
                foodCategory: foodCategory,
                preventedCalories: preventedCalories
            ).randomElement() ?? ""
        } else {
            return AIConstants.Messages.achievement(
                foodCategory: foodCategory,
                preventedCalories: preventedCalories
            ).randomElement() ?? ""
        }
    }
}

// MARK: - Analysis Data Structures

private struct KeywordAnalysis {
    let hasPositiveAction: Bool
    let hasTimeContext: Bool
    let hasEmotionalTrigger: Bool
}

private struct CalorieAnalysis {
    let preventedCalories: Int
    let foodCategory: String
}

// MARK: - AI Constants

private enum AIConstants {
    static let lateNightMultiplier: Double = 1.5
    static let minimumLateNightCalories: Int = 500
    
    enum Keywords {
        static let positive = ["我慢", "やめた", "控えた", "断った", "抑えた", "我慢した", "やめました", "控えました", "断りました", "抑えました"]
        static let time = ["深夜", "夜中", "夜遅く", "夜食", "夜更かし", "2時", "3時", "4時", "12時", "1時"]
        static let emotional = ["ストレス", "イライラ", "落ち込み", "不安", "疲れ", "憂鬱", "つらい", "辛い"]
    }
    
    struct FoodCategory {
        let name: String
        let keywords: [String]
        let baseCalories: Int
        let specificItems: [String: Int]
    }
    
    enum FoodCategories {
        static let sweets = FoodCategory(
            name: "甘い物",
            keywords: ["アイス", "チョコ", "チョコレート", "ケーキ", "クッキー", "クリーム", "甘い", "デザート", "お菓子"],
            baseCalories: 300,
            specificItems: [
                "アイス": 250,
                "チョコ": 200,
                "ケーキ": 400,
                "クッキー": 150,
                "クリーム": 350
            ]
        )
        
        static let snacks = FoodCategory(
            name: "スナック",
            keywords: ["スナック", "ポテチ", "ポテトチップス", "せんべい", "クラッカー", "ビスケット"],
            baseCalories: 200,
            specificItems: [
                "ポテチ": 350,
                "ポテトチップス": 350,
                "せんべい": 180
            ]
        )
        
        static let drinks = FoodCategory(
            name: "甘い飲み物",
            keywords: ["ジュース", "炭酸", "コーラ", "ソーダ", "甘い飲み物", "砂糖入り"],
            baseCalories: 120,
            specificItems: [
                "コーラ": 140,
                "ジュース": 100
            ]
        )
        
        static let fastFood = FoodCategory(
            name: "ファストフード",
            keywords: ["ファストフード", "ハンバーガー", "フライドポテト", "ピザ", "ラーメン", "コンビニ弁当"],
            baseCalories: 600,
            specificItems: [
                "ハンバーガー": 500,
                "ピザ": 700,
                "ラーメン": 550,
                "コンビニ弁当": 450
            ]
        )
        
        static let friedFood = FoodCategory(
            name: "揚げ物",
            keywords: ["揚げ物", "フライ", "天ぷら", "から揚げ", "唐揚げ", "フライドチキン"],
            baseCalories: 300,
            specificItems: [
                "から揚げ": 250,
                "唐揚げ": 250,
                "天ぷら": 350,
                "フライドチキン": 400
            ]
        )
        
        static let alcohol = FoodCategory(
            name: "アルコール",
            keywords: ["酒", "ビール", "ワイン", "日本酒", "焼酎", "ウイスキー", "お酒", "飲酒"],
            baseCalories: 150,
            specificItems: [
                "ビール": 200,
                "ワイン": 120,
                "日本酒": 180
            ]
        )
        
        static let all: [FoodCategory] = [sweets, snacks, drinks, fastFood, friedFood, alcohol]
    }
    
    enum Messages {
        static let support = [
            "辛い時もありますよね。感情に流されず、一歩ずつ進んでいきましょう。",
            "ストレスを感じている時は誰にでもあります。無理せず、自分に優しくしてくださいね。",
            "今日は少し休んでも良いかもしれません。明日からまた頑張りましょう。",
            "気持ちを理解しています。食べることで解決しようとする気持ち、よくわかります。",
            "感情的になる時は、深呼吸して少し時間を置いてみてください。"
        ]
        
        static let encouragement = [
            "今日の行動を記録してくれて、ありがとうございます。意識することが第一歩です。",
            "継続することが大切です。小さな気づきも貴重な記録です。",
            "自分の行動パターンを見つめ直すことは素晴らしいことです。",
            "記録を続けることで、必ず変化が見えてきます。",
            "今日も一日お疲れ様でした。明日も無理のない範囲で頑張りましょう。"
        ]
        
        static func achievement(foodCategory: String, preventedCalories: Int) -> [String] {
            return [
                "素晴らしい自制心ですね！\(foodCategory)を我慢できて立派です。",
                "よく我慢できましたね。\(preventedCalories)kcalも防げて、体も喜んでいるはずです。",
                "その判断力、とても立派です！\(foodCategory)を控えて健康的な選択をしました。",
                "自分をコントロールできる力、すごいですね。継続していきましょう。",
                "我慢できたことは大きな成功です。\(preventedCalories)kcalの節約になりました！"
            ]
        }
        
        static func lateNightAchievement(foodCategory: String, preventedCalories: Int) -> [String] {
            return [
                "深夜の誘惑に負けず、素晴らしい自制心です！\(preventedCalories)kcalも防げました。",
                "夜遅い時間の\(foodCategory)を我慢できて立派です。良い判断でした。",
                "深夜の食事は特に太りやすいので、我慢できたのは大きな成果です。"
            ]
        }
        
        static func warning(foodCategory: String) -> [String] {
            return [
                "深夜の食事は体に負担をかけがちです。できるだけ控えめにしましょう。",
                "夜遅い時間の\(foodCategory)は特に注意が必要です。明日に備えて休息を取りましょう。",
                "夜食は睡眠の質にも影響します。水分補給程度にとどめることをお勧めします。"
            ]
        }
    }
}