//
//  HttpNetwork.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import Combine

struct AuthenticationResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

protocol HTTPClient {
    func perform(request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), Error>
}

extension URLSession: HTTPClient {
    struct InvalidHTTPResponseError: Error {}
    func perform(request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), Error> {
        return dataTaskPublisher(for: request)
            .tryMap { result in
                guard let httpResponse = result.response as? HTTPURLResponse else {
                    throw InvalidHTTPResponseError()
                }
                return (result.data, httpResponse)
            }
            .eraseToAnyPublisher()
    }
}

protocol TokenProvider {
    func fetchToken() -> AnyPublisher<String, Error>
    func refreshToken() -> AnyPublisher<String, Error>
}

final class HTTPTokenProvider: TokenProvider {
    private let network: HTTPClient
    private let keyStore: KeyStoreModule
    
    private var currentToken: String?
    private var refreshSubject: PassthroughSubject<String, Error>?
    private let lock = NSLock()
    private var cancellables = Set<AnyCancellable>()
    
    init(network: HTTPClient, keyStore: KeyStoreModule) {
        self.network = network
        self.keyStore = keyStore
    }
    
    func fetchToken() -> AnyPublisher<String, any Error> {
        if let currentToken = currentToken {
            return Just<String>(currentToken).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        return refreshToken()
    }
    
    func refreshToken() -> AnyPublisher<String, Error> {
        lock.lock()
        defer { lock.unlock() }
        
        // If refresh already in progress, return same publisher
        if let subject = refreshSubject {
            return subject.eraseToAnyPublisher()
        }
        
        let subject = PassthroughSubject<String, Error>()
        refreshSubject = subject
        
        let refreshToken: String? = keyStore.retrieve(key: .refreshToken)
        performRefresh(refreshToken: refreshToken)
            .sink(receiveCompletion: { [weak self] completion in
                self?.lock.lock()
                defer { self?.lock.unlock() }
                
                self?.refreshSubject = nil
                if case .failure(let error) = completion {
                    subject.send(completion: .failure(error))
                }
            }, receiveValue: { [weak self] response in
                self?.keyStore.store(key: .refreshToken, value: response.refreshToken)
                self?.currentToken = response.accessToken
                subject.send(response.accessToken)
                subject.send(completion: .finished)
            })
            .store(in: &cancellables)
        
        return subject.eraseToAnyPublisher()
    }
    
    private func performRefresh(refreshToken: String?) -> AnyPublisher<AuthenticationModel, Error> {
        guard let refreshToken = refreshToken else {
            return Fail<AuthenticationModel, Error>(error: NSError(domain: "Should log out", code: -1)).eraseToAnyPublisher()
        }
        let urlString = "http://localhost:3000/auth/token"
        
        let request = buildRequest(url: urlString, method: .post, body: ["token": refreshToken])
        
        return network.perform(request: request)
            .tryMap { data, response in
                guard response.statusCode == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                let model = try JSONDecoder().decode(AuthenticationResponse.self, from: data)
                
                return AuthenticationModel(accessToken: model.accessToken, refreshToken: model.refreshToken)
            }
            .first()
            .eraseToAnyPublisher()
    }
}

final class AuthenticatedHTTPClient: HTTPClient {
    private let client: HTTPClient
    private let tokenProvider: TokenProvider
    
    init(client: HTTPClient, tokenProvider: TokenProvider) {
        self.client = client
        self.tokenProvider = tokenProvider
    }
    
    func perform(request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), any Error> {
        var request = request
        return tokenProvider.fetchToken()
            .flatMap { token in
                request.setBearerToken(token)
                return self.client.perform(request: request)
            }
            .eraseToAnyPublisher()
    }
}

final class RetryAuthenticatedHTTPClient: HTTPClient {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func perform(request: URLRequest) -> AnyPublisher<(Data, HTTPURLResponse), any Error> {
        let retryTimes = 2
        return client.perform(request: request)
            .catch { error in
                return self.performWithRetry(request, retryTimes: retryTimes)
            }
            .eraseToAnyPublisher()
    }
    
    private func performWithRetry(_ request: URLRequest, retryTimes: Int) -> AnyPublisher<(Data, HTTPURLResponse), any Error> {
        if retryTimes == 0 {
            return Fail<(Data, HTTPURLResponse), any Error>(error: NSError(domain: "", code: 1)).eraseToAnyPublisher() // should log out
        }
        return performWithRetry(request, retryTimes: retryTimes - 1)
    }
}

final class HttpAuthenticationNetwork: AuthenticationNetwork {
    
    private let network: HTTPClient
    
    init(network: HTTPClient) {
        self.network = network
    }
    
    func registerUser(data: PasswordAuthentication) -> AnyPublisher<AuthenticationModel, Error> {
        let urlString = "http://localhost:3000/auth/register"
        
        let request = buildRequest(url: urlString, method: .post, body: try? data.asDictionary())
        
        return network.perform(request: request)
            .tryMap { data, response in
                
                guard response.statusCode == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                let model = try JSONDecoder().decode(AuthenticationResponse.self, from: data)
                
                return AuthenticationModel(accessToken: model.accessToken, refreshToken: model.refreshToken)
            }
            .eraseToAnyPublisher()
    }
    
    func logInUser(data: PasswordAuthentication) -> AnyPublisher<AuthenticationModel, any Error> {
        let urlString = "http://localhost:3000/auth/login"
        
        let request = buildRequest(url: urlString, method: .post, body: try? data.asDictionary())
        
        return network.perform(request: request)
            .tryMap { data, response in
                
                guard response.statusCode == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                let model = try JSONDecoder().decode(AuthenticationResponse.self, from: data)
                
                return AuthenticationModel(accessToken: model.accessToken, refreshToken: model.refreshToken)
            }
            .eraseToAnyPublisher()
    }
}

struct GenericMapper {
    static func map<T>(data: Data, response: HTTPURLResponse) throws -> T where T: Decodable {
        guard response.statusCode == 200 else {
            let error = URLError(.badServerResponse)
            throw error
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

final class AuthenticatedNetwork: NetworkModule {
    private let network: HTTPClient
    
    init(network: HTTPClient) {
        self.network = network
    }
    
    func sendPublicKey(user: String, publicKey: Data) -> AnyPublisher<Void, Error> {
        let urlString = "http://localhost:3000/keys"
        
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
        let urlString = "http://localhost:3000/key-backup"
        
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
        let urlString = "http://localhost:3000/key-backup/\(username)"
        
        let request = buildRequest(url: urlString)
        
        return network.perform(request: request)
            .tryMap { data, response -> RestoreKeyResponse in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.toRestoreKeyModel() }
            .eraseToAnyPublisher()
    }
    
    func fetchUsers() -> AnyPublisher<[User], Error> {
        let urlString = "http://localhost:3000/users"
        
        let request = buildRequest(url: urlString)
        
        return network.perform(request: request)
            .tryMap { data, response -> ListUser in
                try GenericMapper.map(data: data, response: response)
            }
            .map { $0.users }
            .eraseToAnyPublisher()
    }
    
    func fetchSalt(sender: String, receiver: String) -> AnyPublisher<String, Error> {
        let urlString = "http://localhost:3000/session"
        
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
        let urlString = "http://localhost:3000/keys/\(username)"
        
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
        let urlString = "http://localhost:3000/messages/\(data.sender)/\(data.receiver)"
        
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
