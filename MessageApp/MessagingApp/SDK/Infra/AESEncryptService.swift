//
//  AESEncryptService.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation
import CryptoKit

public final class AESEncryptService: EncryptionModule {
    public func encryptMessage(with key: Data, plainText: Data) throws -> Data? {
        do {
            let sealedData = try AES.GCM.seal(
                plainText,
                using: SymmetricKey(data: key)
            )
            return sealedData.combined
        } catch {
            debugPrint("❌ encryptMessage failed \(error.localizedDescription)")
            throw error
        }
    }
}
