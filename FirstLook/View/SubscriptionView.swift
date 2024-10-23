//
//  SubscriptionView.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/23.
//

import SwiftUI

struct SubscriptionView: View {
    var body: some View {
        VStack(spacing: 64){
            VStack(alignment:.leading,spacing: 16){
                Text("Wallpaper PRO")
                    .font(.largeTitle)
                    .bold()
                Text("Wallpaper PRO，为你精选海量壁纸。无限制使用，多种高级功能等你来，如 iCloud 同步、随机壁纸、编辑等。还有快捷指令同步。更多专属订阅会员即将推出，快来让你的屏幕绽放独特魅力，开启个性化之旅。")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            VStack{
                ProText()
                UpgradeButton()
                    .padding(.top, 24)
                Spacer()
            }
            
        }
        .padding(.horizontal,16)
        .preferredColorScheme(.dark)  // 设置深色模式
    }
}


struct ProText: View {
    var body: some View {
        VStack(alignment:.leading,spacing: 20){
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                Text("无限制使用多张精选壁纸,多个主题随心切换，随时随地享受")
            }
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                Text("解锁多个高级功能：iCloud 收藏夹同步，随机壁纸，壁纸编辑等")
            }
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                Text("个性化快捷指令同步")
            }
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                Text("更多专属订阅会员即将推出")
            }
        }
        .font(.body)
        .bold()
    }
}

struct UpgradeButton: View {
    var body: some View {
        VStack(spacing: 24){
            Button {
                
            } label: {
                Text("Upgrade PRO for $12.8")
                    .bold()
                    .padding()
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .background(.white)
                    .cornerRadius(36)
            }
            
            VStack(spacing: 8){
                Text("一次订阅永久有效")
                Text("已经解锁？ 点击恢复购买记录")
            }
            .font(.caption)
            HStack(spacing: 12){
                Text("隐私政策")
                Text("条款与条件")
            }
            .font(.caption)
        }
    }
}

#Preview {
    SubscriptionView()
}
