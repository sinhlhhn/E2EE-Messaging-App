//
//  MessageView 2.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/7/25.
//


import SwiftUI

struct MessageImageView: View {
    @State private var viewModel: MessageImageViewModel
    
    private let geoEffectId: String
    private let nsAnimation: Namespace.ID
    
    private let didTapImage: (UIImage) -> Void
    
    init(geoEffectId: String, nsAnimation: Namespace.ID, viewModel: MessageImageViewModel, didTapImage: @escaping (UIImage) -> Void) {
        self.viewModel = viewModel
        self.didTapImage = didTapImage
        self.nsAnimation = nsAnimation
        self.geoEffectId = geoEffectId
    }
    
    var body: some View {
        contentView
    }
    
    private var contentView: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                LoadingView()
                    .frame(width: 200, height: 400)
            case .completed(let image):
                CachedMessageImageView(image: image, geoEffectId: geoEffectId, nsAnimation: nsAnimation, didTapImage: didTapImage)
            }
        }.task {
            viewModel.getData()
        }
        
    }
}

//#Preview {
//    MessageImageView(image: "tiger")
//}
