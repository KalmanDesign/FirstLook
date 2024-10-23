//
//  Configuration.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/22.
//


// 这个文件定义了一个 Configuration 结构体，用于获取应用的版本号和构建号。
// 它提供了两个静态属性：version 和 build，分别用于获取应用的版本号和构建号。
// 另外，它还提供了一个静态计算属性：versionAndBuild，用于返回版本号和构建号的组合字符串。

import Foundation


struct Configuration {
    static let version: String = {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            fatalError("CFBundleShortVersionString should not be missing from info.plist")
        }
        return version
    }()
    
    static let build: String = {
        guard let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            fatalError("CFBundleVersion should not be missing from info.plist")
        }
        return build
    }()
    
    static var versionAndBuild: String {
        return "\(version) (\(build))"
    }
}
