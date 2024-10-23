//
//  ContentView.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/18.
//

import SwiftUI
import SwiftData
import WaterfallGrid

struct ContentView: View {
    @ObservedObject var vm: ViewModel
    let container: ModelContainer
    @State private var selectedTab = 0
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ListView()
                .tabItem {
                    Label("Home", systemImage: "square.filled.on.square")
                }
                .tag(0)
            
            TopicsView()
                .tabItem {
                    Label("Topics", systemImage: "heart.text.square.fill")
                }
                .tag(1)
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart")
                }
                .tag(2)
            SettingView()
                .tabItem {
                    Label("Setting", systemImage: "heart")
                }
                .tag(3)
        }
        .environmentObject(vm)
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 2 { // FavoritesView
                print("切换到 FavoritesView，重新加载数据")
                vm.loadFavoritePhotos()
            }
        }
        .preferredColorScheme(.dark)  // 设置深色模式
        .background(Color.black)  // 设置背景颜色为黑色
        
    }
}

#Preview {
    let container = PreviewContainer()
    return ContentView(vm: container.createViewModel(), container: container.container)
        .modelContainer(container.container)
}
