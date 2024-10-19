//
//  FirstLookApp.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/18.
//

import SwiftUI
import SwiftData

@main
struct FirstLookApp: App {
    let container: ModelContainer
        init(){
            do{
                container = try ModelContainer(for: FirstLook.self, Topic.self, TopicPhoto.self)
            }catch{
                fatalError("无法初始化 ModelContainer: \(error)")
            }
        }
    var body: some Scene {
        WindowGroup {
            ContentView(vm: ViewModel(modelContext: container.mainContext), container: container)
        }
        .modelContainer(container)
    }
}
