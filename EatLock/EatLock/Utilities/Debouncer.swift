//
//  Debouncer.swift
//  EatLock
//
//  Created by arusu0629 on 2025/07/10.
//

import Foundation

/// デバウンス機能を提供するユーティリティクラス
/// 連続する呼び出しを遅延し、最後の呼び出しのみを実行する
public class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    
    /// デバウンサーを初期化
    /// - Parameters:
    ///   - delay: 遅延時間（秒）
    ///   - queue: 実行するキュー（デフォルト: メインキュー）
    public init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    /// デバウンス処理を実行
    /// - Parameter action: 実行するアクション
    public func debounce(action: @escaping () -> Void) {
        // 既存のタスクをキャンセル
        workItem?.cancel()
        
        // 新しいタスクを作成
        workItem = DispatchWorkItem(block: action)
        
        // 指定した遅延後にタスクを実行
        if let workItem = workItem {
            queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
    
    /// 保留中のタスクをキャンセル
    public func cancel() {
        workItem?.cancel()
        workItem = nil
    }
    
    deinit {
        cancel()
    }
}