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
    let text: String
    let createdAt: String
}
