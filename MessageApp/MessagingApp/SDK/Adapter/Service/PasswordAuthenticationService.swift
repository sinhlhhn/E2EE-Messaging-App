//
//  PasswordAuthenticationService.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import Combine

final class PasswordAuthenticationService: AuthenticationUseCase {
    
    private let secureKey: any SecureKeyModule<P256ExchangeKey, P256KeyData>
    private let keyStore: KeyStoreModule
    
    init(secureKey: any SecureKeyModule<P256ExchangeKey, P256KeyData>, keyStore: KeyStoreModule) {
        self.secureKey = secureKey
        self.keyStore = keyStore
    }
    
    func login(data: PasswordAuthentication) -> AnyPublisher<Bool, Error> {
        return registerUser(username: data.email)
            .flatMap { _ in
                let exchangeKey = self.secureKey.generateExchangeKey()
                self.keyStore.store(key: data.email, value: exchangeKey.privateKey)
                return self.sendPublicKey(user: data.email, publicKey:  exchangeKey.publicKey)
            }
            .map { _ in
                self.keyStore.store(key: .loggedInUserKey, value: data.email)
                return true
            }
            .first()
            .eraseToAnyPublisher()
    }
    
    private func sendPublicKey(user: String, publicKey: Data) -> AnyPublisher<Void, Error> {
        let urlString = "http://localhost:3000/keys"
        
        let request = buildRequest(url: urlString, method: .post, body: [
            "username": user,
            "publicKey": publicKey.base64EncodedString()
        ])
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                
                guard let code = (response as? HTTPURLResponse)?.statusCode else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                guard code == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                return Void()
            }
            .eraseToAnyPublisher()
    }
    
    private func registerUser(username: String) -> AnyPublisher<Void, Error> {
        let urlString = "http://localhost:3000/users"
        
        let request = buildRequest(url: urlString, method: .post, body: ["username": username])
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                
                guard let code = (response as? HTTPURLResponse)?.statusCode else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                guard code == 200 else {
                    let error = URLError(.badServerResponse)
                    throw error
                }
                
                return Void()
            }
            .eraseToAnyPublisher()
    }
}
