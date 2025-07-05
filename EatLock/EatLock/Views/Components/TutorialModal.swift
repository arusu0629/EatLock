//
//  TutorialModal.swift
//  EatLock
//
//  Created by AI Assistant on 2025/07/03.
//

import SwiftUI

struct TutorialModal: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    private let pages: [TutorialPage] = [
        TutorialPage(
            title: "EatLockへようこそ！",
            description: "暴飲暴食の抑制をサポートするアプリです。あなたの健康的な食生活をお手伝いします。",
            imageName: "heart.fill",
            color: .red
        ),
        TutorialPage(
            title: "行動を記録しよう",
            description: "食べたい衝動や我慢した体験を下部の入力欄に記録してください。AIがサポートメッセージを送ります。",
            imageName: "pencil.and.outline",
            color: .blue
        ),
        TutorialPage(
            title: "統計を確認しよう",
            description: "記録回数、防いだカロリー、継続日数を上部のカードで確認できます。",
            imageName: "chart.bar.fill",
            color: .green
        ),
        TutorialPage(
            title: "プライバシーは安全",
            description: "すべてのデータは端末内で暗号化されて保存されます。外部に送信されることはありません。",
            imageName: "lock.shield.fill",
            color: .purple
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ページコンテンツ
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        TutorialPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .frame(height: 400)
                
                // ナビゲーションボタン
                HStack {
                    if currentPage > 0 {
                        Button("戻る") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button("次へ") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .foregroundColor(.blue)
                    } else {
                        Button("始める") {
                            UserDefaults.standard.set(true, forKey: "HasSeenTutorial")
                            isPresented = false
                        }
                        .foregroundColor(.blue)
                        .bold()
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .padding()
        }
    }
}

struct TutorialPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

struct TutorialPageView: View {
    let page: TutorialPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(page.color)
            
            Text(page.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    TutorialModal(isPresented: .constant(true))
}