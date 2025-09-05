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

struct FannedGroupImageView: View {
    @State private var viewModel: GroupMessageImageViewModel
    
    var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                LoadingView()
                    .frame(width: 200, height: 200)
            case .completed(let images):
                createImageView(images)
                    .frame(width: 200, height: 200)
            }
        }.task {
            viewModel.getData()
        }
        
    }
    
    @ViewBuilder
    private func createImageView(_ images: [UIImage]) -> some View {
        ZStack {
            ForEach(images.indices, id: \.self) { index in
                Image(uiImage: images[index])
                    .resizable()
                    .rotationEffect(.degrees(calculateRotationAngle(index)))
                    .offset(x: calculateOffset(index).0, y: calculateOffset(index).1)
            }
        }
    }
    
    private func calculateRotationAngle(_ index: Int) -> Double {
        if index == 0 {
            return 10
        }
        if index == 1 {
            return -10
        }
        return 0
    }
    
    private func calculateOffset(_ index: Int) -> (CGFloat, CGFloat) {
        if index == 0 {
            return (30, -10)
        }
        if index == 1 {
            return (-30, -10)
        }
        return (0, 0)
    }
}
