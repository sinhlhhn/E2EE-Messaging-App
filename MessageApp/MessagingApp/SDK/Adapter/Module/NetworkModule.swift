//
//  NetworkModule.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import Combine

// TODO: -Can extract to small module: UserCloudModule, NetworkCloudModule
protocol NetworkModule {
    func fetchUsers() -> AnyPublisher<[User], Error>
    
    func fetchReceiverKey(username: String) -> AnyPublisher<String, Error>
    func fetchSalt(sender: String, receiver: String) -> AnyPublisher<String, Error>
    func fetchEncryptedMessages(data: FetchMessageData) -> AnyPublisher<[Message], any Error>
}
