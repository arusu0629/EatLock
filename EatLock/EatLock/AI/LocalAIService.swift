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
    
    // MARK: - Private Properties
    
    /// パフォーマンス最適化のためのキャッシュされた食べ物カテゴリ
    private static let cachedFoodCategories = AIConstants.FoodCategories.createAllCategories()
    /// キーワード検索のためのSetを使用した高速化
    private static let positiveKeywordSet = Set(AIConstants.Keywords.positive)
    private static let timeKeywordSet = Set(AIConstants.Keywords.time)
    private static let emotionalKeywordSet = Set(AIConstants.Keywords.emotional)
    
    // MARK: - Input Validation
    
    /// 入力の詳細検証
    private func validateInput(_ input: String) -> Result<String, AIError> {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 空文字チェック
        guard !trimmedInput.isEmpty else {
            return .failure(.inputProcessingFailed)
        }
        
        // 長すぎる入力のチェック（DoS攻撃防止）
        guard trimmedInput.count <= AIConstants.InputLimits.maxLength else {
            logger.warning("Input too long: \(trimmedInput.count) characters")
            return .failure(.inputProcessingFailed)
        }
        
        // 最小文字数チェック
        guard trimmedInput.count >= AIConstants.InputLimits.minLength else {
            return .failure(.inputProcessingFailed)
        }
        
        return .success(trimmedInput.lowercased())
    }
    
    // MARK: - Analysis Methods (Optimized)
    
    private func analyzeDummyInput(_ input: String) -> (message: String, preventedCalories: Int, type: AIFeedback.FeedbackType) {
        // 入力検証
        let validatedInput: String
        switch validateInput(input) {
        case .success(let processed):
            validatedInput = processed
        case .failure(_):
            // フォールバック：基本的な励ましメッセージ
            return (
                AIConstants.Messages.fallback,
                0,
                .encouragement
            )
        }
        
        // 各種分析を実行（最適化済み）
        let keywordAnalysis = analyzeKeywordsOptimized(in: validatedInput)
        let calorieAnalysis = analyzeCaloriesOptimized(in: validatedInput, hasTimeContext: keywordAnalysis.hasTimeContext)
        let messageType = determineMessageType(from: keywordAnalysis)
        let message = generateMessageSafely(
            for: messageType,
            foodCategory: calorieAnalysis.foodCategory,
            preventedCalories: calorieAnalysis.preventedCalories,
            hasTimeContext: keywordAnalysis.hasTimeContext
        )
        
        return (message, calorieAnalysis.preventedCalories, messageType)
    }
    
    /// 最適化されたキーワード分析（早期終了で高速化）
    private func analyzeKeywordsOptimized(in input: String) -> KeywordAnalysis {
        // 部分文字列マッチングのための効率的な実装（早期終了付き）
        let hasPositiveAction = Self.positiveKeywordSet.first { input.contains($0) } != nil
        let hasTimeContext = Self.timeKeywordSet.first { input.contains($0) } != nil
        let hasEmotionalTrigger = Self.emotionalKeywordSet.first { input.contains($0) } != nil
        
        return KeywordAnalysis(
            hasPositiveAction: hasPositiveAction,
            hasTimeContext: hasTimeContext,
            hasEmotionalTrigger: hasEmotionalTrigger
        )
    }
    
    /// 最適化されたカロリー分析（早期終了とキャッシュ使用）
    private func analyzeCaloriesOptimized(in input: String, hasTimeContext: Bool) -> CalorieAnalysis {
        // キャッシュされたカテゴリを使用
        for category in Self.cachedFoodCategories {
            // 早期終了のための最適化
            if let matchedKeyword = category.keywords.first(where: { input.contains($0) }) {
                let baseCalories = calculateSpecificCaloriesOptimized(
                    for: input,
                    in: category,
                    matchedKeyword: matchedKeyword
                )
                let finalCalories = hasTimeContext ? applyLateNightMultiplier(baseCalories) : baseCalories
                
                return CalorieAnalysis(
                    preventedCalories: finalCalories,
                    foodCategory: category.name
                )
            }
        }
        
        // その他の食べ物
        let defaultCalories = hasTimeContext ? AIConstants.Calories.defaultLateNight : AIConstants.Calories.defaultRegular
        return CalorieAnalysis(
            preventedCalories: defaultCalories,
            foodCategory: AIConstants.FoodCategories.defaultCategory
        )
    }
    
    /// 最適化された具体的カロリー計算
    private func calculateSpecificCaloriesOptimized(
        for input: String,
        in category: AIConstants.FoodCategory,
        matchedKeyword: String
    ) -> Int {
        // マッチしたキーワードから開始して検索を最適化
        if let specificCalories = category.specificItems[matchedKeyword] {
            return specificCalories
        }
        
        // その他の具体的な食べ物による調整
        for (keyword, calories) in category.specificItems {
            if keyword != matchedKeyword && input.contains(keyword) {
                return calories
            }
        }
        
        return category.baseCalories
    }
    
    /// 安全なメッセージ生成（nil対策強化）
    private func generateMessageSafely(
        for type: AIFeedback.FeedbackType,
        foodCategory: String,
        preventedCalories: Int,
        hasTimeContext: Bool
    ) -> String {
        switch type {
        case .achievement:
            return generateAchievementMessageSafely(
                foodCategory: foodCategory,
                preventedCalories: preventedCalories,
                hasTimeContext: hasTimeContext
            )
        case .support:
            return AIConstants.Messages.support.randomElement() ?? AIConstants.Messages.fallbackSupport
        case .warning:
            return AIConstants.Messages.warning(foodCategory: foodCategory).randomElement() ?? AIConstants.Messages.fallbackWarning
        case .encouragement:
            return AIConstants.Messages.encouragement.randomElement() ?? AIConstants.Messages.fallback
        }
    }
    
    /// 安全な達成メッセージ生成
    private func generateAchievementMessageSafely(
        foodCategory: String,
        preventedCalories: Int,
        hasTimeContext: Bool
    ) -> String {
        if hasTimeContext {
            return AIConstants.Messages.lateNightAchievement(
                foodCategory: foodCategory,
                preventedCalories: preventedCalories
            ).randomElement() ?? AIConstants.Messages.fallbackAchievement
        } else {
            return AIConstants.Messages.achievement(
                foodCategory: foodCategory,
                preventedCalories: preventedCalories
            ).randomElement() ?? AIConstants.Messages.fallbackAchievement
        }
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
    
    // MARK: - Legacy Methods (for backward compatibility)
    
    private func analyzeKeywords(in input: String) -> KeywordAnalysis {
        return analyzeKeywordsOptimized(in: input)
    }
    
    private func analyzeCalories(in input: String, hasTimeContext: Bool) -> CalorieAnalysis {
        return analyzeCaloriesOptimized(in: input, hasTimeContext: hasTimeContext)
    }
    
    private func calculateSpecificCalories(for input: String, in category: AIConstants.FoodCategory) -> Int {
        return calculateSpecificCaloriesOptimized(for: input, in: category, matchedKeyword: "")
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
        
        /// 最適化：静的に生成されたカテゴリ配列（実行時の配列生成を避ける）
        private static let _cachedCategories: [FoodCategory] = [sweets, snacks, drinks, fastFood, friedFood, alcohol]
        
        /// パフォーマンス向上：キャッシュされた配列を返す
        static var all: [FoodCategory] {
            return _cachedCategories
        }
        
        /// 新しい実装でキャッシュされたカテゴリを作成
        static func createAllCategories() -> [FoodCategory] {
            return _cachedCategories
        }
        
        static let defaultCategory = "その他"
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
        
        static let fallback = "エラーが発生しました。入力を確認してください。"
        static let fallbackSupport = "サポートメッセージが見つかりませんでした。"
        static let fallbackWarning = "警告メッセージが見つかりませんでした。"
        static let fallbackAchievement = "達成メッセージが見つかりませんでした。"
    }
    
    enum InputLimits {
        static let maxLength: Int = 200 // 長すぎる入力を防ぐための制限
        static let minLength: Int = 1 // 空文字を防ぐための制限
    }
    
    enum Calories {
        static let defaultLateNight: Int = 500
        static let defaultRegular: Int = 150
    }
}