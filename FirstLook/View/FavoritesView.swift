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
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                if vm.favoritePhotos.isEmpty {
                    emptyStateView
                } else {
                    WaterfallGrid(vm.favoritePhotos, id: \.id) { photo in
                        NavigationLink(destination: DetailView(photo: photo).toolbar(.hidden, for: .tabBar)) {
                            KFImage(URL(string: photo.urls.small))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipped()
                                .cornerRadius(8)
                        }
                    }
                    .gridStyle(columns: 2, spacing: 8, animation: .easeInOut)
                    .padding(.horizontal, 8)
                }
            }
            .padding(.top,12)
            .navigationTitle("Favorite")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        vm.unfavoriteAllPhotos()
//                    }) {
//                        Text("清空收藏")
//                    }
//                }
//            }
            .onAppear {
                print("FavoritesView onAppear")
                vm.loadFavoritePhotos()
            }
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
