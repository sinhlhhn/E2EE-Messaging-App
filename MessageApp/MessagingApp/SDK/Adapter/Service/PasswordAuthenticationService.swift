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
    
    init(network: NetworkModule, secureKey: any SecureKeyModule<P256ExchangeKey, P256KeyData>, keyStore: KeyStoreModule) {
        self.network = network
        self.secureKey = secureKey
        self.keyStore = keyStore
    }
    
    func register(data: PasswordAuthentication) -> AnyPublisher<Void, any Error> {
        return network.registerUser(username: data.email)
            .flatMap { _ in
                let exchangeKey = self.secureKey.generateExchangeKey()
                self.keyStore.store(key: data.email, value: exchangeKey.privateKey)
                return self.network.sendPublicKey(user: data.email, publicKey:  exchangeKey.publicKey)
                    .map { _ in exchangeKey.privateKey }
            }
            .tryMap { key in
                try self.encryptPrivateKeyForBackup(privateKeyData: key, password: data.password)
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
            .tryMap { response in
                try self.restoreKey(response: response, data: data)
            }
            .map { _ in () }
            .first()
            .eraseToAnyPublisher()
    }
    
    private func restoreKey(response: RestoreKeyResponse, data: PasswordAuthentication) throws {
        guard let salt = Data(base64Encoded: response.salt),
        let encryptedKey = Data(base64Encoded: response.encryptedKey) else {
            throw NSError(domain: "Cannot decode salt", code: 0, userInfo: nil)
        }
        let symmetricKey = deriveSymmetricKey(from: data.password, salt: salt)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedKey)
        let decrypted = try AES.GCM.open(sealedBox, using: symmetricKey)
        let key = try P256.KeyAgreement.PrivateKey(rawRepresentation: decrypted)
        
        keyStore.store(key: data.email, value: key.rawRepresentation)
    }
    
    func encryptPrivateKeyForBackup(privateKeyData: Data, password: String) throws -> (encryptedKey: Data, salt: Data) {
        let salt = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let symmetricKey = deriveSymmetricKey(from: password, salt: salt)
        
        let sealedBox = try AES.GCM.seal(privateKeyData, using: symmetricKey)
        guard let encrypted = sealedBox.combined else {
            throw NSError(domain: "Cannot encrypt private key", code: 0, userInfo: nil)
        }
        return (encryptedKey: encrypted, salt: salt)
    }
    
    func deriveSymmetricKey(from password: String, salt: Data) -> SymmetricKey {
        let passwordData = password.data(using: .utf8)!
        let key = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: salt,
            info: Data(),
            outputByteCount: 32
        )
        return key
    }
}
