//
//  HTTPTokenProvider.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Foundation
import Combine

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
