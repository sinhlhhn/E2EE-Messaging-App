//
//  SplashView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/6/25.
//

import SwiftUI

struct SplashView: View {
    let viewModel: SplashViewModel
    
    init(viewModel: SplashViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Text("Splash screen")
    }
}
