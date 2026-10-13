//
//  UploadDataResponse.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 28/7/25.
//

import Foundation

public struct UploadDataResponse: Decodable {
    public let path: String
    public let originalName: String
}
