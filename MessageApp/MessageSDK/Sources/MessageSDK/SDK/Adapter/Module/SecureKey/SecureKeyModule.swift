//
//  SecureKeyModule.swift
//  MessagingApp
//
//  Created by Sam on 25/5/25.
//

import Foundation
public protocol SecureKeyModule<ExchangeKey, SecureKey> {
    associatedtype ExchangeKey
    associatedtype SecureKey
    func generateExchangeKey() -> ExchangeKey
    func generateSecureKey(data: SecureKey) throws -> Data
}
