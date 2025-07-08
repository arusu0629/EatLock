//
//  ConsentFormView.swift
//  EatLock
//
//  Created by arusu0629 on 2025/07/07.
//

import SwiftUI

/// プライバシー同意フォームビュー
/// UMP同意フォームと連携して動作する補完的なUIコンポーネント
struct ConsentFormView: View {
    @ObservedObject private var adManager = AdManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var isProcessing = false
    @State private var showingUMPForm = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 16) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("プライバシーとデータの使用について")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                // 説明文
                VStack(alignment: .leading, spacing: 16) {
                    Text("このアプリでは、以下の目的でお客様のデータを使用する場合があります：")
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ConsentItemView(
                            icon: "target",
                            title: "パーソナライズされた広告",
                            description: "関心に基づいた広告を表示するため"
                        )
                        
                        ConsentItemView(
                            icon: "chart.bar",
                            title: "分析と改善",
                            description: "アプリの使用状況を分析し、サービスを改善するため"
                        )
                        
                        ConsentItemView(
                            icon: "gear",
                            title: "機能の提供",
                            description: "アプリの基本機能を提供するため"
                        )
                    }
                    
                    Text("詳細については、プライバシーポリシーをご確認ください。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // ボタン
                VStack(spacing: 12) {
                    Button(action: {
                        showConsentForm()
                    }) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text("同意設定を確認")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                    
                    Button(action: {
                        handleSkip()
                    }) {
                        Text("後で設定")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    .disabled(isProcessing)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("プライバシー設定")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // 同意が必要な場合は自動的にUMPフォームを表示
            if adManager.consentStatus == .required {
                showConsentForm()
            }
        }
        .onChange(of: adManager.consentStatus) { _, newStatus in
            // 同意状態が変更されたら処理を停止
            if newStatus != .required {
                isProcessing = false
            }
        }
    }
    
    /// UMP同意フォームを表示
    private func showConsentForm() {
        isProcessing = true
        
        // UMP同意フォームを表示
        adManager.presentConsentForm()
        
        // 少し待ってから処理完了
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if adManager.consentStatus == .obtained {
                dismiss()
            } else {
                isProcessing = false
            }
        }
    }
    
    /// スキップ処理
    private func handleSkip() {
        isProcessing = true
        
        // 一時的にスキップ（後で設定可能）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isProcessing = false
            dismiss()
        }
    }
}

/// 同意項目表示ビュー
struct ConsentItemView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ConsentFormView()
} 