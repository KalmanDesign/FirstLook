//
//  FavoritesView.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/18.
//

import SwiftUI
import Kingfisher
import SwiftData
import WaterfallGrid

struct FavoritesView: View {
    @EnvironmentObject private var vm: ViewModel
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                if vm.favoritePhotos.isEmpty {
                    emptyStateView
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(vm.favoritePhotos, id: \.id) { photo in
                            NavigationLink(destination: ImageDetailView(photo: photo).toolbar(.hidden, for: .tabBar).navigationBarBackButtonHidden(true)) {
                                GeometryReader { geometry in
                                    KFImage(URL(string: photo.urls.small))
                                        .resizable()
                                        .aspectRatio(contentMode: .fill) // 以中心裁剪
                                        .frame(width: geometry.size.width, height: geometry.size.width * (4/3)) // 16:9 比例
                                        .clipped() // 裁剪超出部分
                                        .cornerRadius(10)
                                }
                                .aspectRatio(3/4, contentMode: .fit) // 设置为 16:9 比例
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
            .id(refreshID)
            .navigationTitle("Collect")
            .onAppear {
                print("FavoritesView onAppear")
                print("Current favoritePhotos count: \(vm.favoritePhotos.count)")
                vm.loadFavoritePhotos()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.refreshID = UUID()
                }
            }
            // .onChange(of: vm.favoritePhotos.map { $0.id }) { newValue in
            //     print("favoritePhotos changed in FavoritesView, new count: \(newValue.count)")
            //     self.refreshID = UUID()
            // }
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Image(systemName: "heart.slash")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
            Text("暂无收藏的照片")
                .foregroundColor(.secondary)
                .padding(.top, 10)
            Spacer()
        }
        .frame(minHeight: UIScreen.main.bounds.height - 200)
    }
}

#Preview {
    let container = PreviewContainer()
    return FavoritesView()
        .environmentObject(container.createViewModel())
        .modelContainer(container.container)
}
