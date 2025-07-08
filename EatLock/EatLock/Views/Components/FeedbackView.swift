//
//  FeedbackView.swift
//  EatLock
//
//  Created by AI Assistant on 2025/07/04.
//

import SwiftUI

struct FeedbackView: View {
    let feedback: AIFeedback
    @Binding var isPresented: Bool
    @State private var showingFullFeedback = false
    @State private var animateCalories = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 背景タップエリア
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissFeedback()
                }
            
            // メインコンテンツ
            VStack(spacing: 20) {
                // ヘッダー
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AIフィードバック")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(feedback.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: dismissFeedback) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                // 防いだカロリー表示（強調）
                if feedback.preventedCalories > 0 {
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.title)
                            .foregroundColor(.orange)
                            .scaleEffect(animateCalories ? 1.2 : 1.0)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("防いだカロリー")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(feedback.preventedCalories) kcal")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        // 達成感アイコン
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                    .onAppear {
                        // カロリー表示のアニメーション
                        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                            animateCalories = true
                        }
                    }
                }
                
                // フィードバックメッセージ
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(feedback.message)
                            .font(.body)
                            .lineLimit(showingFullFeedback ? nil : 5)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                        
                        if feedback.message.count > 100 {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingFullFeedback.toggle()
                                }
                            }) {
                                Text(showingFullFeedback ? "閉じる" : "続きを読む")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 200)
                
                // 生成日時
                Text("生成日時: \(formattedDate)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // アクションボタン
                Button(action: dismissFeedback) {
                    Text("閉じる")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                }
                .padding(.horizontal)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 10)
            )
            .padding()
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
    }
    
    private func dismissFeedback() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
    
    private var formattedDate: String {
        // 他のビューと一貫したフォーマットを使用
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        formatter.locale = Locale.current
        return formatter.string(from: feedback.generatedAt)
    }
}

#Preview {
    @State var isPresented = true
    
    let sampleFeedback = AIFeedback(
        message: "素晴らしい自制心です！夜中のアイスクリームを我慢できたのは本当に立派です。水を飲むという代替行動も効果的でした。この調子で健康的な生活を続けていきましょう。",
        preventedCalories: 250,
        type: .achievement,
        generatedAt: Date()
    )
    
    return ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        if isPresented {
            FeedbackView(
                feedback: sampleFeedback,
                isPresented: $isPresented
            )
        }
    }
}