import Foundation
import SwiftData

// 本扩展为 ViewModel 类添加了收藏照片的功能，包括检查收藏限制、收藏或取消收藏照片、取消所有收藏和加载所有收藏的照片。
extension ViewModel {
    func hasReachedFavoriteLimit() -> Bool {
        return !isVIP && favoritePhotos.count >= maxFavoritesForNonVIP
    }
    
    // 收藏或取消收藏照片
    func toggleFavorite(_ photo: any Photo) {
        print("toggleFavorite 被调用，照片 ID: \(photo.id)")
        
        let isCurrentlyFavorite: Bool
        if let firstLook = photo as? FirstLook {
            isCurrentlyFavorite = firstLook.isFavorite ?? false
        } else if let topicPhoto = photo as? TopicPhoto {
            isCurrentlyFavorite = topicPhoto.isFavorite ?? false
        } else {
            isCurrentlyFavorite = false
        }
        
        if hasReachedFavoriteLimit() && !isCurrentlyFavorite {
            errorMessage = "非 VIP 用户最多只能收藏 8 张图片。升级到 VIP 以解锁无限收藏！"
            return
        }
        
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
}