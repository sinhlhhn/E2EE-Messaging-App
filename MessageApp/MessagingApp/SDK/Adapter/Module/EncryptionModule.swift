//
//  EncryptionModule.swift
//  MessagingApp
//
//  Created by Sam on 25/5/25.
//

import Foundation

public protocol EncryptionModule {
    func encryptMessage(with key: Data, plainText: Data) throws -> Data?
}
