//
//  HttpNetwork.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import Combine

//let localhost = "http://localhost:3000/"
let localhost = "https://localhost:3000/"

final class AuthenticatedNetwork: NetworkModule {
    private let network: DataTaskHTTPClient
    private let uploadNetwork: UploadTaskHTTPClient
    private let progress: AnyPublisher<Double, Error>
    private let uploadStream: any HTTPClient<URLRequest, Void>
    
    init(network: DataTaskHTTPClient, uploadNetwork: UploadTaskHTTPClient, progress: AnyPublisher<Double, Error>, uploadStream: any HTTPClient<URLRequest, Void>) {
        self.network = network
        self.uploadNetwork = uploadNetwork
        self.progress = progress
        self.uploadStream = uploadStream
    }
    
    //MARK: -Authentication Flow
    func logOut(userName: String) -> AnyPublisher<Void, any Error> {
        let urlString = "\(localhost)api/logout"
        let request = buildRequest(url: urlString, method: .post, body: ["username": userName])
        
        return network.perform(request: request)
            .tryMap { data, response in
                guard response.statusCode == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                return Void()
            }
            .eraseToAnyPublisher()
        
    }
    
    func sendPublicKey(user: String, publicKey: Data) -> AnyPublisher<Void, Error> {
        let urlString = "\(localhost)api/keys"
        
        let request = buildRequest(url: urlString, method: .post, body: [
            "username": user,
            "publicKey": publicKey.base64EncodedString()
        ])
        
        return network.perform(request: request)
            .tryMap { data, response -> String in
                try GenericMapper.map(data: data, response: response)
            }
            .map { _ in Void() }
            .eraseToAnyPublisher()
    }
    
    func sendBackupKey(user: String, salt: String, encryptedKey: String) -> AnyPublisher<Void, Error> {
        let urlString = "\(localhost)api/key-backup"
        
        let request = buildRequest(url: urlString, method: .post, body: [
            "username": user,
            "salt": salt,
            "encryptedKey": encryptedKey
        ])
        
        return network.perform(request: request)
            .tryMap { data, response -> String in
                try GenericMapper.map(data: data, response: response)
            }
            .map { _ in Void() }
            .eraseToAnyPublisher()
    }
    
    func fetchRestoreKey(username: String) -> AnyPublisher<RestoreKeyModel, Error> {
        let urlString = "\(localhost)api/key-backup/\(username)"
        
        let request = buildRequest(url: urlString)
        
        return network.perform(request: request)
            .tryMap { data, response -> RestoreKeyResponse in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.toRestoreKeyModel() }
            .eraseToAnyPublisher()
    }
    
    //MARK: -User
    func fetchUsers() -> AnyPublisher<[User], Error> {
        let urlString = "\(localhost)api/users"
        
        let request = buildRequest(url: urlString)
        
        return network.perform(request: request)
            .tryMap { data, response -> ListUser in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.users }
            .eraseToAnyPublisher()
    }
    
    //MARK: -Conversation
    func fetchSalt(sender: String, receiver: String) -> AnyPublisher<String, Error> {
        let urlString = "\(localhost)api/session"
        
        let request = buildRequest(url: urlString, method: .post, body: [
            "senderUsername": sender,
            "receiverUsername": receiver
        ])
        
        return network.perform(request: request)
            .tryMap { data, response -> SaltResponse in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.salt }
            .eraseToAnyPublisher()
    }
    
    func fetchReceiverKey(username: String) -> AnyPublisher<String, Error> {
        let urlString = "\(localhost)api/keys/\(username)"
        
        let request = buildRequest(url: urlString)
        
        return network.perform(request: request)
            .tryMap { data, response -> PublicKeyResponse in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.publicKey }
            .eraseToAnyPublisher()
    }
    
    func fetchEncryptedMessages(data: FetchMessageData) -> AnyPublisher<[Message], any Error> {
        let sender = data.sender
        let urlString = "\(localhost)api/messages/\(data.sender)/\(data.receiver)"
        
        var params = [String: Any]()
        if let before = data.before {
            params["before"] = before
        }
        if let limit = data.limit {
            params["limit"] = limit
        }
        
        let request = buildRequest(url: urlString, parameters: params)
        
        return network.perform(request: request)
            .tryMap { data, response -> [MessageResponse] in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.map { Message(messageId: $0.id, content: $0.text, isFromCurrentUser: $0.sender == sender)} }
            .eraseToAnyPublisher()
    }
    
    //MARK: -Image
    func uploadImage(
        images: [MultipartImage],
        fields: [FormField] = []
    ) -> AnyPublisher<Void, Error> {
        guard let url = URL(string: "\(localhost)upload") else {
            return Fail<Void, Error>(error: NSError(domain: "", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add fields
        for field in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(field.name)\"\r\n\r\n")
            body.append("\(field.value)\r\n")
        }

        // Add images
        for image in images {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(image.fieldName)\"; filename=\"\(image.fileName)\"\r\n")
            body.append("Content-Type: \(image.mimeType)\r\n\r\n")
            body.append(image.data)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")

        let uploadRequest = (request, body)
        
        let uploadTask = uploadNetwork.perform(request: uploadRequest)
            .tryMap { data, response in
                guard response.statusCode == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                return Void()
            }
            .eraseToAnyPublisher()
        
        return Publishers.CombineLatest(
            progress,
            uploadTask.prepend(())
        )
        .print("--------------- ")
        .map { progress, complete in
            print("slh: \(progress)")
            return Void()
        }
        .eraseToAnyPublisher()
    }
    
    func downloadImage(url: String) -> AnyPublisher<Data, Error> {
        Empty<Data, Error>().eraseToAnyPublisher()
    }
    
    var cancellables: Set<AnyCancellable> = []
    //MARK: -Upload Stream
    func uploadStreamRawData() {
        
//        let data = Data(repeating: 0xAB, count: 100 * 1024 * 1024) // 100MB
//        let contentLength = data.count
//
        
        let message = "*** \(Date())\r\n"
        guard let messageData = message.data(using: .utf8) else { return }
        let contentLength = messageData.count * 3
        
        // Create streamed request
        var request = URLRequest(url: URL(string: "\(localhost)upload/raw/backup.data")!)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
        
        uploadStream.perform(request: request)
            .sink { completion in
                print("uploadStream completion: \(completion)")
            } receiveValue: { response in
                print("uploadStream response: \(response)")
            }
            .store(in: &cancellables)

    }

}

struct MultipartImage {
    let data: Data
    let fieldName: String
    let fileName: String
    let mimeType: String
}

struct FormField {
    let name: String
    let value: String
}

// MARK: - Data helper
private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
