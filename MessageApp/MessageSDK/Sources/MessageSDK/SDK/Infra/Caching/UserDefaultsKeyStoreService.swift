//
//  UserDefaultsKeyStoreService.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

public extension String {
    static let privateKey = "PRIVATE_KEY"
    static let secureKey = "SECURE_KEY"
    static let refreshToken = "REFRESH_TOKEN"
    static let userName = "USER_NAME"
    static let userId = "USER_ID"
}

public final class UserDefaultsKeyStoreService: KeyStoreModule {
    private let userDefaults = UserDefaults.standard
    
    public init() {}
    
    public func store<T>(key: String, value: T) {
        userDefaults.set(value, forKey: key)
    }
    
    public func retrieve<T>(key: String) -> T? {
        return userDefaults.value(forKey: key) as? T
    }
    
    public func delete(key: String) {
        return userDefaults.removeObject(forKey: key)
    }
    
    public func deleteAllKeys() {
        userDefaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
    }
}
