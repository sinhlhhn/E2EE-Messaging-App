//
//  MessageResponse.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

struct MessageResponse: Codable {
    let id: Int
    let sender: String
    let receiverId: Int
    let text: String?
    let mediaUrl: String?
    let mediaType: String
    let createdAt: Double
    let originalName: String?
    let groupId: String?
}

enum MediaType: String {
    case image
    case attachment
    case video
    case text
}


