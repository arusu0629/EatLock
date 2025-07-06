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
    @State private var keyboardHeight: CGFloat = 0
    
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
                    TextField("今日の行動を入力...", text: $newLogContent)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .submitLabel(.send)
                        .onSubmit {
                            handleSubmit()
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
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed = pressing
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
        !newLogContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Handles the log submission action with a button press animation and a short delay before invoking the submit closure.
    /// Triggers the `onSubmit` callback if submission is enabled, and animates the button to provide visual feedback.
    private func handleSubmit() {
        guard isSubmitEnabled else { return }
        
        // 送信アニメーション
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            isPressed = true
        }
        
        // 少し遅延させてから実際の送信処理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onSubmit()
            
            // アニメーションを元に戻す
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
    }
    
    /// Sets up observers to adjust the view's keyboard height state when the keyboard appears or disappears.
    /// Updates the `keyboardHeight` property to ensure the input view remains visible above the keyboard.
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
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
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.keyboardHeight = 0
        }
    }
    
    /// Removes observers for keyboard show and hide notifications from the notification center.
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
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