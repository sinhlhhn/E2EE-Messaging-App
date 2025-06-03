//
//  PasswordAuthentication.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//


struct PasswordAuthentication: Encodable {
    let email: String
    let password: String
    
    enum CodingKeys: String, CodingKey {
        case email = "username"
        case password = "password"
    }
}
