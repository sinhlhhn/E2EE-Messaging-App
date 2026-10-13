//
//  Message.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

// This domain model can be call from any isolation
public nonisolated
protocol SingleMediaMessage: Hashable {
    var path: URL { get }
}

public extension SingleMediaMessage {
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

public struct TextMessageData: Hashable {
    let id = UUID()
    public let content: String
    
    public init(content: String) {
        self.content = content
    }
    
    func getData() -> Data {
        content.data(using: .utf8)!
    }
}

public struct VideoMessage: Hashable, SingleMediaMessage {
    let id = UUID()
    public let path: URL
    public let originalName: String
    
    public init(path: URL, originalName: String) {
        self.path = path
        self.originalName = originalName
    }
    
    func getData() -> Data {
        return try! Data(contentsOf: path)
    }
}

public struct ImageMessage: Hashable {
    public let id = UUID()
    public let path: URL
    public let originalName: String
    
    public init(path: URL, originalName: String) {
        self.path = path
        self.originalName = originalName
    }
}

public struct AttachmentMessage: Hashable, SingleMediaMessage {
    let id = UUID()
    public let path: URL
    public let originalName: String
    
    public init(path: URL, originalName: String) {
        self.path = path
        self.originalName = originalName
    }
    
    func getData() -> Data {
        return try! Data(contentsOf: path)
    }
}

enum RemoteMessageType: Hashable {
    case text(TextMessageData)
    case image(ImageMessage)
    case video(VideoMessage)
    case attachment(AttachmentMessage)
}

public struct RemoteMessage {
    let id: Int
    let type: RemoteMessageType
    let isFromCurrentUser: Bool
    let groupId: UUID?
    let createdDate: Double
}

public enum MessageType: Hashable {
    case text(TextMessageData)
    case image(ImageMessage)
    case video(VideoMessage)
    case attachment(AttachmentMessage)
}

public struct Message: Identifiable, Hashable {
    public let id = UUID()
    public let remoteId: Int?
    public let type: MessageType
    public let isFromCurrentUser: Bool
    public let groupId: UUID?
    public let createdDate: Double
    
    public init(remoteId: Int?, type: MessageType, isFromCurrentUser: Bool, groupId: UUID?, createdDate: Double) {
        self.remoteId = remoteId
        self.type = type
        self.isFromCurrentUser = isFromCurrentUser
        self.groupId = groupId
        self.createdDate = createdDate
    }
}
