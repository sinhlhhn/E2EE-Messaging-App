//
//  File.swift
//  MessagingApp
//
//  Created by Sam on 21/5/25.
//

import Combine

let mockMessages: [Message] = [
    Message(messageId: 1, content: "Hey, how are you?", isFromCurrentUser: true),
    Message(messageId: 2, content: "I'm good, thanks! How about you?", isFromCurrentUser: false),
    Message(messageId: 3, content: "Doing well. Did you finish the project?", isFromCurrentUser: true),
    Message(messageId: 4, content: "Yes, I submitted it this morning.", isFromCurrentUser: false),
    Message(messageId: 5, content: "Great job! I'll review it soon.", isFromCurrentUser: true),
    Message(messageId: 6, content: "Thanks, let me know if you have feedback.", isFromCurrentUser: false),
    Message(messageId: 7, content: "Sure. Want to grab lunch later?", isFromCurrentUser: true),
    Message(messageId: 8, content: "Sounds good! Where do you want to go?", isFromCurrentUser: false),
    Message(messageId: 9, content: "Maybe the new place near the office?", isFromCurrentUser: true),
    Message(messageId: 10, content: "Perfect, I’ve heard good things about it.", isFromCurrentUser: false),
    Message(messageId: 11, content: "Let’s meet at 12:30?", isFromCurrentUser: true),
    Message(messageId: 12, content: "Works for me. See you then!", isFromCurrentUser: false),
    Message(messageId: 13, content: "By the way, are you attending the workshop tomorrow?", isFromCurrentUser: true),
    Message(messageId: 14, content: "Yes, I registered last week.", isFromCurrentUser: false),
    Message(messageId: 15, content: "Nice. I’ll see you there as well.", isFromCurrentUser: true),
    Message(messageId: 16, content: "Looking forward to it!", isFromCurrentUser: false),
    Message(messageId: 17, content: "Oh, can you send me the slides from the last meeting?", isFromCurrentUser: false),
    Message(messageId: 18, content: "Sure, I’ll email them to you in a bit.", isFromCurrentUser: true),
    Message(messageId: 19, content: "Thanks, appreciate it!", isFromCurrentUser: false),
    Message(messageId: 20, content: "No problem at all!", isFromCurrentUser: true)
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
}

final class NullAuthenticationService<Authentication>: AuthenticationUseCase {
    func login(data: Authentication) -> AnyPublisher<Bool, Error> {
        Empty<Bool, Error>().eraseToAnyPublisher()
    }
}

final class NullUserService: UserUseCase {
    func fetchUsers() -> AnyPublisher<[User], any Error> {
        Empty<[User], Error>().eraseToAnyPublisher()
    }
}

final class NullMessageService: MessageUseCase {
    func fetchMessages(data: FetchMessageData) -> AnyPublisher<[Message], any Error> {
        Empty<[Message], Error>().eraseToAnyPublisher()
    }
}
