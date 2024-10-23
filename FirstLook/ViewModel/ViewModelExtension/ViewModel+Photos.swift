import Foundation
import SwiftData

// ViewModelExtension.swift 文件扩展了 ViewModel 类，添加了与照片相关的功能。
// 它提供了从本地和API获取照片的方法，并且实现了照片的缓存和清除功能。

extension ViewModel {
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
}