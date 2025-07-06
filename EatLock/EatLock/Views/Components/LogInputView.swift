//
//  LogInputView.swift
//  EatLock
//
//  Created by AI Assistant on 2025/07/03.
//

import SwiftUI

struct LogInputView: View {
    @Binding var newLogContent: String
    @Binding var selectedLogType: LogType
    let onSubmit: () -> Void
    
    @State private var isPressed = false
    @State private var isSubmitting = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var keyboardShowObserver: NSObjectProtocol?
    @State private var keyboardHideObserver: NSObjectProtocol?
    @State private var showCharacterLimitWarning = false
    
    // 文字数上限
    private let maxCharacters = 500
    
    var body: some View {
        VStack(spacing: 0) {
            // 入力欄とボタン
            VStack(spacing: 12) {
                // ログタイプ選択
                HStack {
                    Picker("ログタイプ", selection: $selectedLogType) {
                        ForEach(LogType.allCases, id: \.self) { type in
                            Text("\(type.emoji) \(type.displayName)")
                                .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                // テキスト入力欄と送信ボタン
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("今日の行動を入力...", text: $newLogContent)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .submitLabel(.send)
                            .onSubmit {
                                handleSubmit()
                            }
                            .onChange(of: newLogContent) { newValue in
                                // 文字数上限チェック
                                if newValue.count > maxCharacters {
                                    // 文字数制限を適用（状態変数の自己修正を避けるため遅延実行）
                                    DispatchQueue.main.async {
                                        newLogContent = String(newValue.prefix(maxCharacters))
                                    }
                                    showCharacterLimitWarning = true
                                } else {
                                    // 警告を非表示にするのは、実際に文字数が制限内の場合のみ
                                    if showCharacterLimitWarning {
                                        showCharacterLimitWarning = false
                                    }
                                }
                            }
                        
                        // 文字数カウンター
                        HStack {
                            if showCharacterLimitWarning {
                                Text("文字数上限に達しました")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            Spacer()
                            
                            Text("\(newLogContent.count)/\(maxCharacters)")
                                .font(.caption)
                                .foregroundColor(
                                    newLogContent.count > maxCharacters - 50 ? .orange :
                                    newLogContent.count > maxCharacters - 100 ? .yellow : .secondary
                                )
                        }
                        .padding(.horizontal, 4)
                        .opacity(newLogContent.isEmpty ? 0 : 1)
                        .animation(.easeInOut(duration: 0.2), value: newLogContent.isEmpty)
                    }
                    
                    Button(action: {
                        handleSubmit()
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(isSubmitEnabled ? .white : .gray)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(isSubmitEnabled ? .blue : Color(.systemGray4))
                            )
                            .scaleEffect(isPressed ? 0.9 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                    }
                    .disabled(!isSubmitEnabled)
                    .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
                        // 送信中でない場合のみアニメーション状態を更新
                        if !isSubmitting {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isPressed = pressing
                            }
                        }
                    }, perform: {})
                }
            }
            .padding(16)
            .background(
                Color(.systemBackground)
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 4,
                        x: 0,
                        y: -2
                    )
            )
            .overlay(
                // 上部の境界線
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
                    .opacity(0.8),
                alignment: .top
            )
        }
        .background(Color(.systemBackground))
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .offset(y: -keyboardHeight)
        .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
    }
    
    private var isSubmitEnabled: Bool {
        let trimmedContent = newLogContent.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedContent.isEmpty && 
               trimmedContent.count <= maxCharacters &&
               !isSubmitting
    }
    
    private func handleSubmit() {
        guard isSubmitEnabled else { return }
        
        // 送信開始状態に設定（重複送信を防止）
        isSubmitting = true
        
        // 送信アニメーション
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            isPressed = true
        }
        
        // 即座に送信処理を実行
        onSubmit()
        
        // アニメーションを元に戻し、送信状態をリセット
        // 短い遅延でアニメーション効果を保持
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
        
        // 送信状態は少し長めに保持して重複送信を防止
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSubmitting = false
        }
    }
    
    private func setupKeyboardObservers() {
        keyboardShowObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                let keyboardHeight = keyboardFrame.height
                let bottomSafeArea = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }?
                    .safeAreaInsets.bottom ?? 0
                
                self.keyboardHeight = keyboardHeight - bottomSafeArea
            }
        }
        
        keyboardHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.keyboardHeight = 0
        }
    }
    
    private func removeKeyboardObservers() {
        if let observer = keyboardShowObserver {
            NotificationCenter.default.removeObserver(observer)
            keyboardShowObserver = nil
        }
        
        if let observer = keyboardHideObserver {
            NotificationCenter.default.removeObserver(observer)
            keyboardHideObserver = nil
        }
    }
}

#Preview {
    @State var logContent = ""
    @State var logType: LogType = .other
    
    return VStack {
        Spacer()
        Text("メインコンテンツ")
            .font(.headline)
        Spacer()
        
        LogInputView(
            newLogContent: $logContent,
            selectedLogType: $logType,
            onSubmit: {
                print("Submit tapped with content: \(logContent)")
            }
        )
    }
    .background(Color(.systemBackground))
}