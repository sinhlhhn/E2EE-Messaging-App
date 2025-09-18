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
    private let didCompleteDisplayImage: (UIImage) -> Void
    
    init(
        geoEffectId: String,
        nsAnimation: Namespace.ID,
        viewModel: MessageImageViewModel,
        didTapImage: @escaping (UIImage) -> Void,
        didCompleteDisplayImage: @escaping (UIImage) -> Void
    ) {
        self.viewModel = viewModel
        self.didTapImage = didTapImage
        self.didCompleteDisplayImage = didCompleteDisplayImage
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
                    .onAppear {
                        didCompleteDisplayImage(image)
                    }
            }
        }.task {
            await viewModel.getData()
        }
        
    }
}

//#Preview {
//    MessageImageView(image: "tiger")
//}
