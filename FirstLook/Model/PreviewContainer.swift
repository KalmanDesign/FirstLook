//
//  PreviewContainer.swift
//  FreshLook
//
//  Created by Kalman on 2024/10/17.
//

import SwiftUI
import SwiftData

@MainActor
struct PreviewContainer {
    let container: ModelContainer
    
    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            container = try ModelContainer(for: FirstLook.self, configurations: config)
            
            // 这里可以添加一些示例数据
            let sampleFreshLook = FirstLook(id: "Dwu85P9SOIk",
                                            urls: PhotoModel.Urls(raw: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d",
                                                     full: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d?q=75&fm=jpg",
                                                     regular: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d?q=75&fm=jpg&w=1080&fit=max",
                                                     small: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d?q=75&fm=jpg&w=400&fit=max",
                                                     thumb: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d?q=75&fm=jpg&w=200&fit=max"),
                                            user: PhotoModel.User(id: "QPxL2MGqfrw", name: "Joe Example", username: "joe_example"),
                                            isFavorite: false)
            container.mainContext.insert(sampleFreshLook)
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }
    
    func createViewModel() -> ViewModel {
        return ViewModel(modelContext: container.mainContext)
    }
}
