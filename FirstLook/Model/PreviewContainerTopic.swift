//
//  PreviewContainer.swift
//  FreshLook
//
//  Created by Kalman on 2024/10/17.
//

import SwiftUI
import SwiftData

@MainActor
struct PreviewContainerTopic {
    let container: ModelContainer
    
    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            container = try ModelContainer(for: FirstLook.self, configurations: config)
            
            // 这里可以添加一些示例数据
            let sampleTopic = Topic(id: "Dwu85P9SOIk",
                                    slug: "example-topic",
                                    description: "这是一个示例主题",
                                    isFavorite: false)
            container.mainContext.insert(sampleTopic)
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    func createViewModel() -> ViewModel {
        return ViewModel(modelContext: container.mainContext)
    }
}
