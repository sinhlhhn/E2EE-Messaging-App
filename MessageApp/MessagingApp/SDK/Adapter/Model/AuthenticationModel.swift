//
//  AuthenticationModel.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 3/6/25.
//

struct AuthenticationModel {
    let accessToken: String
    let refreshToken: String
    let user: User
}

struct TokenModel {
    let accessToken: String
    let refreshToken: String
}
