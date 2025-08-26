//
//  MessageVideoView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/7/25.
//

import SwiftUI
import AVKit

struct MessageVideoView: View {
    @State private var isPlaying: Bool = false
    @State private var viewModel: MessageVideoViewModel
    @State private var player = AVPlayer(playerItem: nil)
    
    init(viewModel: MessageVideoViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                loadingView
            case .completed(let url):
                createVideoPlayer()
                    .task {
                        player = AVPlayer(url: url)
                    }
            }
        }
        .task {
            viewModel.getData()
        }
    }
    
    private var loadingView: some View {
        ProgressView()
    }
    
    private func createVideoPlayer() -> some View {
        return ZStack {
            VideoPlayer(player: player)
        }
    }
}



//#Preview {
//    MessageVideoView(viewModel: .init(message: "freevideo.mp4", downloadNetwork: nil))
//}
