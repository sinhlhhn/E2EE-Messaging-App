//
//  User.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/5/25.
//

import Foundation

struct User: Identifiable, Hashable, Codable {
    let id: Int
    let username: String
}
