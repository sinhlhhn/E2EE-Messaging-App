//
//  HttpNetwork.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import Combine

final class AuthenticatedNetwork: NetworkModule {
    private let network: HTTPClient
    
    init(network: HTTPClient) {
        self.network = network
    }
    
    func logOut(userName: String) -> AnyPublisher<Void, any Error> {
        let urlString = "http://localhost:3000/api/logout"
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
        let urlString = "http://localhost:3000/api/keys"
        
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
        let urlString = "http://localhost:3000/api/key-backup"
        
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
        let urlString = "http://localhost:3000/api/key-backup/\(username)"
        
        let request = buildRequest(url: urlString)
        
        return network.perform(request: request)
            .tryMap { data, response -> RestoreKeyResponse in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.toRestoreKeyModel() }
            .eraseToAnyPublisher()
    }
    
    func fetchUsers() -> AnyPublisher<[User], Error> {
        let urlString = "http://localhost:3000/api/users"
        
        let request = buildRequest(url: urlString)
        
        return network.perform(request: request)
            .tryMap { data, response -> ListUser in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.users }
            .eraseToAnyPublisher()
    }
    
    func fetchSalt(sender: String, receiver: String) -> AnyPublisher<String, Error> {
        let urlString = "http://localhost:3000/api/session"
        
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
        let urlString = "http://localhost:3000/api/keys/\(username)"
        
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
        let urlString = "http://localhost:3000/api/messages/\(data.sender)/\(data.receiver)"
        
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
}

extension URLRequest {
    public mutating func addApplicationJsonContentAndAcceptHeaders() {
        let value = "application/json"
        addValue(value, forHTTPHeaderField: "Content-Type")
        addValue(value, forHTTPHeaderField: "Accept")
    }
    
    public mutating func setBearerToken(_ token: String) {
        setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

extension URLComponents {
    mutating func addQueryParameters(params: [String: Any]) {
        queryItems = [URLQueryItem]()
        for (key, value) in params {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            queryItems?.append(queryItem)
        }
    }
}

enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

func buildRequest(url: String, parameters: [String: Any]? = nil, method: HttpMethod = .get, headers: [String: String]? = nil, body: [String: Any]? = nil) -> URLRequest {
    var components = URLComponents(string: url)

    // URLComponents(string: url) can't init with url params contains double quote
    if components == nil, let urlQueryAllowed = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
        components = URLComponents(string: urlQueryAllowed)
    }
    
    if let parameters = parameters {
        components?.addQueryParameters(params: parameters)
    }

    guard let urlWithParameters = components?.url else {
        return URLRequest(url: URL(fileURLWithPath: ""))
    }

    var urlRequest = URLRequest(url: urlWithParameters)
    urlRequest.httpMethod = method.rawValue
    urlRequest.addApplicationJsonContentAndAcceptHeaders()

    for (headerField, value) in headers ?? [:] {
        urlRequest.addValue(value, forHTTPHeaderField: headerField)
    }

    if let body = body, let data = try? JSONSerialization.data(withJSONObject: body) {
        urlRequest.httpBody = data
    }

    return urlRequest
}

extension Encodable {
    /// Returns a dictionary version of the Encodable object, if the conversion fails it throws an
    /// Error
    public func asDictionary(
        keyStrategy: JSONEncoder.KeyEncodingStrategy? = nil
    ) throws -> [String: Any] {
        let encoder = JSONEncoder()
        if let keyStrategy = keyStrategy {
            encoder.keyEncodingStrategy = keyStrategy
        }
        guard let json = try JSONSerialization.jsonObject(
            with: try encoder.encode(self),
            options: .allowFragments
        ) as? [String: Any] else {
            throw NSError(domain: "cannot encode", code: -1)
        }

        return json
    }
}
