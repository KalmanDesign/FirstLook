import Foundation
import SwiftData

// 这是一个 ViewModel 的扩展，用于处理主题相关的逻辑
extension ViewModel {
    // 加载主题内容
    // 这个方法检查主题列表是否为空，如果为空，则调用loadTopicsWithRetry方法获取主题，否则跳过获取。
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
    // 这个方法从API获取主题，插入到本地数据库，并更新内存中的主题列表。
    // 它首先从API获取主题列表，然后在主线程中清空现有主题列表，插入新获取的主题到数据库和内存中。
    // 最后，它保存数据库的更改，并缓存获取到的主题数据。
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
    // 这个方法首先从本地数据库中获取指定主题的图片，如果本地数据不足，则从API获取新数据。
    // 如果从API获取数据，则更新或插入本地数据库，并将获取到的图片添加到内存中的主题照片字典中。
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
    
    // 新增带重试机制的主题加载方法
    // 这个方法尝试从API获取主题，如果失败则进行重试，最多重试maxRetries次
    // 如果重试次数超过maxRetries，将打印错误信息并尝试从缓存加载主题
    func loadTopicsWithRetry(retries: Int = 0) async {
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
    
    // 该方法用于异步加载更多主题照片。它首先检查是否正在加载更多照片，并且是否可以加载更多页面。
    // 如果可以加载更多照片，则增加当前页面数，尝试从API获取照片，并将获取到的照片添加到主题照片数组中。
    // 如果获取照片失败，则打印错误信息并更新错误信息。
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