//
//  FloatingAddButton.swift
//  EatLock
//
//  Created by AI Assistant on 2025/07/04.
//

import SwiftUI

/// フローティングアクションボタン
/// Issue #37の要件: プラスボタンアニメーションとインタラクティブ要素の実装
struct FloatingAddButton: View {
    let onTap: () -> Void
    
    @Binding var isInputFocused: Bool
    @Binding var scrollOffset: CGFloat
    
    @State private var isPressed = false
    @State private var isLongPressed = false
    @State private var scale: CGFloat = 1.0
    @State private var bounce: CGFloat = 0
    @State private var rotation: Double = 0
    
    private var shouldShow: Bool {
        // 入力フォーカス時は非表示、スクロールが一定以下の場合も非表示
        !isInputFocused && scrollOffset > 50
    }
    
    var body: some View {
        if shouldShow {
            Button(action: {
                handleTap()
            }) {
                ZStack {
                    // メインボタン
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // プラスアイコン
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(rotation))
                }
            }
            .scaleEffect(scale)
            .offset(y: bounce)
            .onLongPressGesture(
                minimumDuration: 0.5,
                maximumDistance: 50,
                pressing: { pressing in
                    handleLongPress(pressing: pressing)
                },
                perform: {
                    handleLongPressComplete()
                }
            )
            .transition(.asymmetric(
                insertion: .scale.combined(with: .move(edge: .bottom)),
                removal: .scale.combined(with: .move(edge: .bottom))
            ))
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: shouldShow)
            .onAppear {
                startFloatingAnimation()
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        // タップアニメーション
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 0.9
        }
        
        // ハプティックフィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // アクション実行
        onTap()
        
        // スケールを元に戻す
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
    }
    
    private func handleLongPress(pressing: Bool) {
        if pressing {
            // 長押し開始 - プレビューアニメーション
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                scale = 1.2
                rotation = 45
            }
            
            // より強いハプティックフィードバック
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            isLongPressed = true
        } else {
            // 長押し終了
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 0
            }
            
            isLongPressed = false
        }
    }
    
    private func handleLongPressComplete() {
        // 長押し完了時のアニメーション
        withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
            scale = 1.1
        }
        
        // 成功のハプティックフィードバック
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        // プレビュー効果を示すために一瞬拡大
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
        }
    }
    
    // MARK: - Animations
    
    private func startFloatingAnimation() {
        // 浮き上がりアニメーション（連続的な上下動）
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            bounce = -8
        }
    }
}

/// スクロール位置監視用のPreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// スクロール位置検出ヘルパービュー
struct ScrollOffsetReader: View {
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scroll")).minY
                )
        }
        .frame(height: 0)
    }
}

// MARK: - Preview

#Preview {
    @State var isInputFocused = false
    @State var scrollOffset: CGFloat = 100
    
    return ZStack {
        Color(.systemBackground)
            .ignoresSafeArea()
        
        VStack {
            Toggle("入力フォーカス", isOn: $isInputFocused)
                .padding()
            
            Slider(value: $scrollOffset, in: 0...200)
                .padding()
            
            Text("スクロールオフセット: \(Int(scrollOffset))")
                .padding()
            
            Spacer()
        }
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingAddButton(
                    onTap: {
                        print("フローティングボタンがタップされました")
                    },
                    isInputFocused: $isInputFocused,
                    scrollOffset: $scrollOffset
                )
                .padding(.trailing, 20)
                .padding(.bottom, 80)
            }
        }
    }
}