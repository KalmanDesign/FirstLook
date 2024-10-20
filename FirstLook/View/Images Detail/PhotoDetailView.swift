//
//  DetailView.swift
//  FreshLook
//
//  Created by Kalman on 2024/10/18.
//

import SwiftUI
import Kingfisher

struct ImageDetailView: View {
    let photo: any Photo
    @EnvironmentObject private var vm: ViewModel
    @State private var showInfoSheet = false
    @State private var overlayState: Int = 0
    @State private var isImageLoadingFailed = false
    @State private var showToast = false
    
    
    
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                
                KFImage(URL(string: photo.urls.full))
                    .placeholder { // 在图片加载时显示
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                    .fade(duration: 0.25) // 添加淡入效果
                    .onFailure() { error in
                           // 这里可以设置一个 @State 变量来显示错误信息
                           print("Image loading failed: \(error.localizedDescription)")
                       }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .blur(radius: overlayState == 1 ? 10 : 0)
                    .scaleEffect(overlayState == 1 ? 1.2 : 1, anchor: .center)
                    
                
                Group {
                    if overlayState == 1 {
                        AppleAppGirdView()
                            .disabled(true)
                            .offset(x: 0, y: 80)
                    } else if overlayState == 2 {
                        Color.black.opacity(0.3)
                        LockScreenView()
                    }
                }
                
            }
        }
        .overlay(alignment: .bottomLeading) {
            HStack(alignment: .bottom) {
                ButtonGroup(showInfoSheet: $showInfoSheet, overlayState: $overlayState, showToast: $showToast, photo: photo)
            }
            .padding()
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.bottom, 16)
            .padding(.horizontal, 12)
            .zIndex(100)
        }
        .overlay(alignment: .top){
            if showToast{
                ToastView(photo: photo)
                    .offset(y: UIScreen.main.bounds.height / 2)
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


struct ToastView: View {
    @EnvironmentObject private var vm: ViewModel
    let photo: any Photo // 添加了photo参数
    var body: some View {
        HStack {
             Image(systemName: photo.isFavorite ?? false ? "heart.fill" : "heart")
                .foregroundColor(photo.isFavorite ?? false ? .red : .white)
            Text(photo.isFavorite ?? false ? "Favorite successfully" : "Cancel Favorite") // 显示文字
                .foregroundColor(.white) // 设置文字颜色为白色
        }
        .padding() // 设置内边距
        .background(Color.black.opacity(0.5)) // 设置背景颜色为半透明黑色
        .cornerRadius(12)
            .zIndex(100)
    }
}


struct ButtonGroup: View {
    @EnvironmentObject private var vm: ViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var showInfoSheet: Bool
    @Binding var overlayState: Int
    @Binding var showToast: Bool
    let photo: any Photo // 添加了photo参数
    
    
    var body: some View {
        HStack{
            Button{
                dismiss()
            }label: {
                Image(systemName: "arrow.uturn.backward")
                    .resizable()  // 使图标可调整大小
                    .aspectRatio(contentMode: .fit)  // 保持宽高比
                    .frame(width: 14, height: 14)  // 设置固定大小为14
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // 收藏按钮
            Button {
                let impact = UIImpactFeedbackGenerator(style: .rigid)
                impact.impactOccurred()
                vm.toggleFavorite(photo)
                 showToast = true
                DispatchQueue.main.asyncAfter(deadline: .now()+1.4){
                    withAnimation {
                        showToast = false
                    }
                }
            } label: {
                Image(systemName: photo.isFavorite ?? false ? "heart.fill" : "heart")
                    .resizable()
                    .aspectRatio(contentMode: .fit)  // 保持宽高比
                    .frame(width: 14, height: 14)  // 设置固定大小为14
                    .foregroundColor(photo.isFavorite ?? false ? .red : .white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            // 控制sheet的显示
            Button {
                let impact = UIImpactFeedbackGenerator(style: .rigid)
                impact.impactOccurred()
                showInfoSheet.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .resizable()  // 使图标可调整大小
                    .aspectRatio(contentMode: .fit)  // 保持宽高比
                    .frame(width: 14, height: 14)  // 设置固定大小为14
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            // 切换视图展示
            Button{
                let impact = UIImpactFeedbackGenerator(style: .rigid)
                impact.impactOccurred()
                withAnimation {
                    overlayState = (overlayState + 1) % 3
                }
            }label: {
                Image(systemName: overlayStateIcons)
                    .resizable()  // 使图标可调整大小
                    .aspectRatio(contentMode: .fit)  // 保持宽高比
                    .frame(width: 14, height: 14)  // 设置固定大小为14
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
        }
    }
    private var overlayStateIcons:String{
        switch overlayState {
        case 0:
            return "square.grid.2x2"
        case 1:
            return "lock"
        case 2:
            return "xmark.circle"
        default:
            return "square.grid.2x2"
        }
    }
}







#Preview {
    ImageDetailView(photo: FirstLook(id: "Dwu85P9SOIk",
                                     urls: PhotoModel.Urls(raw: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d",
                                                           full: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d?q=75&fm=jpg",
                                                           regular: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d?q=75&fm=jpg&w=1080&fit=max",
                                                           small: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d?q=75&fm=jpg&w=400&fit=max",
                                                           thumb: "https://images.unsplash.com/photo-1417325384643-aac51acc9e5d?q=75&fm=jpg&w=200&fit=max"),
                                     user: PhotoModel.User(id: "QPxL2MGqfrw", name: "Joe Example", username: "joe_example"),
                                     isFavorite: false))
}
