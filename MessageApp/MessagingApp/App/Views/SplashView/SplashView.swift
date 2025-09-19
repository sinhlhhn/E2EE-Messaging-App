//
//  SplashView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/6/25.
//

import SwiftUI

struct SplashView: View {
    @State private var viewModel: SplashViewModel
    
    init(viewModel: SplashViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Text("Splash screen")
            .onAppear {
                print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
                viewModel.checkAuthentication()
            }
    }
}
