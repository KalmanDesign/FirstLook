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
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadPhotos()  // 在初始化时立即调用 loadPhotos()，确保 ViewModel 创建后就开始加载照片
            await loadTopicsIfNeeded() // 加载主题内容，只有在主题列表为空时才调用
            loadFavoritePhotos()
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
            print("从本地获取到 \(photos.count) 张照片")
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
            
            try modelContext.save()
            print("ViewModel: 保存 \(newPhotos.count) 张新照片到本地")
        } catch {
            errorMessage = "从 API 获取或保存照片失败: \(error.localizedDescription)"
            print("ViewModel 错误: \(errorMessage ?? "")")
        }
    }
    
    // 清除所有照片
    func clearAllPhotos() {
        do {
            try modelContext.delete(model: FirstLook.self)
            try modelContext.save()
            photos.removeAll()
            print("所有照片已清除")
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
                modelContext.insert(newTopic) // 插入到数据库中
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
    func fetchTopicPhotos(topic: Topic, page: Int, perPage:Int = 10) async {
        do {
            print("ViewModel: 开始获取主题 \(topic.id) 下的图片")
            let fetchedPhotos = try await api.fetchTopicPhotos(topicIdOrSlug: topic.id, page: page, perPage: perPage)
            
            var newTopicPhotos: [TopicPhoto] = []
            for photo in fetchedPhotos {
                // 尝试从数据库中获取已存在的 TopicPhoto
                let existingPhotoDescriptor = FetchDescriptor<TopicPhoto>(predicate: #Predicate { $0.id == photo.id })
                let existingPhotos = try modelContext.fetch(existingPhotoDescriptor)
                
                let topicPhoto: TopicPhoto
                if let existingPhoto = existingPhotos.first {
                    // 如果照片已存在，更新其属性
                    topicPhoto = existingPhoto
                    topicPhoto.user = PhotoModel.User(
                        id: photo.user.id,
                        name: photo.user.name,
                        username: photo.user.username
                    )
                    topicPhoto.urls = PhotoModel.Urls(
                        raw: photo.urls.raw,
                        full: photo.urls.full,
                        regular: photo.urls.regular,
                        small: photo.urls.small,
                        thumb: photo.urls.thumb
                    )
                    // 保留现有的 isFavorite 状态
                } else {
                    // 如果照片不存在，创建新的 TopicPhoto
                    topicPhoto = TopicPhoto(
                        id: photo.id,
                        user: PhotoModel.User(
                            id: photo.user.id,
                            name: photo.user.name,
                            username: photo.user.username
                        ),
                        urls: PhotoModel.Urls(
                            raw: photo.urls.raw,
                            full: photo.urls.full,
                            regular: photo.urls.regular,
                            small: photo.urls.small,
                            thumb: photo.urls.thumb
                        ),
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
            print("ViewModel: 保存 \(fetchedPhotos.count) 张主题照片到内存和 SwiftData")
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

}
