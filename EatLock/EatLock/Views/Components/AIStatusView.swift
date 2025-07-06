import SwiftUI

struct AIStatusView: View {
    @ObservedObject private var aiManager = AIManager.shared
    @State private var showErrorDetails = false
    
    var body: some View {
        HStack(spacing: 8) {
            // ステータスアイコン
            Image(systemName: statusIcon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(statusColor)
                .frame(width: 16, height: 16)
                .background(
                    Circle()
                        .fill(statusColor.opacity(0.1))
                        .frame(width: 20, height: 20)
                )
            
            // ステータステキスト
            Text(aiManager.status.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // エラー詳細ボタン（エラー時のみ）
            if case .error = aiManager.status, let error = aiManager.lastError {
                Button(action: {
                    showErrorDetails.toggle()
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .popover(isPresented: $showErrorDetails) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AIエラー詳細")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("再試行") {
                            Task {
                                await aiManager.reinitialize()
                            }
                            showErrorDetails = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding()
                    .frame(maxWidth: 250)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var statusIcon: String {
        switch aiManager.status {
        case .notInitialized:
            return "circle.dotted"
        case .loading:
            return "clock"
        case .ready:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch aiManager.status {
        case .notInitialized:
            return .gray
        case .loading:
            return .blue
        case .ready:
            return .green
        case .error:
            return .red
        }
    }
}

// MARK: - Compact Version

struct AIStatusIndicator: View {
    @ObservedObject private var aiManager = AIManager.shared
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .opacity(aiManager.status == .loading ? 0.6 : 1.0)
            .scaleEffect(aiManager.status == .loading ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), 
                      value: aiManager.status == .loading)
    }
    
    private var statusColor: Color {
        switch aiManager.status {
        case .notInitialized:
            return .gray
        case .loading:
            return .blue
        case .ready:
            return .green
        case .error:
            return .red
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AIStatusView()
        
        HStack {
            Text("AI:")
            AIStatusIndicator()
        }
        
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}