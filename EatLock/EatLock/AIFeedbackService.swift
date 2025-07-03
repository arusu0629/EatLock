import Foundation
import NaturalLanguage

/// ローカルAIフィードバック処理サービス
class AIFeedbackService {
    static let shared = AIFeedbackService()
    
    private init() {}
    
    /// 行動ログに対してAIフィードバックを生成
    func generateFeedback(for logText: String) async -> (feedback: String, preventedCalories: Int, isSuccessful: Bool) {
        // テキスト解析
        let sentiment = analyzeSentiment(logText)
        let keywords = extractKeywords(logText)
        
        // 成功/失敗の判定
        let isSuccessful = determineSuccess(from: keywords, sentiment: sentiment)
        
        // 防いだカロリー数の推定
        let preventedCalories = estimatePreventedCalories(from: keywords, isSuccessful: isSuccessful)
        
        // フィードバック生成
        let feedback = generatePersonalizedFeedback(
            isSuccessful: isSuccessful,
            preventedCalories: preventedCalories,
            keywords: keywords,
            sentiment: sentiment
        )
        
        return (feedback, preventedCalories, isSuccessful)
    }
    
    /// センチメント分析
    private func analyzeSentiment(_ text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let sentiment = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore).0
        return Double(sentiment?.rawValue ?? "0") ?? 0.0
    }
    
    /// キーワード抽出
    private func extractKeywords(_ text: String) -> [String] {
        let successKeywords = ["我慢", "止め", "控え", "やめ", "抑え", "セーブ", "断念", "回避", "我慢でき", "やめられ"]
        let foodKeywords = ["アイス", "ケーキ", "チョコ", "お菓子", "スイーツ", "デザート", "ジュース", "炭酸", "ラーメン", "揚げ物", "ポテチ", "クッキー"]
        let timeKeywords = ["夜中", "深夜", "夜", "寝る前", "朝", "昼", "夕方", "間食"]
        let struggleKeywords = ["誘惑", "我慢中", "葛藤", "迷っ", "欲しい", "食べたい"]
        
        let lowercasedText = text.lowercased()
        var foundKeywords: [String] = []
        
        for keyword in successKeywords + foodKeywords + timeKeywords + struggleKeywords {
            if lowercasedText.contains(keyword) {
                foundKeywords.append(keyword)
            }
        }
        
        return foundKeywords
    }
    
    /// 成功/失敗の判定
    private func determineSuccess(from keywords: [String], sentiment: Double) -> Bool {
        let successKeywords = ["我慢", "止め", "控え", "やめ", "抑え", "セーブ", "断念", "回避", "我慢でき", "やめられ"]
        let failureKeywords = ["食べ過ぎ", "食べてしまっ", "失敗", "だめ", "後悔"]
        
        let hasSuccessKeyword = keywords.contains { successKeywords.contains($0) }
        let hasFailureKeyword = keywords.contains { failureKeywords.contains($0) }
        
        // 失敗キーワードがある場合は失敗
        if hasFailureKeyword {
            return false
        }
        
        // 成功キーワードがあるか、センチメントが中性以上なら成功とみなす
        return hasSuccessKeyword || sentiment >= -0.3
    }
    
    /// 防いだカロリー数の推定
    private func estimatePreventedCalories(from keywords: [String], isSuccessful: Bool) -> Int {
        guard isSuccessful else { return 0 }
        
        let calorieMap: [String: Int] = [
            "アイス": 200,
            "ケーキ": 350,
            "チョコ": 150,
            "お菓子": 200,
            "スイーツ": 300,
            "デザート": 250,
            "ジュース": 150,
            "炭酸": 120,
            "ラーメン": 600,
            "揚げ物": 400,
            "ポテチ": 300,
            "クッキー": 180
        ]
        
        var totalCalories = 0
        for keyword in keywords {
            if let calories = calorieMap[keyword] {
                totalCalories += calories
            }
        }
        
        // キーワードが見つからない場合のデフォルト値
        return totalCalories > 0 ? totalCalories : Int.random(in: 100...300)
    }
    
    /// パーソナライズされたフィードバック生成
    private func generatePersonalizedFeedback(
        isSuccessful: Bool,
        preventedCalories: Int,
        keywords: [String],
        sentiment: Double
    ) -> String {
        if isSuccessful {
            let successMessages = [
                "素晴らしい判断です！\(preventedCalories) kcal防ぐことができました 🎉",
                "よく我慢できましたね！\(preventedCalories) kcalの節約になりました ✨",
                "その意志力、素敵です！\(preventedCalories) kcal分、体が喜んでいます 😊",
                "立派な選択でした！\(preventedCalories) kcal防いで、健康に一歩近づきました 💪",
                "すごいです！\(preventedCalories) kcal分の誘惑に勝ちました 🌟",
                "素晴らしい自制心です！\(preventedCalories) kcal防げて気持ちもすっきりですね ✨"
            ]
            return successMessages.randomElement() ?? successMessages[0]
        } else {
            let supportMessages = [
                "大丈夫です、次回は一緒に頑張りましょう 💪 小さな一歩から始めることが大切です",
                "今日は難しい日だったんですね 😌 明日は新しい機会です、応援しています！",
                "時には自分に優しくすることも必要です ✨ 次回のチャレンジを待っています",
                "完璧でなくても大丈夫 😊 継続することが一番重要です",
                "誰にでもある日です 🤗 次はきっとうまくいきますよ",
                "振り返りができただけでも立派です 🌱 次に向けて準備しましょう"
            ]
            return supportMessages.randomElement() ?? supportMessages[0]
        }
    }
    
    /// ログタイプの自動判定
    func determineLogType(from text: String) -> LogType {
        let keywords = extractKeywords(text)
        let sentiment = analyzeSentiment(text)
        
        let struggleKeywords = ["誘惑", "我慢中", "葛藤", "迷っ", "欲しい", "食べたい"]
        let hasStruggleKeyword = keywords.contains { struggleKeywords.contains($0) }
        
        if hasStruggleKeyword {
            return .struggle
        }
        
        let isSuccessful = determineSuccess(from: keywords, sentiment: sentiment)
        return isSuccessful ? .success : .failure
    }
}