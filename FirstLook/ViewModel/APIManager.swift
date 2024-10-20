//
//  APIManager.swift
//  FreshLook
//
//  Created by Kalman on 2024/10/17.
//

import Foundation

class APIManager{
    private let baseURL = "https://api.unsplash.com"
    private let accessKey = "fe-n7OGmhF3_4V2QD4o5oCprtUkv3OsgKHq_0K6VLE4"
    private let topicURL = "https://api.unsplash.com"
    

    //  获取随机图片
    func fetchRandomPhotos(count: Int) async throws -> [FirstLook] {
        var components = URLComponents(string: "\(baseURL)/photos/random")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: accessKey),
            URLQueryItem(name: "count", value: String(count))
        ]
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        print("请求 URL: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError
            }
            
            // 简化switch语句
            if !(200...299).contains(httpResponse.statusCode) {
                throw APIError.networkError
            }

            

            



            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
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
    
    
    // 主题
    func fetchTopics(perPage: Int) async throws -> [Topic] {
        var components = URLComponents(string: "\(baseURL)/topics")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: accessKey),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]
        let url = components.url!
        
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
    
    
    // 获取主题下的图片
    func fetchTopicPhotos(topicIdOrSlug: String, page: Int = 1, perPage: Int = 10) async throws -> [TopicPhoto] {
        let url = URL(string: "\(baseURL)/topics/\(topicIdOrSlug)/photos?client_id=\(accessKey)&page=\(page)&per_page=\(perPage)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // 打印响应状态码和原始数据
            if let httpResponse = response as? HTTPURLResponse {
                print("Response status code: \(httpResponse.statusCode)")
            }
            // print("Raw response data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            let photos = try decoder.decode([TopicPhoto].self, from: data)
            for photo in photos {
                print("主题照片 ID: \(photo.id), 主题照片用户名: \(photo.user.username), 主题图片简介:\(String(describing: photo.user.bio))")
            }

            return photos
        } catch {
            print("获取主题照片时出错: \(error)")
            throw APIError.networkError
        }
    }
    
    
    
}





enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkError
    case unauthorized
    case serverError
    
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
