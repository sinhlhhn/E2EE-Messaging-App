//
//  PasswordAuthenticationService.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import Combine

import CryptoKit

final class PasswordAuthenticationService: AuthenticationUseCase {
    
    private let unauthenticatedNetwork: UnauthenticatedNetworking
    private let network: NetworkModule
    private let secureKey: any SecureKeyModule<P256ExchangeKey, P256KeyData>
    private let keyStore: KeyStoreModule
    private let restoreKey: RestoreKeyModule
    
    init(unauthenticatedNetwork: UnauthenticatedNetworking, network: NetworkModule, secureKey: any SecureKeyModule<P256ExchangeKey, P256KeyData>, keyStore: KeyStoreModule, restoreKey: RestoreKeyModule) {
        self.unauthenticatedNetwork = unauthenticatedNetwork
        self.network = network
        self.secureKey = secureKey
        self.keyStore = keyStore
        self.restoreKey = restoreKey
    }
    
    func register(data: PasswordAuthentication) -> AnyPublisher<User, any Error> {
        let registerPublisher = unauthenticatedNetwork.registerUser(data: data)
        
        let userPublisher = registerPublisher
            .map { $0.user }
            .handleEvents(receiveOutput: { [weak self] user in
                self?.storeUserInformation(user)
            })
            .first()
            .eraseToAnyPublisher()
        
        let keyPublisher = registerPublisher
            .map { authenticationModel in
                self.keyStore.store(key: .refreshToken, value: authenticationModel.refreshToken)
            }
            .flatMap { _ in
                let exchangeKey = self.secureKey.generateExchangeKey()
                self.keyStore.store(key: .privateKey, value: exchangeKey.privateKey)
                return self.network.sendPublicKey(user: data.email, publicKey:  exchangeKey.publicKey)
                    .map { _ in exchangeKey.privateKey }
            }
            .tryMap { key in
                try self.restoreKey.encryptPrivateKeyForBackup(privateKeyData: key, password: data.password)
            }
            .flatMap { encryptedKey, salt in
                return self.network.sendBackupKey(user: data.email, salt: salt.base64EncodedString(), encryptedKey: encryptedKey.base64EncodedString())
            }
            .first()
            .eraseToAnyPublisher()
        
        return Publishers.Zip(userPublisher, keyPublisher)
            .map { user, _ in user }
            .eraseToAnyPublisher()
    }
    
    func login(data: PasswordAuthentication) -> AnyPublisher<User, Error> {
        let loginPublisher = unauthenticatedNetwork.logInUser(data: data)
            .share()

        let userPublisher = loginPublisher
            .map { $0.user }
            .handleEvents(receiveOutput: { [weak self] user in
                self?.storeUserInformation(user)
            })
            .first()
            .eraseToAnyPublisher()

        let keyPublisher = loginPublisher
            .map { data in
                self.keyStore.store(key: .refreshToken, value: data.refreshToken)
            }
            .flatMap { _ in
                self.network.fetchRestoreKey(username: data.email)
            }
            .tryMap { response in
                try self.restoreKey.restoreKey(response: response, data: data)
            }
            .map { key in
                self.keyStore.store(key: .privateKey, value: key)
            }
            .first()
            .eraseToAnyPublisher()

        return Publishers.Zip(userPublisher, keyPublisher)
            .map { user, _ in user }
            .eraseToAnyPublisher()
    }
    
    private func storeUserInformation(_ user: User) {
        keyStore.store(key: .userName, value: user.username)
        keyStore.store(key: .userId, value: user.id)
    }
}
