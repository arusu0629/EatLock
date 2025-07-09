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
            color: .red,
            accessibilityLabel: "EatLockアプリの紹介画面。心臓のアイコンが表示されています。"
        ),
        TutorialPage(
            title: "行動を記録しよう",
            description: "食べたい衝動や我慢した体験を下部の入力欄に記録してください。AIがサポートメッセージを送ります。",
            imageName: "pencil.and.outline",
            color: .blue,
            accessibilityLabel: "行動記録の説明画面。鉛筆とアウトラインのアイコンが表示されています。"
        ),
        TutorialPage(
            title: "統計を確認しよう",
            description: "記録回数、防いだカロリー、継続日数を上部のカードで確認できます。",
            imageName: "chart.bar.fill",
            color: .green,
            accessibilityLabel: "統計確認の説明画面。棒グラフのアイコンが表示されています。"
        ),
        TutorialPage(
            title: "プライバシーは安全",
            description: "すべてのデータは端末内で暗号化されて保存されます。外部に送信されることはありません。",
            imageName: "lock.shield.fill",
            color: .purple,
            accessibilityLabel: "プライバシー保護の説明画面。ロックとシールドのアイコンが表示されています。"
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .accessibilityHidden(true)
            
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
                .accessibilityLabel("チュートリアルページ \(currentPage + 1) / \(pages.count)")
                
                // ナビゲーションボタン
                HStack {
                    if currentPage > 0 {
                        Button("戻る") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.blue)
                        .accessibilityLabel("前のページに戻る")
                        .accessibilityHint("前のチュートリアルページを表示します")
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button("次へ") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .foregroundColor(.blue)
                        .accessibilityLabel("次のページに進む")
                        .accessibilityHint("次のチュートリアルページを表示します")
                    } else {
                        Button("始める") {
                            try? DataSecurityManager.shared.saveEncryptedBool(true, forKey: "HasSeenTutorial")
                            isPresented = false
                        }
                        .foregroundColor(.blue)
                        .bold()
                        .accessibilityLabel("チュートリアルを完了してアプリを開始")
                        .accessibilityHint("チュートリアルを終了してメイン画面に移動します")
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .padding()
            .accessibilityElement(children: .contain)
            .accessibilityLabel("チュートリアルモーダル")
        }
    }
}

struct TutorialPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
    let accessibilityLabel: String
}

struct TutorialPageView: View {
    let page: TutorialPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: page.imageName)
                .font(.system(size: 80, weight: .medium, design: .default))
                .foregroundColor(page.color)
                .accessibilityHidden(true)
            
            Text(page.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .dynamicTypeSize(.large ... .accessibility3)
                .accessibilityAddTraits(.isHeader)
            
            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .dynamicTypeSize(.large ... .accessibility3)
            
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(page.accessibilityLabel)
    }
}

#Preview {
    TutorialModal(isPresented: .constant(true))
}