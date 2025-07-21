//
//  HTTPTokenProvider.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Foundation
import Combine

final class HTTPTokenProvider: TokenProvider {
    private let network: DataTaskHTTPClient
    private let keyStore: KeyStoreModule
    
    private enum AuthState {
        case notAuthenticated
        case authenticated
    }
    
    private enum AuthenticationError: Error {
        case refreshTokenExpired
    }
    
    private let authenticationState = PassthroughSubject<AuthenticationState, Never>()
    
    private var currentToken: String?
    private var refreshSubject: PassthroughSubject<String, Error>?
    private let lock = NSLock()
    private var cancellables = Set<AnyCancellable>()
    
    init(
        network: DataTaskHTTPClient,
        keyStore: KeyStoreModule
    ) {
        self.network = network
        self.keyStore = keyStore
    }
    
    func subscribeToAuthenticationState() -> AnyPublisher<AuthenticationState, Never> {
        authenticationState
            .eraseToAnyPublisher()
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
                    subject.send(completion: .finished)
                    self?.handleError(error: error)
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
    
    private func handleError(error: Error) {
        if let error = error as? AuthenticationError, error == .refreshTokenExpired {
            authenticationState.send(.loggedOut)
        }
    }
    
    private func performRefresh(refreshToken: String?) -> AnyPublisher<TokenModel, Error> {
        guard let refreshToken = refreshToken else {
            return Fail<TokenModel, Error>(error: NSError(domain: "Should log out", code: -1)).eraseToAnyPublisher()
        }
        let urlString = "\(localhost)/auth/token"
        
        let request = buildRequest(url: urlString, method: .post, body: ["token": refreshToken])
        
        return network.perform(request: request)
            .tryMap { data, response in
                let statusCode = response.statusCode
                guard statusCode == 200 else {
                    if statusCode == 403 {
                        debugPrint("Got 403, logout user")
                        throw AuthenticationError.refreshTokenExpired
                    }
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                let model = try JSONDecoder().decode(TokenResponse.self, from: data)
                
                return TokenModel(accessToken: model.accessToken, refreshToken: model.refreshToken)
            }
            .first()
            .eraseToAnyPublisher()
    }
}
