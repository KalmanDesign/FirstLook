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


@MainActor
class ViewModel: ObservableObject {
    private let api = APIManager()
    private let modelContext: ModelContext
    
    @Published var photos: [FirstLook] = []
    @Published var favoritePhotos: [any Photo] = []  // 收照片
    @Published var topics: [Topic] = []  // 主题内容
    @Published var topicPhotos: [String: [TopicPhoto]] = [:] // 主题下的照片
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var imageCache: [String: URL] = [:] // 图片缓存
    private let cachesDirectory: URL // 缓存目录
    private let cacheFile: URL // 缓存文件

    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheFile = cachesDirectory.appendingPathComponent("imageCache.plist")
        
        loadImageCache()
        
        Task {
            await loadPhotos()  // 在初始化时立即调用 loadPhotos()，确保 ViewModel 创建后就开始加载照片
            await loadTopicsIfNeeded() // 加载主题内容，只有在主题列表为空时才调用
            loadFavoritePhotos()
        }
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
            // 如果加载失败，就使用空的缓存
            imageCache = [:]
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
    func loadPhotos() async {
        isLoading = true
        errorMessage = nil
        await fetchPhotosFromLocal() // 从本地获取照片
        if photos.isEmpty {
            await fetchRandomPhotoFromAPI(count: 30) // 从 API 获取 30 张随机照片
        }
        isLoading = false
        
        
    }
    
    // 从本地数据库获取所有照片
    func fetchPhotosFromLocal() async {
        let descriptor = FetchDescriptor<FirstLook>(sortBy: [SortDescriptor(\.id)])
        do {
            photos = try modelContext.fetch(descriptor) // 从本地数据库获取所有 FreshLook 对象,同时将新照片添加到 photos 数组中，确保 UI 立即更新
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
    func fetchRandomPhotoFromAPI(count: Int) async {
        do {
            let newPhotos = try await api.fetchRandomPhotos(count: count) // 调用 API 获取指定数量的随机照片。
            print("ViewModel: API 返回的照片数量: \(newPhotos.count)")
            
            for photo in newPhotos {
                let newFreshLook = FirstLook(id: photo.id, urls: photo.urls, user: photo.user)  // 对于每张新照片，创建一个新的 FreshLook 对象并插入到 modelContext 中
                modelContext.insert(newFreshLook) // 插入到数据库中
                photos.append(newFreshLook)       // 同时将新照片添加到 photos 数组中，确保 UI 立即更新。
                print("ViewModel: 插入新照片: \(photo.id)")
            }
            for photo in newPhotos {
                let newFreshLook = FirstLook(id: photo.id, urls: photo.urls, user: photo.user)
                modelContext.insert(newFreshLook)
                photos.append(newFreshLook)
                print("ViewModel: 插入新照片: \(photo.id), portfolioUrl: \(photo.user.portfolioUrl ?? "No portfolio")")
            }
            
            
            try modelContext.save()
            print("ViewModel: 保存 \(newPhotos.count) 张新照片到本地")
        } catch {
            errorMessage = "从 API 获取或保存照片失败: \(error.localizedDescription)"
            print("ViewModel 错误: \(errorMessage ?? "")")
        }
    }
    
    // 清除所有照片
    func clearAllPhotos() async {
        do {
            try modelContext.delete(model: FirstLook.self)
            try modelContext.delete(model: Topic.self)
            try modelContext.save()
            print("所有数据已清除")
            await fetchRandomPhotoFromAPI(count: 20)
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
            photo.isFavorite = false
        }
        // ADDED: 获取所有已保存的 TopicPhoto
        let descriptor = FetchDescriptor<TopicPhoto>()
        do {
            let savedTopicPhotos = try modelContext.fetch(descriptor)
            for photo in savedTopicPhotos {
                photo.isFavorite = false
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
    
    // 加载主题内容
    func loadTopicsIfNeeded() async{
        if topics.isEmpty {
            print("ViewModel: 主题列表为空，开始获取主题")
            await fetchTopics()
            print("ViewModel: 主题获取完成")
        } else {
            print("ViewModel: 主题列表不为空，跳过获取")
        }
    }
    
    // 获取主题内容
    func fetchTopics() async {
        do {
            print("ViewModel: 开始获取主题")
            let newTopics = try await api.fetchTopics(perPage: 6)
            // print("ViewModel: API 返回的原始数据: \(newTopics)")
            
            for topic in newTopics {
                let newTopic = Topic(id: topic.id, slug: topic.slug, description: topic.topicDescription, isFavorite: topic.isFavorite)  // 对于每一个新主题，创建一个新的 Topic 对象并插入到 modelContext 中
                modelContext.insert(newTopic) // 插入到数据库
                topics.append(newTopic)       // 同时将新主添加到 topics 数组中，确保 UI 立即更新。
                print("ViewModel: 插入新主题: \(topic.id)")
            }
            
            try modelContext.save()
            print("ViewModel: 保存 \(newTopics.count) 个新主题到本地")
        } catch {
            errorMessage = "从 API 获取或保存主题失败: \(error.localizedDescription)"
            print("ViewModel 错误: \(errorMessage ?? "")")
        }
    }
    
    // 获取主题下的图片
    func fetchTopicPhotos(topic: Topic, page: Int, perPage: Int = 10) async {
        print("ViewModel: 开始获取主题 \(topic.id) 下的图片")
        
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
                    self.topicPhotos[topic.id] = localPhotos
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
                self.topicPhotos[topic.id] = newTopicPhotos
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
            favoritePhotos = (favoriteFirstLooks as [any Photo]) + (favoriteTopicPhotos as [any Photo])
            print("加载收藏图片：FirstLook \(favoriteFirstLooks.count) 张，TopicPhoto \(favoriteTopicPhotos.count) 张")
            print("TopicPhoto 收藏详情：")
            for photo in favoriteTopicPhotos {
                print("ID: \(photo.id), isFavorite: \(photo.isFavorite ?? false)")
            }
            
            
            objectWillChange.send()
        } catch {
            print("加载收藏图片时出错: \(error)")
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
     func downloadAndSaveDisplayImage(from urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
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
                                    completion(success)
                                }
                            }
                        case .denied, .restricted, .notDetermined:
                            DispatchQueue.main.async {
                                completion(false)
                            }
                        @unknown default:
                            DispatchQueue.main.async {
                                completion(false)
                            }
                        }
                    }
                } else {
                    completion(false)
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
    func shareImage(from urlString: String) {
        Task {
            do {
                let fileURL = try await downloadImageForSharing(from: urlString)
                
                await MainActor.run {
                    let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootViewController = window.rootViewController {
                        rootViewController.present(activityVC, animated: true, completion: nil)
                    }
                }
            } catch {
                print("图片下载或分享失败：\(error.localizedDescription)")
            }
        }
    }
    
}

