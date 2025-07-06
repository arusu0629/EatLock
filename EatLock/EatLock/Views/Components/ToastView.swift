//
//  ToastView.swift
//  EatLock
//
//  Created by AI Assistant on 2025/07/04.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isPresented: Bool
    
    @State private var dismissalTask: DispatchWorkItem?
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(type.iconColor)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(type.backgroundColor)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 100) // 入力欄の上に表示
        }
        .background(Color.clear)
        .opacity(isPresented ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isPresented)
        .onAppear {
            // 既存のタスクがある場合はキャンセル
            dismissalTask?.cancel()
            
            // 3秒後に自動的に非表示にするタスクを作成
            let task = DispatchWorkItem {
                withAnimation {
                    isPresented = false
                }
            }
            
            // タスクを保存してスケジュール
            dismissalTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: task)
        }
        .onDisappear {
            // ビューが非表示になる際にタスクをキャンセル
            dismissalTask?.cancel()
            dismissalTask = nil
        }
    }
}

enum ToastType {
    case success
    case error
    case warning
    case info
    
    var backgroundColor: Color {
        switch self {
        case .success:
            return Color.green
        case .error:
            return Color.red
        case .warning:
            return Color.orange
        case .info:
            return Color.blue
        }
    }
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var iconColor: Color {
        return .white
    }
}

#Preview {
    @State var isPresented = true
    
    return ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        ToastView(
            message: "行動ログを保存しました",
            type: .success,
            isPresented: $isPresented
        )
    }
}