//
//  ListView.swift
//  FreshLook
//
//  Created by Kalman on 2024/10/17.
//

import SwiftUI
import SwiftData
import Kingfisher
import WaterfallGrid

struct ListView: View {
    @EnvironmentObject private var vm: ViewModel
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                WaterfallGrid(vm.photos) { photo in
                    NavigationLink(destination: DetailView(photo: photo).toolbar(.hidden, for: .tabBar)) {
                        KFImage(URL(string: photo.urls.thumb))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            // .frame(height: 240)
                            .clipped()
                            .cornerRadius(8)
                        // .overlay(alignment: .topTrailing) {
                        //     Button {
                        //         vm.toggleFavorite(photo)
                        //     } label: {
                        //         Image(systemName: photo.isFavorite ?? false ? "heart.fill" : "heart")
                        //             .foregroundColor(photo.isFavorite ?? false ? .red : .white)
                        //             .padding(8)
                        //             .background(Color.black.opacity(0.5))
                        //             .clipShape(Circle())
                        //     }
                        //     .padding(8)
                        // }
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.top,12)
            .navigationTitle("Wallpaper")
        }
    }
}



#Preview {
    let container = PreviewContainer()
    return ListView()
        .environmentObject(container.createViewModel())
        .modelContainer(container.container)
    
}
