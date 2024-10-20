//
//  Photo.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/19.
//

//
//  Photo.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/19.
//


import Foundation
import SwiftData

protocol Photo: Identifiable {
    var id: String { get }
    var urls: PhotoModel.Urls { get }
    var user: PhotoModel.User { get }
    var isFavorite: Bool? { get set }
}

enum PhotoModel {
    struct Urls: Codable {
        var raw: String
        var full: String
        var regular: String
        var small: String
        var thumb: String
    }
    
    struct User: Codable {
        var id: String
        var name: String
        var username: String
        var bio: String?
        var portfolioUrl: String?
        
        enum CodingKeys: String, CodingKey {
            case id, name, username, bio
            case portfolioUrl = "portfolio_url"
        }
    }
}
