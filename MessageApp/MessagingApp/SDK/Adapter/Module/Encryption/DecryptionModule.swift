//
//  DecryptionModule.swift
//  MessagingApp
//
//  Created by Sam on 25/5/25.
//

import Foundation

public protocol DecryptionModule {
    func decryptMessage(with key: Data, combined: Data) throws -> Data
}
