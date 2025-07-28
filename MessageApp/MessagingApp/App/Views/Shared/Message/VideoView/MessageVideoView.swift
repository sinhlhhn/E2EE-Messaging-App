//
//  MessageVideoView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/7/25.
//

import SwiftUI
import AVKit

struct MessageVideoView: View {
    @State var isPlaying: Bool = false
    let viewModel: MessageVideoViewModel
    
    init(viewModel: MessageVideoViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                loadingView
            case .completed(let url):
                let player = AVPlayer(url: url)
                createVideoPlayer(player: player)
            }
        }
        .task {
            viewModel.getData()
        }
    }
    
    private var loadingView: some View {
        ProgressView()
    }
    
    private func createVideoPlayer(player: AVPlayer?) -> some View {
        return ZStack {
            VideoPlayer(player: player)
                .clipShape(.rect(cornerRadius: 10))
                .frame(width: 200, height: 400)
        }
    }
}



//#Preview {
//    MessageVideoView(viewModel: .init(message: "freevideo.mp4", downloadNetwork: nil))
//}
