//
//  AESDecryption.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import CryptoKit

class AESDecryption: DecryptionModule {
    func decryptMessage(with key: Data, combined: Data) throws -> Data {
        do {
            let sealBox = try AES.GCM.SealedBox(combined: combined)
            let result = try AES.GCM.open(sealBox, using: SymmetricKey(data: key))
            return result
        } catch {
            debugPrint("❌ decryptMessage failed key: \(key.asHexString) - data: \(combined.asHexString)")
            throw error
        }
    }

}
