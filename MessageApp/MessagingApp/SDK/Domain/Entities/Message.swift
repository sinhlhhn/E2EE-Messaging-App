//
//  Message.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

enum MessageType: Hashable {
    case text(String)
    case image(URL)
    case video(URL)
}

struct Message: Identifiable, Hashable {
    let id = UUID()
    let messageId: Int
    let type: MessageType
    let isFromCurrentUser: Bool
    
    func getData() -> Data {
        switch type {
        case .text(let text):
            return text.data(using: .utf8)!
        case .image(let url):
            return try! Data(contentsOf: url)
        case .video(let url):
            return try! Data(contentsOf: url)
        }
    }
}
