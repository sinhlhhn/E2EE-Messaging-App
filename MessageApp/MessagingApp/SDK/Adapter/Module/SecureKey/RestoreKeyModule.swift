//
//  RestoreKeyModule.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 2/6/25.
//

import Foundation

protocol RestoreKeyModule {
    func encryptPrivateKeyForBackup(privateKeyData: Data, password: String) throws -> (encryptedKey: Data, salt: Data)
    func restoreKey(response: RestoreKeyModel, data: PasswordAuthentication) throws -> Data
}
