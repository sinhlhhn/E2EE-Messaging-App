//
//  KeyStoreService.swift
//  MessagingApp
//
//  Created by Sam on 25/5/25.
//

import Foundation

public protocol KeyStoreModule {
    func store<T>(key: String, value: T)
    func retrieve<T>(key: String) -> T?
}
