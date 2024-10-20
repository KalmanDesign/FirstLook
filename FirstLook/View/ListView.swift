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
    @State private var isGridView = false
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                WaterfallGrid(vm.photos) { photo in
                    NavigationLink(destination: DetailView(photo: photo).toolbar(.hidden, for: .tabBar)) {
                        KFImage(URL(string: photo.urls.thumb))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipped()
                            .cornerRadius(8)
                    }
                    
                }
                .gridStyle(columns: isGridView ? 1 : 2, spacing: 8)
                .padding(.horizontal, 8)
                Button{
                    Task{
                        await vm.clearAllPhotos()
                    }
                }label: {
                    Text("清除所有图片")
                }
            }
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isGridView.toggle()
                    }) {
                        Image(systemName: isGridView ? "square.fill" : "rectangle.grid.1x2.fill")
                    }
                }
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
