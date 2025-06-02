//
//  RemoteRestoreKeyModule.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 2/6/25.
//

import Foundation
import Combine
import CryptoKit

final class RemoteRestoreKeyModule: RestoreKeyModule {
    func encryptPrivateKeyForBackup(privateKeyData: Data, password: String) throws -> (encryptedKey: Data, salt: Data) {
        let salt = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let symmetricKey = deriveSymmetricKey(from: password, salt: salt)
        
        let sealedBox = try AES.GCM.seal(privateKeyData, using: symmetricKey)
        guard let encrypted = sealedBox.combined else {
            throw NSError(domain: "Cannot encrypt private key", code: 0, userInfo: nil)
        }
        return (encryptedKey: encrypted, salt: salt)
    }
    
    func restoreKey(response: RestoreKeyModel, data: PasswordAuthentication) throws -> Data {
        guard let salt = Data(base64Encoded: response.salt),
        let encryptedKey = Data(base64Encoded: response.encryptedKey) else {
            throw NSError(domain: "Cannot decode salt", code: 0, userInfo: nil)
        }
        let symmetricKey = deriveSymmetricKey(from: data.password, salt: salt)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedKey)
        let decrypted = try AES.GCM.open(sealedBox, using: symmetricKey)
        let key = try P256.KeyAgreement.PrivateKey(rawRepresentation: decrypted)
        return key.rawRepresentation
    }
    
    private func deriveSymmetricKey(from password: String, salt: Data) -> SymmetricKey {
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
