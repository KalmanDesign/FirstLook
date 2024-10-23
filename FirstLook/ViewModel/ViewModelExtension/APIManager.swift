//
//  APIManager.swift
//  FreshLook
//
//  Created by Kalman on 2024/10/17.
//

import Foundation

// 创建一个名为APIManager的类，用于管理所有的API请求
class APIManager{
    // 定义私有变量baseURL，用于存储API的基本URL
    private let baseURL = "https://api.unsplash.com"
    // 定义私有变量accessKey，用于存储API的访问密钥
    private let accessKey = "fe-n7OGmhF3_4V2QD4o5oCprtUkv3OsgKHq_0K6VLE4"
    // 定义私有变量topicURL，用于存储主题的URL
    private let topicURL = "https://api.unsplash.com"
    

    // 定义一个名为fetchRandomPhotos的方法，用于获取随机图片
    func fetchRandomPhotos(count: Int) async throws -> [FirstLook] {
        // 创建一个URLComponents对象，用于构建URL
        var components = URLComponents(string: "\(baseURL)/photos/random")!
        // 添加查询参数
        components.queryItems = [
            URLQueryItem(name: "client_id", value: accessKey),
            URLQueryItem(name: "count", value: String(count))
        ]
        
        // 检查URL是否有效
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        print("请求 URL: \(url)")
        
        // 使用URLSession发送网络请求
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // 检查响应是否为HTTPURLResponse类型
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError
            }
            
            // 检查响应状态码是否在200到299之间
            if !(200...299).contains(httpResponse.statusCode) {
                throw APIError.networkError
            }

            // 创建一个JSONDecoder对象，用于解析JSON数据
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            // 解析JSON数据并转换为FirstLook对象的数组
            let photos = try decoder.decode([FirstLook].self, from: data)
            print("成功获取 \(photos.count) 张照片")
            for photo in photos {
                print("照片 ID: \(photo.id), 用户名: \(photo.user.username), 用户简介: \(String(describing: photo.user.bio))")
                 }
            return photos
        } catch let decodingError as DecodingError {
            print("解码错误: \(decodingError)")
            throw APIError.decodingError
        } catch {
            print("网络请求错误: \(error)")
            throw APIError.networkError
        }
    }
    
    
    // 定义一个名为fetchTopics的方法，用于获取主题
    func fetchTopics(perPage: Int) async throws -> [Topic] {
        // 创建一个URLComponents对象，用于构建URL
        var components = URLComponents(string: "\(baseURL)/topics")!
        // 添加查询参数
        components.queryItems = [
            URLQueryItem(name: "client_id", value: accessKey),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        let url = components.url!
        
        // 使用URLSession发送网络请求
        do {
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedTopics = try decoder.decode([Topic].self, from: data)
            
            return decodedTopics
        } catch let decodingError as DecodingError {
            print("解码错误: \(decodingError)")
            throw APIError.decodingError
        } catch {
            print("网络请求错误: \(error)")
            throw APIError.networkError
        }
    }
    
    
    // 定义一个名为fetchTopicPhotos的方法，用于获取主题下的图片
    func fetchTopicPhotos(topicIdOrSlug: String, page: Int = 1, perPage: Int = 10) async throws -> [TopicPhoto] {
        let url = URL(string: "\(baseURL)/topics/\(topicIdOrSlug)/photos?client_id=\(accessKey)&page=\(page)&per_page=\(perPage)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        
        // 使用URLSession发送网络请求
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 检查响应是否为HTTPURLResponse类型
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError
            }
            
            // 检查响应状态码是否在200到299之间
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError
            }
            
            // 创建一个JSONDecoder对象，用于解析JSON数据
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            // 解析JSON数据并转换为TopicPhoto对象的数组
            do {
                let photos = try decoder.decode([TopicPhoto].self, from: data)
                print("Successfully decoded \(photos.count) photos")
                return photos
            } catch {
                print("Decoding error: \(error)")
                throw APIError.decodingError
            }
        } catch {
            print("Network request error: \(error)")
            throw APIError.networkError
        }
    }
    
    
    
}





// 定义一个枚举类型APIError，用于表示API请求中可能出现的错误
enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkError
    case unauthorized
    case serverError
    
    // 为每个错误定义一个本地化描述
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "没有数据"
        case .decodingError:
            return "解码错误"
        case .networkError:
            return "网络错误"
        case .unauthorized:
            return "未授权"
        case .serverError:
            return "服务器错误"
        }
    }
}
