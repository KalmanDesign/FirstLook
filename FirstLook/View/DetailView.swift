//
//  DetailView.swift
//  FreshLook
//
//  Created by Kalman on 2024/10/18.
//

import SwiftUI
import Kingfisher

struct DetailView: View {
    let photo: any Photo
    @EnvironmentObject private var vm: ViewModel
    @State private var showInfoSheet = false
    
    
    var body: some View {
        GeometryReader { geo in
            KFImage(URL(string: photo.urls.raw))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .overlay(alignment: .bottomLeading) {
                    HStack(alignment: .bottom, spacing: 8) {
                        Spacer()
                        ButtonGroup(showInfoSheet: $showInfoSheet, photo: photo)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 20)
                    .padding(.horizontal, 20)
                }
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $showInfoSheet) {
            VStack(alignment: .center,spacing: 12){
                Text(photo.user.username.capitalized)
                    .font(.title2)
                    .bold()
                Text(photo.user.bio ?? "The absence of a bio makes it hard to know the subject but could imply mystery and offer a chance for discovery.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(16)
            .presentationDetents([.height(160), .height(200)])
        }
    }
}

struct ButtonGroup: View {
    @EnvironmentObject private var vm: ViewModel
    @Binding var showInfoSheet: Bool
    let photo: any Photo // 添加了photo参数
    
    var body: some View {
        Button {
            vm.toggleFavorite(photo)
        } label: {
            Image(systemName: photo.isFavorite ?? false ? "heart.fill" : "heart")
                .foregroundColor(photo.isFavorite ?? false ? .red : .white)
                .padding(16)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
        
        Button {
            showInfoSheet.toggle()
        } label: {
            Image(systemName: "info.circle")
                .foregroundColor(.white)
                .padding(16)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
        
    }
}







#Preview {
    DetailView(photo: FirstLook(id: "Dwu85P9SOIk",
                                urls: PhotoModel.Urls(raw: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d",
                                                      full: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d?q=75&fm=jpg",
                                                      regular: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d?q=75&fm=jpg&w=1080&fit=max",
                                                      small: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d?q=75&fm=jpg&w=400&fit=max",
                                                      thumb: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d?q=75&fm=jpg&w=200&fit=max"),
                                user: PhotoModel.User(id: "QPxL2MGqfrw", name: "Joe Example", username: "joe_example"),
                                isFavorite: false))
}
