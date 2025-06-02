//
//  RestoreKeyResponse.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 2/6/25.
//


struct RestoreKeyResponse: Codable {
    let salt: String
    let encryptedKey: String
}
