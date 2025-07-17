//
//  Message.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

struct MessageText: Hashable {
    let content: String
}

struct MessageVideo: Hashable {
    let path: URL
}

struct ImageVideo: Hashable {
    let path: URL
}

enum MessageType: Hashable {
    case text(MessageText)
    case image(MessageVideo)
    case video(ImageVideo)
}

struct Message: Identifiable, Hashable {
    let id = UUID()
    let messageId: Int
    let type: MessageType
    let isFromCurrentUser: Bool
    
    func getData() -> Data {
        switch type {
        case .text(let text):
            return text.content.data(using: .utf8)!
        case .image(let type):
            return try! Data(contentsOf: type.path)
        case .video(let type):
            return try! Data(contentsOf: type.path)
        }
    }
}
