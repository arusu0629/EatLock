//
//  FloatingAddButton.swift
//  EatLock
//
//  Created by AI Assistant on 2025/07/04.
//

import SwiftUI

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
        Button(action: {
            handleTap()
        }) {
            ZStack {
                // メインボタン
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(
                        color: Color.blue.opacity(0.3),
                        radius: isPressed ? 8 : 12,
                        x: 0,
                        y: isPressed ? 4 : 8
                    )
                
                // プラスアイコン
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(rotation))
                
                // 長押し時のプレビューサークル
                if isLongPressed {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(scale)
                        .opacity(1 - scale + 0.5)
                }
            }
        }
        .scaleEffect(shouldShow ? (isPressed ? 0.9 : 1.0 + bounce) : 0.1)
        .opacity(shouldShow ? 1 : 0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0),
            value: shouldShow
        )
        .animation(
            .spring(response: 0.3, dampingFraction: 0.6),
            value: isPressed
        )
        .onLongPressGesture(
            minimumDuration: 0.5,
            maximumDistance: 50,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPressed = pressing
                }
                
                if pressing {
                    startLongPressAnimation()
                } else {
                    stopLongPressAnimation()
                }
            },
            perform: {
                // 長押し完了時のアクション
                handleLongPress()
            }
        )
        .onAppear {
            startFloatingAnimation()
        }
    }
    
    private func handleTap() {
        // タップ時のハプティックフィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // 回転アニメーション
        withAnimation(.easeInOut(duration: 0.3)) {
            rotation += 90
        }
        
        // タップアクションを実行
        onTap()
        
        // 回転をリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            rotation = 0
        }
    }
    
    private func handleLongPress() {
        // 長押し時のより強いハプティックフィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // 長押し完了時のアニメーション
        withAnimation(.spring(response: 0.4, dampingFraction: 0.3)) {
            bounce = 0.2
        }
        
        // 長押しアクション（通常のタップと同じ）
        onTap()
        
        // バウンスをリセット
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                bounce = 0
            }
        }
    }
    
    private func startLongPressAnimation() {
        isLongPressed = true
        
        // プレビューサークルのアニメーション
        withAnimation(.easeOut(duration: 1.0).repeatForever(autoreverses: false)) {
            scale = 1.5
        }
    }
    
    private func stopLongPressAnimation() {
        isLongPressed = false
        scale = 1.0
    }
    
    private func startFloatingAnimation() {
        // 浮き上がるアニメーション（微細な上下動）
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            bounce = 0.02
        }
    }
}

/// スクロール位置を監視するためのPreferenceKey
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// スクロール位置を検出するためのヘルパービュー
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

#Preview {
    @State var isInputFocused = false
    @State var scrollOffset: CGFloat = 100
    
    return ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                FloatingAddButton(
                    onTap: {
                        print("Floating button tapped!")
                    },
                    isInputFocused: $isInputFocused,
                    scrollOffset: $scrollOffset
                )
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
        }
        
        VStack {
            HStack {
                Text("Input Focused: \(isInputFocused ? "Yes" : "No")")
                Spacer()
                Button("Toggle Input") {
                    isInputFocused.toggle()
                }
            }
            .padding()
            
            HStack {
                Text("Scroll Offset: \(Int(scrollOffset))")
                Spacer()
                VStack {
                    Button("Scroll Up") {
                        scrollOffset += 50
                    }
                    Button("Scroll Down") {
                        scrollOffset -= 50
                    }
                }
            }
            .padding()
            
            Spacer()
        }
    }
}