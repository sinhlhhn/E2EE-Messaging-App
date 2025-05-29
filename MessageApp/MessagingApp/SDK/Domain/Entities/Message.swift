//
//  Message.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

struct Message: Identifiable, Hashable {
    let id = UUID()
    let messageId: Int
    let content: String
    let isFromCurrentUser: Bool
}
