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
                       Label("Home", systemImage: "house")
                   }
                   .tag(0)
               
               TopicsView()
                   .tabItem {
                       Label("Topics", systemImage: "list.bullet")
                   }
                   .tag(1)
               
               FavoritesView()
                   .tabItem {
                       Label("Favorites", systemImage: "heart")
                   }
                   .tag(2)
           }
           .environmentObject(vm)
           .onChange(of: selectedTab) { oldValue, newValue in
               if newValue == 2 { // FavoritesView
                   print("切换到 FavoritesView，重新加载数据")
                   vm.loadFavoritePhotos()
               }
           }
       }
}

#Preview {
    let container = PreviewContainer()
    return ContentView(vm: container.createViewModel(), container: container.container)
        .modelContainer(container.container)
}
