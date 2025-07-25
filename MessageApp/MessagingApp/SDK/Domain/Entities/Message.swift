//
//  Message.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

protocol SingleMediaMessage: Hashable {
    var path: URL { get }
}

extension SingleMediaMessage {
    var fileTitle: String {
        path.lastPathComponent
    }
    
    var fileSize: Int {
        var contentLength: Int? = nil

        let attributes = try! FileManager.default.attributesOfItem(atPath: path.path)
        if let fileSize = attributes[.size] as? NSNumber {
            contentLength = fileSize.intValue
            print("Content-Length: \(contentLength)")
        }
        return contentLength ?? 0
    }
}

struct TextMessageData: Hashable {
    let content: String
    
    func getData() -> Data {
        content.data(using: .utf8)!
    }
}

struct VideoMessage: Hashable, SingleMediaMessage {
    let path: URL
    
    func getData() -> Data {
        return try! Data(contentsOf: path)
    }
}

struct ImageMessage: Hashable {
    let path: URL
    let originalName: String
    
    func getData() -> Data {
        return try! Data(contentsOf: path)
    }
}

struct AttachmentMessage: Hashable, SingleMediaMessage {
    let path: URL
    let originalName: String
    
    func getData() -> Data {
        return try! Data(contentsOf: path)
    }
}

enum MessageType: Hashable {
    case text(TextMessageData)
    case image(ImageMessage)
    case video(VideoMessage)
    case attachment(AttachmentMessage)
}

struct Message: Identifiable, Hashable {
    let id = UUID()
    let messageId: Int
    let type: MessageType
    let isFromCurrentUser: Bool
}
