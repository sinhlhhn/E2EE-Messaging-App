//
//  SocketUseCase.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 22/5/25.
//

import Foundation
import Combine

protocol SocketUseCase<User, Message> {
    associatedtype User
    associatedtype Message
    func connect(user: User) -> AnyPublisher<Void, Error>
    //TODO: -display status of message: sending, sent, read
    func sendMessage(_ message: Message)
    func subscribeToIncomingMessages() -> AnyPublisher<Message, Error>
}
