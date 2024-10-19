//
//  Model.swift
//  FreshLook
//
//  Created by Kalman on 2024/10/17.
//

import Foundation
import SwiftData

@Model
final class FirstLook: Identifiable, Codable {
    @Attribute(.unique) var id: String
    var urls: PhotoModel.Urls
    var user: PhotoModel.User
    var isFavorite: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case urls
        case user
        case isFavorite
    }
    
    init(id: String, urls:  PhotoModel.Urls, user: PhotoModel.User, isFavorite: Bool? = nil) {
        self.id = id
        self.urls = urls
        self.user = user
        self.isFavorite = isFavorite
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        urls = try container.decode(PhotoModel.Urls.self, forKey: .urls)
        user = try container.decode(PhotoModel.User.self, forKey: .user)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(urls, forKey: .urls)
        try container.encode(user, forKey: .user)
        try container.encodeIfPresent(isFavorite, forKey: .isFavorite)
    }
}

struct PhotoUrls: Codable {
    var raw: String
    var full: String
    var regular: String
    var small: String
    var thumb: String
}

struct PhotoUser: Codable {
    var id: String
    var name: String
    var portfolioUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case portfolioUrl = "portfolio_url"
    }
}
extension FirstLook: Photo {}





  // MARK: - Topic
@Model
final class Topic: Identifiable, Codable {
    @Attribute(.unique) var id: String
    var slug: String
    var topicDescription: String?
    var isFavorite: Bool? // 添加了isFavorite属性
    
    init(id: String, slug: String, description: String? = nil, isFavorite: Bool? = nil) {
        self.id = id
        self.slug = slug
        self.topicDescription = description
        self.isFavorite = isFavorite // 初始化isFavorite属性
    }
    
    enum CodingKeys: String, CodingKey {
        case id, slug, description, isFavorite // 只保留id、slug和TopicDescription、isFavorite
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        slug = try container.decode(String.self, forKey: .slug)
        topicDescription = try container.decodeIfPresent(String.self, forKey: .description)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) // 解码isFavorite属性
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(slug, forKey: .slug)
        try container.encodeIfPresent(topicDescription, forKey: .description)
        try container.encodeIfPresent(isFavorite, forKey: .isFavorite) // 编码isFavorite属性
    }
}


// MARK: - TopicPhoto
@Model
final class TopicPhoto: Identifiable, Codable {
    @Attribute(.unique) var id: String
    var user: PhotoModel.User
    var urls: PhotoModel.Urls
    @Attribute var isFavorite: Bool? // 添加 @Attribute 标记

    enum CodingKeys: String, CodingKey {
        case id
        case user
        case urls
        case isFavorite // 添加isFavorite到CodingKeys中
    }
    
    init(id: String, user: PhotoModel.User, urls: PhotoModel.Urls, isFavorite: Bool? = nil) {
        self.id = id
        self.user = user
        self.urls = urls
        self.isFavorite = isFavorite // 初始化isFavorite属性
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        user = try container.decode(PhotoModel.User.self, forKey: .user)
        urls = try container.decode(PhotoModel.Urls.self, forKey: .urls)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) // 解码isFavorite属性
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(user, forKey: .user)
        try container.encode(urls, forKey: .urls)
        try container.encodeIfPresent(isFavorite, forKey: .isFavorite) // 编码isFavorite属性
    }
}

struct TopicPhotoUrls: Codable {
    var raw: String
    var full: String
    var regular: String
    var small: String
    var thumb: String
}

struct TopicPhotoUser: Codable {
    var id: String
    var portfolioUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case portfolioUrl = "portfolio_url"
    }
}

extension TopicPhoto: Photo {}
