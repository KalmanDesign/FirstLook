import Foundation
import Kingfisher


extension ViewModel{
    
     /// 读取应用的缓存信息并以数字展示
    /// - Returns: 缓存大小的字符串表示，单位为 MB
    func readCacheSize() -> String {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileEnumerator = FileManager.default.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey], options: [])
        
        var totalSize: Int64 = 0
        while let fileURL = fileEnumerator?.nextObject() as? URL {
            do {
                // 使用 .fileSizeKey 获取文件大小
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            } catch {
                print("获取文件大小时出错: \(error)")
            }
        }
        
        // 将字节转换为 MB
        let sizeInMB = Double(totalSize) / (1024 * 1024)
        return String(format: "%.2f MB", sizeInMB)
    }

     /// 清除应用的缓存
    func clearCache() {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        do {
            let fileEnumerator = FileManager.default.enumerator(at: cacheDirectory, includingPropertiesForKeys: nil, options: [])
            while let fileURL = fileEnumerator?.nextObject() as? URL {
                try FileManager.default.removeItem(at: fileURL)
            }
            print("缓存已清除")
        } catch {
            print("清除缓存时出错: \(error)")
        }
    }

}
