//
//  MessageService.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 26/5/25.
//

import Foundation
import Combine
import CryptoKit

struct FetchMessageData {
    let sender: String
    let receiver: String
    let before: Int?
    let limit: Int?
    let firstLoad: Bool
    
    init(sender: String, receiver: String, before: Int? = nil, limit: Int? = nil, firstLoad: Bool) {
        self.sender = sender
        self.receiver = receiver
        self.before = before
        self.limit = limit
        self.firstLoad = firstLoad
    }
}

protocol MessageUseCase {
    func fetchMessages(data: FetchMessageData) -> AnyPublisher<[Message], Error>
}
