import Foundation
import UIKit
import Photos

// 本扩展为 ViewModel 类添加了图片处理功能，包括下载、裁剪、保存和分享图片。
extension ViewModel {
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
}