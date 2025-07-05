//
//  NavigationDestination.swift
//  EatLock
//
//  Created by NavigationSystem on 2025/06/25.
//

import SwiftUI

/// ナビゲーション先を定義するenum
/// 型安全なナビゲーション管理を提供
enum NavigationDestination: Hashable {
    case home
    case logDetail(ActionLog)
    case settings
    case statistics
    case tutorial
}

/// NavigationDestinationのビュー生成拡張
extension NavigationDestination {
    @ViewBuilder
    func destination(repository: ActionLogRepository) -> some View {
        switch self {
        case .home:
            ContentView()
        case .logDetail(let log):
            LogDetailView(log: log, repository: repository)
        case .settings:
            SettingsView()
        case .statistics:
            StatisticsView()
        case .tutorial:
            TutorialView()
        }
    }
}

/// 将来的な拡張のための詳細ビュー
struct LogDetailView: View {
    let log: ActionLog
    let repository: ActionLogRepository
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("記録日時")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(log.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                    
                    Text("記録内容")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(log.content)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if let feedback = log.feedback {
                        Text("AI フィードバック")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(feedback)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGreen).opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("記録詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 設定画面（将来的な拡張用）
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("設定")
                    .font(.title)
                    .padding()
                
                Text("将来的な機能拡張の準備として作成されました")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 統計画面（将来的な拡張用）
struct StatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("統計")
                    .font(.title)
                    .padding()
                
                Text("将来的な機能拡張の準備として作成されました")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// チュートリアル画面（将来的な拡張用）
struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("チュートリアル")
                    .font(.title)
                    .padding()
                
                Text("将来的な機能拡張の準備として作成されました")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("チュートリアル")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}