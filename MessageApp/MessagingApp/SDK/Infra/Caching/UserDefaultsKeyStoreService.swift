//
//  UserDefaultsKeyStoreService.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

extension String {
    static let secureKey = "SECURE_KEY"
    static let loggedInUserKey = "LOGGED_IN_USER"
    static let refreshToken = "REFRESH_TOKEN"
}

final class UserDefaultsKeyStoreService: KeyStoreModule {
    private let userDefaults = UserDefaults.standard
    
    func store<T>(key: String, value: T) {
        userDefaults.set(value, forKey: key)
    }
    
    func retrieve<T>(key: String) -> T? {
        return userDefaults.value(forKey: key) as? T
    }
}
