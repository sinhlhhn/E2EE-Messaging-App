//
//  MultipartRequest.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 15/7/25.
//

import Foundation

public struct MultipartRequest {
    
    public let boundary: String
    
    private let separator: String = "\r\n"
    private var data: Data

    public init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
        self.data = .init()
    }
    
    private mutating func appendBoundarySeparator() {
        data.append("--\(boundary)\(separator)")
    }
    
    private mutating func appendSeparator() {
        data.append(separator)
    }

    private func disposition(_ key: String) -> String {
        "Content-Disposition: form-data; name=\"\(key)\""
    }

    public mutating func add(
        key: String,
        value: String
    ) {
        appendBoundarySeparator()
        data.append(disposition(key) + separator)
        appendSeparator()
        data.append(value + separator)
    }

    public mutating func add(
        key: String,
        fileName: String,
        fileMimeType: String,
        fileData: Data
    ) {
        appendBoundarySeparator()
        data.append(disposition(key) + "; filename=\"\(fileName)\"" + separator)
        data.append("Content-Type: \(fileMimeType)" + separator + separator)
        data.append(fileData)
        appendSeparator()
    }

    public var httpContentTypeHeadeValue: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    public var httpBody: Data {
        var bodyData = data
        bodyData.append("--\(boundary)--")
        return bodyData
    }
}

public struct MultipartImage {
    let data: Data
    let fieldName: String
    let fileName: String
    let mimeType: String
    
    public init(data: Data, fieldName: String, fileName: String, mimeType: String) {
        self.data = data
        self.fieldName = fieldName
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

public struct FormField {
    let name: String
    let value: String
    
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

// MARK: - Data helper
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
