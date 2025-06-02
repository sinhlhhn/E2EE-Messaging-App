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
    
    private let network: NetworkModule
    private let secureKey: any SecureKeyModule<P256ExchangeKey, P256KeyData>
    private let keyStore: KeyStoreModule
    private let restoreKey: RestoreKeyModule
    
    init(network: NetworkModule, secureKey: any SecureKeyModule<P256ExchangeKey, P256KeyData>, keyStore: KeyStoreModule, restoreKey: RestoreKeyModule) {
        self.network = network
        self.secureKey = secureKey
        self.keyStore = keyStore
        self.restoreKey = restoreKey
    }
    
    func register(data: PasswordAuthentication) -> AnyPublisher<Void, any Error> {
        return network.registerUser(data: data)
            .flatMap { _ in
                let exchangeKey = self.secureKey.generateExchangeKey()
                self.keyStore.store(key: data.email, value: exchangeKey.privateKey)
                return self.network.sendPublicKey(user: data.email, publicKey:  exchangeKey.publicKey)
                    .map { _ in exchangeKey.privateKey }
            }
            .tryMap { key in
                try self.restoreKey.encryptPrivateKeyForBackup(privateKeyData: key, password: data.password)
            }
            .flatMap { encryptedKey, salt in
                return self.network.sendBackupKey(user: data.email, salt: salt.base64EncodedString(), encryptedKey: encryptedKey.base64EncodedString())
            }
            .map { _ in
                self.keyStore.store(key: .loggedInUserKey, value: data.email)
                return ()
            }
            .first()
            .eraseToAnyPublisher()
    }
    
    func login(data: PasswordAuthentication) -> AnyPublisher<Void, Error> {
        network.fetchRestoreKey(username: data.email)
            .map { response in
                response.toRestoreKeyModel()
            }
            .tryMap { response in
                try self.restoreKey.restoreKey(response: response, data: data)
            }
            .map { key in
                self.keyStore.store(key: data.email, value: key)
                return ()
            }
            .first()
            .eraseToAnyPublisher()
    }
}
