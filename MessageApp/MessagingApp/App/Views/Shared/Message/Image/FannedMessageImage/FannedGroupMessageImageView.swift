//
//  FannedGroupMessageImageView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 9/9/25.
//

import SwiftUI

struct FannedGroupMessageImageView: View {
    @State private var viewModel: GroupMessageImageViewModel
    
    init(viewModel: GroupMessageImageViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                LoadingView()
            case .completed(let images):
                createImageView(images)
            }
        }.task {
            viewModel.getData()
        }
        
    }
    
    @ViewBuilder
    private func createImageView(_ images: [UIImage]) -> some View {
        FannedImageView(images: images)
    }
}

struct FannedImageView: View {
    private let images: [UIImage]
    
    init(images: [UIImage]) {
        self.images = images
    }
    
    var body: some View {
        ZStack {
            ForEach(images.indices, id: \.self) { index in
                Image(uiImage: images[index])
                    .resizable()
                    .clipShape(.rect(cornerRadius: 10))
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

#Preview(body: {
    FannedImageView(images: [
        .init(named: "lion")!,
        .init(named: "elephant")!,
        .init(named: "dog")!,
        .init(named: "horse")!,
    ])
    .frame(width: 150, height: 150)
    
})
