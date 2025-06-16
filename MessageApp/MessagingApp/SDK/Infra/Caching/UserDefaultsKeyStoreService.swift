//
//  UserDefaultsKeyStoreService.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

extension String {
    static let privateKey = "PRIVATE_KEY"
    static let secureKey = "SECURE_KEY"
    static let refreshToken = "REFRESH_TOKEN"
    static let userName = "USER_NAME"
}

final class UserDefaultsKeyStoreService: KeyStoreModule {
    private let userDefaults = UserDefaults.standard
    
    func store<T>(key: String, value: T) {
        userDefaults.set(value, forKey: key)
    }
    
    func retrieve<T>(key: String) -> T? {
        return userDefaults.value(forKey: key) as? T
    }
    
    func delete(key: String) {
        return userDefaults.removeObject(forKey: key)
    }
    
    func deleteAllKeys() {
        userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
    }
}
