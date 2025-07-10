//
//  ThreadSafeLRUCache.swift
//  EatLock
//
//  Created by arusu0629 on 2025/07/10.
//

import Foundation

/// スレッドセーフなLRUキャッシュ実装
public final class ThreadSafeLRUCache<Key: Hashable, Value> {
    private let maxSize: Int
    private var cache: [Key: Value] = [:]
    private var accessOrder: [Key] = []
    private let queue = DispatchQueue(label: "com.eatlock.lru-cache", attributes: .concurrent)
    
    /// LRUキャッシュを初期化
    /// - Parameter maxSize: 最大サイズ
    public init(maxSize: Int) {
        self.maxSize = maxSize
    }
    
    /// 値を取得
    /// - Parameter key: キー
    /// - Returns: 値（存在しない場合はnil）
    public func getValue(for key: Key) -> Value? {
        return queue.sync {
            guard let value = cache[key] else { return nil }
            
            // アクセス順序を更新
            updateAccessOrder(for: key)
            return value
        }
    }
    
    /// 値を設定
    /// - Parameters:
    ///   - value: 値
    ///   - key: キー
    public func setValue(_ value: Value, for key: Key) {
        queue.async(flags: .barrier) {
            self.cache[key] = value
            self.updateAccessOrder(for: key)
            self.evictIfNeeded()
        }
    }
    
    /// キャッシュをクリア
    public func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
            self.accessOrder.removeAll()
        }
    }
    
    /// 現在のサイズを取得
    public var count: Int {
        return queue.sync {
            cache.count
        }
    }
    
    // MARK: - Private Methods
    
    private func updateAccessOrder(for key: Key) {
        // 既存のキーを削除（パフォーマンス最適化）
        if let index = accessOrder.lastIndex(of: key) {
            accessOrder.remove(at: index)
        }
        // 最新のアクセスとして末尾に追加
        accessOrder.append(key)
    }
    
    private func evictIfNeeded() {
        while cache.count > maxSize {
            guard let oldestKey = accessOrder.first else { break }
            cache.removeValue(forKey: oldestKey)
            accessOrder.removeFirst()
        }
    }
}