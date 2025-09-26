//
//  SingleGroupMessageView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 25/9/25.
//

import SwiftUI

struct SingleGroupMessageView: View {
    
    let group: MessageGroup
    @Binding var fullScreenImage: UIImage?
    let cacheImage: UIImage?
    let nsAnimation: Namespace.ID
    
    let didCreateMessageVideoView: (VideoMessage) -> MessageVideoView
    let didCreateMessageAttachmentView: (AttachmentMessage) -> MessageAttachmentView
    let didCreateMessageImageView: (ImageMessage, Message) -> MessageImageView
    let didSelectImageView: (UUID, UIImage) -> Void
    
    var body: some View {
        ForEach(group.messages) { message in
            HStack {
                if message.isFromCurrentUser {
                    Spacer()
                }
                createMessageView(message)
                    .flippedUpsideDown()
                    .id(message.id)
            }
        }
    }
    
    @ViewBuilder
    private func createMessageView(_ message: Message) -> some View {
        switch message.type {
        case .text(let data):
            MessageView(content: data.content)
                .frame(maxWidth: .infinity, alignment: message.isFromCurrentUser ? .trailing : .leading)
                .padding(message.isFromCurrentUser ? .leading : .trailing, 16)
        case .video(let data):
            didCreateMessageVideoView(data)
                .clipShape(.rect(cornerRadius: 10))
                .frame(width: 200, height: 300)
        case .image(let image):
            createSingleImageMessage(data: image, message: message)
        case .attachment(let data):
            didCreateMessageAttachmentView(data)
            .frame(maxWidth: 200, alignment: message.isFromCurrentUser ? .trailing : .leading)
        }
    }
    
    @ViewBuilder
    private func createSingleImageMessage(data: ImageMessage, message: Message) -> some View {
        // This code is used to create a Hero animation for the image.
        // We have a thumbnail and a full-size image, and we want to create a Hero animation between them.
        // The process is as follows:
        //  - The app loads the image from disk.
        //  - When the user taps the thumbnail image, the image flies from the thumbnail to the full-size version.
        //  - When the user dismisses the full-size image, it flies back to the thumbnail.
        //
        // Issue:
        //  - The problem is that `matchedGeometryEffect` only allows one view with the same ID and `isSource = true` at a time.
        //    → To work around this, we create a placeholder and remove the thumbnail when transitioning to the full-size image.
        //  - Since the thumbnail is removed, we have to reload the image from disk. This introduces a delay,
        //    and we show a loading state to the user. However, this loading state prevents SwiftUI from recognizing
        //    the transition properly, resulting in a choppy animation.
        //    → To fix this, we implement a caching mechanism to avoid loading from disk, allowing SwiftUI to perform
        //    a smooth transition.
        if let fullScreenImage = fullScreenImage {
            Image(uiImage: fullScreenImage)
                .resizable()
                .clipShape(.rect(cornerRadius: 10))
                .frame(width: 200, height: 200)
        } else if let image = cacheImage {
            CachedMessageImageView(image: image, geoEffectId: message.id.uuidString, nsAnimation: nsAnimation) { image in
                didSelectImageView(message.id, image)
            }
            .frame(width: 200, height: 200)
        } else {
            didCreateMessageImageView(data, message)
                .frame(width: 200, height: 200)
        }
    }
}

#Preview {
//    SingleGroupMessageView()
}
