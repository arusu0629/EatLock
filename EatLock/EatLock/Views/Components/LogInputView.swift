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
    
    var body: some View {
        VStack {
            HStack {
                Picker("ログタイプ", selection: $selectedLogType) {
                    ForEach(LogType.allCases, id: \.self) { type in
                        Text("\(type.emoji) \(type.displayName)")
                            .tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            HStack {
                TextField("今日の行動を入力...", text: $newLogContent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        onSubmit()
                    }
                
                Button(action: onSubmit) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(newLogContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

#Preview {
    @State var logContent = ""
    @State var logType: LogType = .other
    
    return VStack {
        LogInputView(
            newLogContent: $logContent,
            selectedLogType: $logType,
            onSubmit: {
                print("Submit tapped with content: \(logContent)")
            }
        )
        
        Spacer()
    }
    .background(Color(.systemBackground))
}