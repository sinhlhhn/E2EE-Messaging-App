//
//  PasswordAuthentication.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//


public struct PasswordAuthentication: Encodable {
    let email: String
    let password: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
    
    enum CodingKeys: String, CodingKey {
        case email = "username"
        case password = "password"
    }
}
