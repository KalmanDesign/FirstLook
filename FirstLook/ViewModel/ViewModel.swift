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
    private let api = APIManager()
    private let modelContext: ModelContext
    private var imageCache: [String: URL] = [:] // 图片缓存
    private let cachesDirectory: URL // 缓存目录
    private let cacheFile: URL // 缓存文件
    private var cancellables = Set<AnyCancellable>()
    private let retryDelay: TimeInterval = 3.0
    private let maxRetries = 3
    
    @Published var photos: [FirstLook] = []
    @Published var favoritePhotos: [any Photo] = []  // 收照片
    @Published var topics: [Topic] = []  // 主题内容
    @Published var topicPhotos: [String: [TopicPhoto]] = [:] // 主题下的照片
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSharing = false // 是否正在分享
    
    @Published var isLoadingMore = false  // 是否正在加载更多
    private var currentPage: [String: Int] = [:] // 记录当前页数
    private let maxFreePages = 3  // 最大免费页数
    @Published var isVIP: Bool = false // 是否是 VIP 用户

    
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
    
    // 保存数据到本地
    private func loadImageCache() {
        do {
            let data = try Data(contentsOf: cacheFile)
            let decoder = PropertyListDecoder()
            let cachedURLs = try decoder.decode([String: String].self, from: data)
            imageCache = cachedURLs.mapValues { URL(fileURLWithPath: $0) }
        } catch {
            print("Failed to load image cache: \(error)")
            imageCache = [:] // 如果加载失败，就使用空的缓存
        }
    }
    
    // 保存数据到本地
    private func saveImageCache() {
        do {
            let encoder = PropertyListEncoder()
            let cachedURLs = imageCache.mapValues { $0.path }
            let data = try encoder.encode(cachedURLs)
            try data.write(to: cacheFile)
        } catch {
            print("Failed to save image cache: \(error)")
        }
    }
    
    // 加载照片
    func loadPhotosWithRetry(retries: Int = 0) async {
        isLoading = true
        errorMessage = nil
        
        do {
            await fetchPhotosFromLocal()
            if photos.isEmpty {
                try await fetchRandomPhotoFromAPI(count: 30)
            }
        } catch {
            if retries < maxRetries {
                print("获取照片失败，\(retryDelay)秒后重试。重试次数: \(retries + 1)")
                try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                await loadPhotosWithRetry(retries: retries + 1)
            } else {
                print("获取照片失败，已达到最大重试次数")
                await MainActor.run {
                    self.errorMessage = "无法加载照片，请检查网络连接并重试"
                }
                loadCachedPhotos() // 尝试从缓存加载照片
            }
        }
        
        isLoading = false
    }
    
    // 从本地数据库获取所有照片
    func fetchPhotosFromLocal() async {
        let descriptor = FetchDescriptor<FirstLook>(sortBy: [SortDescriptor(\.id)])
        do {
            photos = try modelContext.fetch(descriptor) // 从本地数据库获取所有 FreshLook 对象
            print("本地获取到 \(photos.count) 张照片")
            for photo in photos {
                print("本地照片 ID: \(photo.id)")
            }
        } catch {
            errorMessage = "从本地获取照片失败: \(error.localizedDescription)"
            print(errorMessage ?? "")
        }
    }
    
    // 从 API 获取指定数量的随机照片
    func fetchRandomPhotoFromAPI(count: Int) async throws {
        print("ViewModel: 开始从API获取随机照片")
        let newPhotos = try await api.fetchRandomPhotos(count: count)
        print("ViewModel: API 返回的照片数量: \(newPhotos.count)")
        
        await MainActor.run {
            for photo in newPhotos {
                let newFreshLook = FirstLook(id: photo.id, urls: photo.urls, user: photo.user)
                modelContext.insert(newFreshLook)
                photos.append(newFreshLook)
                print("ViewModel: 插入新照片: \(photo.id)")
            }
        }
        
        try modelContext.save()
        print("ViewModel: 保存 \(newPhotos.count) 张新照片到本地")
        
        saveCachedPhotos() // 缓存照片数据
    }
    
    // 清除所有照片
    func clearAllPhotos() async {
        do {
            try modelContext.delete(model: FirstLook.self)
            try modelContext.delete(model: Topic.self)
            try modelContext.save()
            print("所有数据已清除")
            try await fetchRandomPhotoFromAPI(count: 20)
        } catch {
            print("清除照片时出错: \(error)")
        }
    }
    
    // 收藏或取消收藏照片
    func toggleFavorite(_ photo: any Photo) {
        print("toggleFavorite 被调用，照片 ID: \(photo.id)")
        switch photo {
        case let firstLook as FirstLook:
            toggleFirstLookFavorite(firstLook)
        case let topicPhoto as TopicPhoto:
            toggleTopicPhotoFavorite(topicPhoto)
        default:
            print("未知的照片类型")
        }
        loadFavoritePhotos() // 直接调用，不需要 DispatchQueue
    }
    
    private func toggleFirstLookFavorite(_ photo: FirstLook) {
        photo.isFavorite?.toggle()
        if photo.isFavorite == nil {
            photo.isFavorite = true
        }
        saveContext()
    }
    
    private func toggleTopicPhotoFavorite(_ photo: TopicPhoto) {
        print("toggleTopicPhotoFavorite 被调用，照片 ID: \(photo.id)")
        
        photo.isFavorite = !(photo.isFavorite ?? false)
        print("TopicPhoto 收藏状态更新：ID: \(photo.id), 新的 isFavorite: \(photo.isFavorite ?? false)")
        
        modelContext.insert(photo)
        saveContext()
        
        // 更新 topicPhotos 数组中的照片状态
        for (topicId, photos) in topicPhotos {
            if let index = photos.firstIndex(where: { $0.id == photo.id }) {
                topicPhotos[topicId]?[index] = photo
            }
        }
        
        loadFavoritePhotos()
    }
    
    // 取消所有收藏
    func unfavoriteAllPhotos() {
        for photo in photos {
            updateFavoriteStatus(for: photo, isFavorite: false)
        }
        // 获取所有已保存的 TopicPhoto
        let descriptor = FetchDescriptor<TopicPhoto>()
        do {
            let savedTopicPhotos = try modelContext.fetch(descriptor)
            for photo in savedTopicPhotos {
                updateFavoriteStatus(for: photo, isFavorite: false)
            }
        } catch {
            print("获取保存的 TopicPhoto 时出错: \(error)")
        }
        
        do {
            try modelContext.save()
        } catch {
            print("取消所有收藏时出错: \(error)")
        }
    }
    
    // 更新收藏状态的通用方法
    private func updateFavoriteStatus(for photo: any Photo, isFavorite: Bool) {
        if let firstLook = photo as? FirstLook {
            firstLook.isFavorite = isFavorite
        } else if let topicPhoto = photo as? TopicPhoto {
            topicPhoto.isFavorite = isFavorite
        }
        saveContext()
    }
    
    // 加载主题内容
    func loadTopicsIfNeeded() async {
        if topics.isEmpty {
            print("ViewModel: 主题列表为空，开始获取主题")
            await loadTopicsWithRetry()
            print("ViewModel: 主题获取完成")
        } else {
            print("ViewModel: 主题列表不为空，跳过获取")
        }
    }
    
    // 获取主题内容
    func fetchTopics() async throws {
        print("ViewModel: 开始获取主题")
        let newTopics = try await api.fetchTopics(perPage: 6)
        
        await MainActor.run {
            self.topics = []  // 清空现有主题
            for topic in newTopics {
                let newTopic = Topic(id: topic.id, slug: topic.slug, description: topic.topicDescription, isFavorite: topic.isFavorite)
                modelContext.insert(newTopic)
                self.topics.append(newTopic)
                print("ViewModel: 插入新主题: \(topic.id)")
            }
        }
        
        try modelContext.save()
        print("ViewModel: 保存 \(newTopics.count) 个新主题到本地")
        
        saveCachedTopics() // 缓存主题数据
    }
    
    // 获取主题下的图片
    func fetchTopicPhotos(topic: Topic, page: Int, perPage: Int = 10) async {
        print("ViewModel: 开始获取主题 \(topic.id) 下的图片，页码：\(page)")
        
        // 首先检查本地数据库
        var localPhotoDescriptor = FetchDescriptor<TopicPhoto>(
            predicate: #Predicate<TopicPhoto> { photo in
                photo.id.contains(topic.id)
            }
        )
        localPhotoDescriptor.sortBy = [SortDescriptor(\TopicPhoto.id)]
        localPhotoDescriptor.fetchLimit = page * perPage
        
        do {
            let localPhotos = try modelContext.fetch(localPhotoDescriptor)
            
            if localPhotos.count >= page * perPage {
                // 如果本地数据足够，直接使用本地数据
                print("ViewModel: 使用本地缓存的 \(localPhotos.count) 张主题照片")
                await MainActor.run {
                    if self.topicPhotos[topic.id] == nil {
                        self.topicPhotos[topic.id] = []
                    }
                    self.topicPhotos[topic.id]?.append(contentsOf: localPhotos)
                }
                return
            }
            
            // 如果本地数据不足，从 API 获取新数据
            let fetchedPhotos = try await api.fetchTopicPhotos(topicIdOrSlug: topic.id, page: page, perPage: perPage)
            
            var newTopicPhotos: [TopicPhoto] = []
            for photo in fetchedPhotos {
                let photoId = "\(topic.id)_\(photo.id)"  // 使用组合 ID
                let existingPhotoDescriptor = FetchDescriptor<TopicPhoto>(predicate: #Predicate { $0.id == photoId })
                let existingPhotos = try modelContext.fetch(existingPhotoDescriptor)
                
                let topicPhoto: TopicPhoto
                if let existingPhoto = existingPhotos.first {
                    // 更新现有照片
                    topicPhoto = existingPhoto
                    topicPhoto.user = PhotoModel.User(id: photo.user.id, name: photo.user.name, username: photo.user.username)
                    topicPhoto.urls = PhotoModel.Urls(raw: photo.urls.raw, full: photo.urls.full, regular: photo.urls.regular, small: photo.urls.small, thumb: photo.urls.thumb)
                } else {
                    // 创建新照片
                    topicPhoto = TopicPhoto(
                        id: photoId,
                        user: PhotoModel.User(id: photo.user.id, name: photo.user.name, username: photo.user.username),
                        urls: PhotoModel.Urls(raw: photo.urls.raw, full: photo.urls.full, regular: photo.urls.regular, small: photo.urls.small, thumb: photo.urls.thumb),
                        isFavorite: false
                    )
                    modelContext.insert(topicPhoto)
                }
                newTopicPhotos.append(topicPhoto)
            }
            
            await MainActor.run {
                if self.topicPhotos[topic.id] == nil {
                    self.topicPhotos[topic.id] = []
                }
                self.topicPhotos[topic.id]?.append(contentsOf: newTopicPhotos)
            }
            
            try modelContext.save()
            print("ViewModel: 保存 \(newTopicPhotos.count) 张主题照片到内存和 SwiftData")
        } catch {
            errorMessage = "从 API 获取或保存主题照片失败: \(error.localizedDescription)"
            print("ViewModel 错误: \(errorMessage ?? "")")
        }
    }
    
    // 添加一个新方法来保存上下文
    private func saveContext() {
        do {
            try modelContext.save()
            print("上下文已保存")
        } catch {
            print("保存上下文时出错: \(error)")
        }
    }
    
    // 添加一个新方法来加载所有收藏的图片
    func loadFavoritePhotos() {
        print("开始加载收藏照片")
        let firstLookDescriptor = FetchDescriptor<FirstLook>(predicate: #Predicate { $0.isFavorite == true })
        let topicPhotoDescriptor = FetchDescriptor<TopicPhoto>(predicate: #Predicate { $0.isFavorite == true })
        
        do {
            let favoriteFirstLooks = try modelContext.fetch(firstLookDescriptor)
            let favoriteTopicPhotos = try modelContext.fetch(topicPhotoDescriptor)
            let newFavorites = (favoriteFirstLooks as [any Photo]) + (favoriteTopicPhotos as [any Photo])
            
            // 使用 DispatchQueue.main.async 确保在主线程上更新 UI
            self.favoritePhotos = newFavorites
            print("收藏照片加载完成，总数：\(newFavorites.count)")
            for (index, photo) in newFavorites.enumerated() {
                print("收藏照片 \(index + 1): ID = \(photo.id), URL = \(photo.urls.small)")
            }
            self.objectWillChange.send()
            
            print("加载收藏图片：FirstLook \(favoriteFirstLooks.count) 张，TopicPhoto \(favoriteTopicPhotos.count) 张")
            print("TopicPhoto 收藏详情：")
            for photo in favoriteTopicPhotos {
                print("ID: \(photo.id), isFavorite: \(photo.isFavorite ?? false)")
            }
        } catch {
            print("加载收藏图片时出错: \(error)")
        }
    }
    
    // 下载原始图片
    @Published var downloadOriginal: Bool{ didSet{ UserDefaults.standard.set(downloadOriginal, forKey: "downloadOriginal") } }
    
    // 下载图片
    func downloadImage(from urlString: String, completion: @escaping (Bool) -> Void) {
        print("downloadOriginal: \(downloadOriginal)") // 添加这行日志
        let downloadFunction = downloadOriginal ? downloadAndSaveImage : downloadAndSaveDisplayImage
        
        downloadFunction(urlString) { result in
            switch result {
            case .success:
                completion(true)
            case .failure(let error):
                print("下载图片失败: \(error)") // 添加错误日志
                completion(false)
            }
        }
    }
    
    // 下载并保存原始图片
    func downloadAndSaveImage(from urlString: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "无效的 URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                completion(.failure(NSError(domain: "无法创建图像", code: 0, userInfo: nil)))
                return
            }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    completion(.success(()))
                } else if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError(domain: "未知错误", code: 0, userInfo: nil)))
                }
            }
        }.resume()
    }
    
    // 下载、裁剪并保存适应屏幕的图片
    func downloadAndSaveDisplayImage(from urlString: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "无效的 URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    completion(.failure(NSError(domain: "无法创建图像", code: 0, userInfo: nil)))
                    return
                }
                
                let screenSize = UIScreen.main.bounds.size
                let imageSize = image.size
                let scale = max(screenSize.width / imageSize.width, screenSize.height / imageSize.height)
                
                let scaledWidth = imageSize.width * scale
                let scaledHeight = imageSize.height * scale
                let xOffset = (scaledWidth - screenSize.width) / 2
                let yOffset = (scaledHeight - screenSize.height) / 2
                
                UIGraphicsBeginImageContextWithOptions(screenSize, false, 0)
                image.draw(in: CGRect(x: -xOffset, y: -yOffset, width: scaledWidth, height: scaledHeight))
                let croppedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                UIGraphicsEndImageContext()
                
                PHPhotoLibrary.requestAuthorization { status in
                    switch status {
                    case .authorized, .limited:
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAsset(from: croppedImage)
                        }) { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    completion(.success(()))
                                } else if let error = error {
                                    completion(.failure(error))
                                } else {
                                    completion(.failure(NSError(domain: "未知错误", code: 0, userInfo: nil)))
                                }
                            }
                        }
                    case .denied, .restricted, .notDetermined:
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "没有相册访问权限", code: 0, userInfo: nil)))
                        }
                    @unknown default:
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "未知的授权状态", code: 0, userInfo: nil)))
                        }
                    }
                }
            }
        }.resume()
    }
    
    // 下载图片并分享
    func downloadImageForSharing(from urlString: String) async throws -> URL {
        if let cachedURL = imageCache[urlString], FileManager.default.fileExists(atPath: cachedURL.path) {
            return cachedURL
        }
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "无效的 URL", code: 0, userInfo: nil)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw NSError(domain: "无法创建图像", code: 0, userInfo: nil)
        }
        
        let fileURL = cachesDirectory.appendingPathComponent("wallpaper_\(UUID().uuidString).jpg")
        
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try jpegData.write(to: fileURL)
            imageCache[urlString] = fileURL
            saveImageCache()
            return fileURL
        } else {
            throw NSError(domain: "无法创建JPEG数据", code: 0, userInfo: nil)
        }
    }
    
    // 下载并分享图片
    func shareImage(from urlString: String) async {
        isSharing = true
        do {
            let fileURL = try await downloadImageForSharing(from: urlString)
            
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                await MainActor.run {
                    rootViewController.present(activityVC, animated: true) {
                        self.isSharing = false
                    }
                }
            } else {
                isSharing = false
            }
        } catch {
            print("图片下载或分享失败：\(error.localizedDescription)")
            isSharing = false
        }
    }
    
    // 新增带重试机制的主题加载方法
    private func loadTopicsWithRetry(retries: Int = 0) async {
        do {
            try await fetchTopics()
        } catch {
            if retries < maxRetries {
                print("获取主题失败，\(retryDelay)秒后重试。重试次数: \(retries + 1)")
                try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                await loadTopicsWithRetry(retries: retries + 1)
            } else {
                print("获取主题失败，已达到最大重试次数")
                await MainActor.run {
                    self.errorMessage = "无法加载主题，请检查网络连接并重试"
                }
                loadCachedTopics() // 尝试从缓存加载主题
            }
        }
    }
    
    // 新增缓存相关方法
    private func saveCachedTopics() {
        do {
            let data = try JSONEncoder().encode(topics)
            try data.write(to: cachesDirectory.appendingPathComponent("cachedTopics.json"))
        } catch {
            print("缓存主题失败: \(error)")
        }
    }
    
    //   新增缓存相关方法
    private func loadCachedTopics() {
        do {
            let data = try Data(contentsOf: cachesDirectory.appendingPathComponent("cachedTopics.json"))
            let cachedTopics = try JSONDecoder().decode([Topic].self, from: data)
            self.topics = cachedTopics
            print("从缓存加载了 \(cachedTopics.count) 个主题")
        } catch {
            print("加载缓存主题失败: \(error)")
        }
    }
    
    // 新增照片缓存相关方法
    private func saveCachedPhotos() {
        do {
            let data = try JSONEncoder().encode(photos)
            try data.write(to: cachesDirectory.appendingPathComponent("cachedPhotos.json"))
        } catch {
            print("缓存照片失败: \(error)")
        }
    }
    
    //  新增照片缓存相关方法
    private func loadCachedPhotos() {
        do {
            let data = try Data(contentsOf: cachesDirectory.appendingPathComponent("cachedPhotos.json"))
            let cachedPhotos = try JSONDecoder().decode([FirstLook].self, from: data)
            self.photos = cachedPhotos
            print("从缓存加载了 \(cachedPhotos.count) 张照片")
        } catch {
            print("加载缓存照片失败: \(error)")
        }
    }


       // 检查用户是否可以加载更多页面
    func canLoadMorePages(for topic: Topic) -> Bool {
        if isVIP {
            return true
        } else {
            return (currentPage[topic.id] ?? 0) < maxFreePages
        }
    }

     // 修改现有的 loadMoreTopicPhotos 方法
    func loadMoreTopicPhotos(for topic: Topic) async {
        guard !isLoadingMore && canLoadMorePages(for: topic) else { return }
        
        isLoadingMore = true
        let page = (currentPage[topic.id] ?? 0) + 1
        
        do {
            let newPhotos = try await api.fetchTopicPhotos(topicIdOrSlug: topic.id, page: page)
            await MainActor.run {
                if topicPhotos[topic.id] == nil {
                    topicPhotos[topic.id] = []
                }
                topicPhotos[topic.id]?.append(contentsOf: newPhotos)
                currentPage[topic.id] = page
                isLoadingMore = false
            }
        } catch {
            await MainActor.run {
                print("Error loading more photos: \(error)")
                errorMessage = "加载更多照片时出错：\(error.localizedDescription)"
                isLoadingMore = false
            }
        }
    }


}

