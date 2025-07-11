//
//  LogDetailModalView.swift
//  EatLock
//
//  Created by AI Assistant on 2025/07/04.
//

import SwiftUI
import SwiftData

/// ログ詳細モーダル表示ビュー
/// Issue 28の要件に従って実装
struct LogDetailModalView: View {
    let log: ActionLog
    let repository: ActionLogRepository
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // ヘッダー情報
                    headerSection
                    
                    // 区切り線
                    Divider()
                    
                    // ログ内容
                    contentSection
                    
                    // AIフィードバック
                    aiFeedbackSection
                    
                    // 統計情報
                    statisticsSection
                    
                    // 防いだカロリー
                    caloriesSection
                    
                    // 感情タグ
                    emotionTagsSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("記録詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(log.logType.emoji)
                    .font(.largeTitle)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(.systemGray6))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.logType.displayName)
                        .font(.title2)
                        .bold()
                    
                    Text(log.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("記録内容", systemImage: "text.quote")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(repository.getSecureContent(for: log))
                .font(.body)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }
    
    // MARK: - AI Feedback Section
    
    @ViewBuilder
    private var aiFeedbackSection: some View {
        if let feedback = repository.getSecureAIFeedback(for: log) {
            VStack(alignment: .leading, spacing: 12) {
                Label("AIフィードバック", systemImage: "brain.head.profile")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text(feedback)
                    .font(.body)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("統計情報", systemImage: "chart.bar")
                .font(.headline)
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                HStack {
                    Text("記録時刻")
                    Spacer()
                    Text(DateFormatter.timeFormatter.string(from: log.timestamp))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("記録タイプ")
                    Spacer()
                    Text(log.logType.displayName)
                        .foregroundColor(.secondary)
                }
                
                if !log.emotionTags.isEmpty {
                    HStack {
                        Text("感情タグ数")
                        Spacer()
                        Text("\(log.emotionTags.count)個")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Calories Section
    
    @ViewBuilder
    private var caloriesSection: some View {
        if let calories = log.preventedCalories {
            VStack(alignment: .leading, spacing: 12) {
                Label("防いだカロリー", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(calories)")
                            .font(.title)
                            .bold()
                        
                        Text("kcal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("素晴らしい！")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                        )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Emotion Tags Section
    
    @ViewBuilder
    private var emotionTagsSection: some View {
        if !log.emotionTags.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("感情タグ", systemImage: "heart.fill")
                    .font(.headline)
                    .foregroundColor(.purple)
                
                FlowLayout(alignment: .leading, spacing: 8) {
                    ForEach(log.emotionTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.purple.opacity(0.2))
                            )
                            .foregroundColor(.purple)
                            .overlay(
                                Capsule()
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Flow Layout for Tags

/// タグ表示用のカスタムレイアウト
struct FlowLayout: Layout {
    let alignment: Alignment
    let spacing: CGFloat
    
    init(alignment: Alignment = .center, spacing: CGFloat = 8) {
        self.alignment = alignment
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, proposal: proposal).offsets
        
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + offsets[index].x, y: bounds.minY + offsets[index].y),
                proposal: ProposedViewSize(sizes[index])
            )
        }
    }
    
    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (offsets: [CGPoint], size: CGSize) {
        let containerWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var currentRowY: CGFloat = 0
        var currentRowX: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for size in sizes {
            if currentRowX + size.width > containerWidth && currentRowX > 0 {
                // 新しい行に移動
                currentRowY += currentRowHeight + spacing
                currentRowX = 0
                currentRowHeight = 0
            }
            
            offsets.append(CGPoint(x: currentRowX, y: currentRowY))
            currentRowX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
        
        totalHeight = currentRowY + currentRowHeight
        
        return (offsets: offsets, size: CGSize(width: containerWidth, height: totalHeight))
    }
}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

// MARK: - Preview

#Preview {
    let sampleLog = ActionLog(content: "夜中にアイスクリームを食べたくなったが、水を飲んで我慢することができました。最初は辛かったけど、だんだん気持ちが落ち着いてきて、最終的には満足感を得ることができました。", logType: .success)
    sampleLog.setAIFeedback("素晴らしい自制心です！水を飲むのは非常に良い対策ですね。この経験を次回も活かしてください。あなたなら必ずできます！", preventedCalories: 250)
    sampleLog.addEmotionTag("達成感")
    sampleLog.addEmotionTag("安心")
    sampleLog.addEmotionTag("満足")
    sampleLog.addEmotionTag("自信")
    
    // プレビュー用の仮のRepository
    let container = try! ModelContainer(for: ActionLog.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    let repository = ActionLogRepository(modelContext: context)
    
    return LogDetailModalView(log: sampleLog, repository: repository)
}