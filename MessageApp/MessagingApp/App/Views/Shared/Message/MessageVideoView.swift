//
//  MessageVideoView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 16/7/25.
//

import SwiftUI
import AVKit

struct MessageVideoView: View {
    @State var player: AVPlayer
    @State var isPlaying: Bool = false
    
    init(source: String, fileExtension: String? = nil) {
        player = AVPlayer(
            url: Bundle.main.url(
                forResource: source,
                withExtension: fileExtension
            )! //TODO: -Handle invalid resource
        )
    }
    
    var body: some View {
        ZStack {
            VideoPlayer(player: player)
                .clipShape(.rect(cornerRadius: 10))
                .frame(maxWidth: 200, maxHeight: 400)
            
            Button {
                isPlaying ? player.pause() : player.play()
                isPlaying.toggle()
                player.seek(to: .zero)
            } label: {
                Image(systemName: isPlaying ? "stop.circle" : "play.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                    .padding()
            }
        }
    }
}

#Preview {
    MessageVideoView(source: "freevideo.mp4", fileExtension: nil)
}
