//
//  User.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

public struct User: Identifiable, Hashable, Codable {
    public let id: Int
    public let username: String
    
    public init(id: Int, username: String) {
        self.id = id
        self.username = username
    }
}
