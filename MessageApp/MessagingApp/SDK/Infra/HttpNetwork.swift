//
//  HttpNetwork.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import Combine

final class HttpNetwork: NetworkModule {
    func fetchUsers() -> AnyPublisher<[User], Error> {
        guard let url = URL(string: "http://localhost:3000/users") else {
            return Fail<[User], Error>(error: NSError(domain: "Invalid URL", code: 0, userInfo: nil)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response in
                
                guard let code = (response as? HTTPURLResponse)?.statusCode else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                guard code == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                let list = try JSONDecoder().decode(ListUser.self, from: data)
                return list.users
            }
            .eraseToAnyPublisher()
    }
    
    func fetchSalt(sender: String, receiver: String) -> AnyPublisher<String, Error> {
        let urlString = "http://localhost:3000/session"
        
        let urlRequest = buildRequest(url: urlString, method: .post, body: [
            "senderUsername": sender,
            "receiverUsername": receiver
        ])
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                
                guard let code = (response as? HTTPURLResponse)?.statusCode else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                guard code == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                let salt = try JSONDecoder().decode(SaltResponse.self, from: data)
                return salt.salt
            }
            .eraseToAnyPublisher()
    }
    
    func fetchReceiverKey(username: String) -> AnyPublisher<String, Error> {
        let urlString = "http://localhost:3000/keys/\(username)"
        
        let urlRequest = buildRequest(url: urlString)
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                
                guard let code = (response as? HTTPURLResponse)?.statusCode else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                guard code == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                let result = try JSONDecoder().decode(PublicKeyResponse.self, from: data)
                return result.publicKey
            }
            .eraseToAnyPublisher()
    }
    
    func fetchEncryptedMessages(data: FetchMessageData) -> AnyPublisher<[Message], any Error> {
        let sender = data.sender
        let urlString = "http://localhost:3000/messages/\(data.sender)/\(data.receiver)"
        
        var params = [String: Any]()
        if let before = data.before {
            params["before"] = before
        }
        if let limit = data.limit {
            params["limit"] = limit
        }
        
        let urlRequest = buildRequest(url: urlString, parameters: params)
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                
                guard let code = (response as? HTTPURLResponse)?.statusCode else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                guard code == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                let list = try JSONDecoder().decode([MessageResponse].self, from: data)
                return list.map { Message(messageId: $0.id, content: $0.text, isFromCurrentUser: $0.sender == sender)}
            }
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

func buildRequest(url: String, parameters: [String: Any]? = nil, method: HttpMethod = .get, headers: [String: String]? = nil, token: String? = nil, body: [String: Any]? = nil) -> URLRequest {
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

    if let token = token {
        urlRequest.setBearerToken(token)
    }

    if let body = body, let data = try? JSONSerialization.data(withJSONObject: body) {
        urlRequest.httpBody = data
    }

    return urlRequest
}
