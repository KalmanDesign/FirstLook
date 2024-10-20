//
//  LockScreenView.swift
//  FirstLook
//
//  Created by Kalman on 2024/10/20.
//

import SwiftUI

struct LockScreenView: View {
    var body: some View {
        Group{
            Image("LockScreen")
                .resizable()
                .scaledToFill()
        }
    }
}
#Preview {
    LockScreenView()
}
