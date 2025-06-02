//
//  RestoreKeyMapper.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 2/6/25.
//

import Foundation

extension RestoreKeyResponse {
    func toRestoreKeyModel() -> RestoreKeyModel {
        return RestoreKeyModel(salt: salt, encryptedKey: encryptedKey)
    }
}
