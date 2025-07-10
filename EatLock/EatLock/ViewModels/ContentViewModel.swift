//
//  ContentViewModel.swift
//  EatLock
//
//  Created by arusu0629 on 2025/07/10.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    @Published var repository: ActionLogRepository?
    @Published var newLogContent = ""
    @Published var selectedLogType: LogType = .other
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var isRepositoryInitialized = false
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .info
    @Published var showFeedback = false
    @Published var currentFeedback: AIFeedback?
    @Published var scrollOffset: CGFloat = 0
    @Published var isInputFocused = false
    
    private var keyboardShowObserver: NSObjectProtocol?
    private var keyboardHideObserver: NSObjectProtocol?
    private let scrollOffsetDebouncer = Debouncer(delay: 0.016) // ~60fps
    
    func setupRepository(modelContext: ModelContext) {
        do {
            repository = ActionLogRepository(modelContext: modelContext)
            isRepositoryInitialized = true
        } catch {
            showToast(message: "データベースの初期化に失敗しました: \(error.localizedDescription)", type: .error)
            isRepositoryInitialized = false
        }
    }
    
    func updateScrollOffset(_ value: CGFloat) {
        scrollOffsetDebouncer.debounce {
            Task { @MainActor in
                self.scrollOffset = -value
            }
        }
    }
    
    func addActionLog() async {
        let content = newLogContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        guard content.count <= 500 else {
            showToast(message: "文字数が上限（500文字）を超えています", type: .error)
            return
        }
        
        guard isRepositoryInitialized, let repository = repository else {
            showToast(message: "データベースの初期化に失敗しました。アプリを再起動してください。", type: .error)
            return
        }
        
        do {
            let createdLog = try await repository.createActionLogWithAIFeedback(content: content, logType: selectedLogType)
            
            newLogContent = ""
            selectedLogType = .other
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            if let aiFeedback = repository.getSecureAIFeedback(for: createdLog) {
                let feedback = AIFeedback(
                    message: aiFeedback,
                    preventedCalories: createdLog.preventedCalories ?? 0,
                    type: determineFeedbackType(for: createdLog.logType),
                    generatedAt: createdLog.updatedAt
                )
                
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                self.currentFeedback = feedback
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showFeedback = true
                }
            } else {
                showToast(message: "行動ログを保存しました", type: .success)
            }
            
        } catch {
            showToast(message: error.localizedDescription, type: .error)
        }
    }
    
    func deleteActionLogs(_ logsToDelete: [ActionLog]) {
        guard isRepositoryInitialized, let repository = repository else {
            showToast(message: "データベースの初期化に失敗しました。アプリを再起動してください。", type: .error)
            return
        }
        
        guard !logsToDelete.isEmpty else {
            showToast(message: "削除対象のログが見つかりません", type: .error)
            return
        }
        
        do {
            try repository.deleteActionLogs(logsToDelete)
            showToast(message: "行動ログを削除しました", type: .success)
        } catch {
            showToast(message: error.localizedDescription, type: .error)
        }
    }
    
    func focusTextInput() {
        withAnimation(.easeInOut(duration: 0.5)) {
            scrollOffset = 0
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func setupKeyboardObservers() {
        keyboardShowObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                self.isInputFocused = true
            }
        }
        
        keyboardHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                self.isInputFocused = false
            }
        }
    }
    
    func removeKeyboardObservers() {
        if let observer = keyboardShowObserver {
            NotificationCenter.default.removeObserver(observer)
            keyboardShowObserver = nil
        }
        
        if let observer = keyboardHideObserver {
            NotificationCenter.default.removeObserver(observer)
            keyboardHideObserver = nil
        }
    }
    
    private func showToast(message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        withAnimation {
            showToast = true
        }
    }
    
    private func determineFeedbackType(for logType: LogType) -> AIFeedback.FeedbackType {
        switch logType {
        case .success:
            return .achievement
        case .failure:
            return .support
        case .struggle:
            return .encouragement
        case .other:
            return .support
        }
    }
    
    deinit {
        removeKeyboardObservers()
    }
}