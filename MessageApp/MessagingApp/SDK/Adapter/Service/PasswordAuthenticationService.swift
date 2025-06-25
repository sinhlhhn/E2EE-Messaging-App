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
    
    func register(data: PasswordAuthentication) -> AnyPublisher<Void, any Error> {
        return unauthenticatedNetwork.registerUser(data: data)
            .map { data in
                self.keyStore.store(key: .refreshToken, value: data.refreshToken)
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
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.keyStore.store(key: .userName, value: data.email)
            })
            .first()
            .eraseToAnyPublisher()
    }
    
    func login(data: PasswordAuthentication) -> AnyPublisher<Void, Error> {
        unauthenticatedNetwork.logInUser(data: data)
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
                self.keyStore.store(key: .userName, value: data.email)
                return ()
            }
            .first()
            .eraseToAnyPublisher()
    }
}
