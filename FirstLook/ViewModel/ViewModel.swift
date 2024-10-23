//
//  ViewModel.swift
//  FreshLook
//
//  Created by Kalman on 2024/10/17.
//

/*
 实现思路的关键点：
 本地优先：总是先尝试从本地加载照片，只有在本地没有照片时才从 API 获取。
 异步操作：使用 async/await 处理所有可能的长时间运行操作，如网络请求和数据库操作。
 状态管理：使用 @Published 属性包装器确保 UI 能够响应数据变化。
 错误处理：捕获并记录可能发生的错误，同时更新 errorMessage 以便在 UI 中显示。
 日志记录：在关键操作点添加日志，有助于调试和了解应用的运行状态。
 数据持久化：利用 SwiftData 的 ModelContext 进行数据的保存和检索。
 这种设计确保了应用能够高效地管理照片数据，减少不必要的网络请求，同时保持 UI 的响应性和数据的一致性。
 */

import Foundation
import SwiftData
import Photos
import UIKit
import Combine

@MainActor
class ViewModel: ObservableObject {
    let api = APIManager()
    let modelContext: ModelContext
    var imageCache: [String: URL] = [:] // 图片缓存
    let cachesDirectory: URL // 缓存目录
    let cacheFile: URL // 缓存文件
    var cancellables = Set<AnyCancellable>()
    let retryDelay: TimeInterval = 3.0
    let maxRetries = 3
    
    @Published var photos: [FirstLook] = []
    @Published var favoritePhotos: [any Photo] = []  // 收藏照片
    @Published var topics: [Topic] = []  // 主题内容
    @Published var topicPhotos: [String: [TopicPhoto]] = [:] // 主题下的照片
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSharing = false // 是否正在分享
    
    @Published var isLoadingMore = false  // 是否正在加载更多
    var currentPage: [String: Int] = [:] // 记录当前页数
    let maxFreePages = 2  // 最大免费页数
    let maxFavoritesForNonVIP = 8 // 非 VIP 用户的最大收藏数量
    @Published var isVIP: Bool = false // 是否是 VIP 用户
    
    @Published var downloadOriginal: Bool {
        didSet {
            UserDefaults.standard.set(downloadOriginal, forKey: "downloadOriginal")
        }
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheFile = cachesDirectory.appendingPathComponent("imageCache.plist")
        self.downloadOriginal = UserDefaults.standard.bool(forKey: "downloadOriginal")
        loadImageCache()
        
        // 延迟加载数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task {
                await self.loadInitialData()
            }
        }
    }
    
    // 用户购买 VIP 的方法
    func purchaseVIP() {
        // 这里应该包含实际的购买逻辑，可能涉及到 StoreKit 的使用
        // 为了演示，我们只是简单地将 isVIP 设置为 true
        isVIP = true
    }
    
    // 加载收藏的照片
    private func loadInitialData() async {
        await loadPhotosWithRetry()
        await loadTopicsWithRetry()
        loadFavoritePhotos()
    }
    
    // 检查用户是否可以加载更多页面
    func canLoadMorePages(for topic: Topic) -> Bool {
        if isVIP {
            return true
        } else {
            return (currentPage[topic.id] ?? 0) < maxFreePages
        }
    }
}
