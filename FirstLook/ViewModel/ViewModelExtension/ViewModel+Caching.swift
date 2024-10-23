import Foundation

// 这个扩展为 ViewModel 类添加了缓存管理功能，包括加载和保存图片缓存、主题缓存和照片缓存。
// 它还提供了保存上下文的方法，用于确保数据的持久化。
extension ViewModel {
    // 保存数据到本地
    func loadImageCache() {
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
    func saveImageCache() {
        do {
            let encoder = PropertyListEncoder()
            let cachedURLs = imageCache.mapValues { $0.path }
            let data = try encoder.encode(cachedURLs)
            try data.write(to: cacheFile)
        } catch {
            print("Failed to save image cache: \(error)")
        }
    }
    
    // 新增缓存相关方法
    func saveCachedTopics() {
        do {
            let data = try JSONEncoder().encode(topics)
            try data.write(to: cachesDirectory.appendingPathComponent("cachedTopics.json"))
        } catch {
            print("缓存主题失败: \(error)")
        }
    }
    
    //   新增缓存相关方法
    func loadCachedTopics() {
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
    func saveCachedPhotos() {
        do {
            let data = try JSONEncoder().encode(photos)
            try data.write(to: cachesDirectory.appendingPathComponent("cachedPhotos.json"))
        } catch {
            print("缓存照片失败: \(error)")
        }
    }
    
    //  新增照片缓存相关方法
    func loadCachedPhotos() {
        do {
            let data = try Data(contentsOf: cachesDirectory.appendingPathComponent("cachedPhotos.json"))
            let cachedPhotos = try JSONDecoder().decode([FirstLook].self, from: data)
            self.photos = cachedPhotos
            print("从缓存加载了 \(cachedPhotos.count) 张照片")
        } catch {
                        print("加载缓存照片失败: \(error)")
        }
    }
    
    // 保存上下文
    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("保存上下文失败: \(error)")
        }
    }
}