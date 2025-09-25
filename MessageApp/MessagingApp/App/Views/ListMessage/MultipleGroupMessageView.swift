//
//  MultipleGroupMessageView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 25/9/25.
//

import SwiftUI

struct MultipleGroupMessageView: View {
    let message: MessageGroup
    let nsAnimation: Namespace.ID
    @Binding var fullScreenGroupImage: [UIImage]
    let cacheImage: [UIImage]?
    
    private let didSelectGroupImage: ([UIImage], String) -> Void
    private let didCreateFannedGroupMessageImageView: ([ImageMessage], Message) -> FannedGroupMessageImageView
    
    
    init(
        message: MessageGroup,
        nsAnimation: Namespace.ID,
        fullScreenGroupImage: Binding<[UIImage]>,
        cacheImage: [UIImage]?,
        didSelectGroupImage: @escaping ([UIImage], String) -> Void,
        didCreateFannedGroupMessageImageView: @escaping ([ImageMessage], Message) -> FannedGroupMessageImageView
    ) {
        self.didSelectGroupImage = didSelectGroupImage
        self.didCreateFannedGroupMessageImageView = didCreateFannedGroupMessageImageView
        self.message = message
        self.nsAnimation = nsAnimation
        self.cacheImage = cacheImage
        self._fullScreenGroupImage = fullScreenGroupImage
    }
    
    var body: some View {
        createMultipleGroupMessageView(message)
    }
    
    @ViewBuilder
    private func createMultipleGroupMessageView(_ group: MessageGroup) -> some View {
        let images: [ImageMessage] = group.messages.compactMap {
            if case let .image(image) = $0.type {
                return ImageMessage(path: image.path, originalName: image.originalName)
            }
            return nil
        }
        if let message = group.messages.first {
            HStack {
                if group.isFromCurrentUser == true {
                    Spacer()
                }
                
                createGroupImageMessage(data: images, message: message)
                    .flippedUpsideDown()
                    .id(message.id)
            }
        }
    }
    
    @ViewBuilder
    private func createGroupImageMessage(data: [ImageMessage], message: Message) -> some View {
        if !fullScreenGroupImage.isEmpty {
            FannedImageView(images: fullScreenGroupImage)
                .frame(width: 150, height: 150)
        } else if let images = cacheImage {
            FannedImageView(images: images)
                .matchedGeometryEffect(id: message.id.uuidString, in: nsAnimation)
                .frame(width: 150, height: 150)
                .highPriorityGesture(
                    TapGesture().onEnded {
                        didSelectGroupImage(images, message.id.uuidString)
                    }
                )
        } else {
            didCreateFannedGroupMessageImageView(data, message)
                .matchedGeometryEffect(id: message.id.uuidString, in: nsAnimation)
                .frame(width: 150, height: 150)
        }
    }
}
