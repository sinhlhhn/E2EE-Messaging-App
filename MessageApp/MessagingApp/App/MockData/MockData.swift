//
//  File.swift
//  MessagingApp
//
//  Created by Sam on 21/5/25.
//

import Combine
import Foundation

let mockMessages: [Message] = [
    Message(messageId: 1, type: .text(.init(content: "Hey, how are you?")), isFromCurrentUser: true, groupId: nil),
    Message(messageId: 2, type: .text(.init(content: "I'm good, thanks! How about you?")), isFromCurrentUser: false, groupId: nil),
    Message(messageId: 3, type: .text(.init(content: "Doing well. Did you finish the project?")), isFromCurrentUser: true, groupId: nil),
    Message(messageId: 4, type: .text(.init(content: "Yes, I submitted it this morning.")), isFromCurrentUser: false, groupId: nil),
    Message(messageId: 5, type: .text(.init(content: "Great job! I'll review it soon.")), isFromCurrentUser: true, groupId: nil),
    Message(messageId: 6, type: .text(.init(content: "Thanks, let me know if you have feedback.")), isFromCurrentUser: false, groupId: nil),
    Message(messageId: 7, type: .text(.init(content: "Sure. Want to grab lunch later?")), isFromCurrentUser: true, groupId: nil),
    Message(messageId: 8, type: .text(.init(content: "Sounds good! Where do you want to go?")), isFromCurrentUser: false, groupId: nil),
    Message(messageId: 9, type: .text(.init(content: "Maybe the new place near the office?")), isFromCurrentUser: true, groupId: nil),
    Message(messageId: 10, type: .text(.init(content: "Perfect, I’ve heard good things about it.")), isFromCurrentUser: false, groupId: nil),
    Message(messageId: 11, type: .text(.init(content: "Let’s meet at 12:30?")), isFromCurrentUser: true, groupId: nil),
    Message(messageId: 12, type: .text(.init(content: "Works for me. See you then!")), isFromCurrentUser: false, groupId: nil),
    Message(messageId: 13, type: .text(.init(content: "By the way, are you attending the workshop tomorrow?")), isFromCurrentUser: true, groupId: nil),
    Message(messageId: 14, type: .text(.init(content: "Yes, I registered last week.")), isFromCurrentUser: false, groupId: nil),
    Message(messageId: 15, type: .text(.init(content: "Nice. I’ll see you there as well.")), isFromCurrentUser: true, groupId: nil),
    Message(messageId: 16, type: .text(.init(content: "Looking forward to it!")), isFromCurrentUser: false, groupId: nil),
    Message(messageId: 17, type: .text(.init(content: "Oh, can you send me the slides from the last meeting?")), isFromCurrentUser: false, groupId: nil),
    Message(messageId: 18, type: .text(.init(content: "Sure, I’ll email them to you in a bit.")), isFromCurrentUser: true, groupId: nil),
    Message(messageId: 19, type: .text(.init(content: "Thanks, appreciate it!")), isFromCurrentUser: false, groupId: nil),
    Message(messageId: 20, type: .text(.init(content: "No problem at all!")), isFromCurrentUser: true, groupId: nil)
    ]


let mockUsers: [User] = [
    User(id: 1, username: "Sinhlh"),
    User(id: 2, username: "Anhlh")
]

final class NullSocketService<User, Message>: SocketUseCase {
    func sendMessage(_ message: Message) {
        
    }
    
    func subscribeToIncomingMessages() -> AnyPublisher<Message, Error> {
        Empty<Message, Error>().eraseToAnyPublisher()
    }
    
    func connect(user: User) -> AnyPublisher<Void, any Error> {
        Empty<Void, Error>().eraseToAnyPublisher()
    }
    
    func disconnect() {
    }
}

final class NullAuthenticationService<Authentication>: AuthenticationUseCase {
    func login(data: Authentication) -> AnyPublisher<User, Error> {
        Empty().eraseToAnyPublisher()
    }
    
    func register(data: Authentication) -> AnyPublisher<User, any Error> {
        Empty().eraseToAnyPublisher()
    }
}

final class NullUserService: UserUseCase {
    func fetchUsers() -> AnyPublisher<[User], any Error> {
        Empty().eraseToAnyPublisher()
    }
}

final class NullMessageService: MessageUseCase {
    func fetchMessages(data: FetchMessageData) -> AnyPublisher<[Message], any Error> {
        Empty<[Message], Error>().eraseToAnyPublisher()
    }
}

final class NullLogOutUseCase: LogOutUseCase {
    func logOut(userName: String) -> AnyPublisher<Void, any Error> {
        Empty<Void, Error>().eraseToAnyPublisher()
    }
}

final class NullProfileService: ProfileUseCase {
    func downloadImage() {
        
    }
    
    func uploadImage(image: ImageData) -> AnyPublisher<Void, any Error> {
        Empty<Void, Error>().eraseToAnyPublisher()
    }
    
    func uploadStreamRawData() {
        
    }
}
