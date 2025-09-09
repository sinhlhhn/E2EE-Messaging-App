//
//  FannedGroupImageView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 9/9/25.
//

import SwiftUI

struct FannedGroupImageView: View {
    @State private var viewModel: GroupMessageImageViewModel
    
    init(viewModel: GroupMessageImageViewModel) {
        self.viewModel = viewModel
    }
    
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
