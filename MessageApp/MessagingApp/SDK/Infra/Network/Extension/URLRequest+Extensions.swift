//
//  File.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 13/6/25.
//

import Foundation

extension URLRequest {
    
    /// Returns a curl command that can be used to invoke this request at the command line.
    ///
    /// Taken from http://gentlebytes.com/blog/2018/02/28/request-debugging/
    ///
    /// Logging URL requests in whole may expose sensitive data, or open up the possibility for
    /// getting access to your user data, so make sure to disable this feature for production
    /// builds!
    public func curlString(pretty: Bool = false) -> String {
        #if !DEBUG
        return ""
        #else
        let newLine = pretty ? "\\\n" : ""
        let method = (pretty ? "--request " : "-X ") + "\(self.httpMethod ?? "GET") \(newLine)"
        let url: String = (pretty ? "--url " : "") + "'\(self.url?.absoluteString ?? "")' \(newLine)"
        
        var cURL = "curl "
        var header = ""
        var data: String = ""
        
        if let httpHeaders = self.allHTTPHeaderFields, httpHeaders.keys.count > 0 {
            for (key,value) in httpHeaders {
                header += (pretty ? "--header " : "-H ") + "'\(key): \(value)' \(newLine)"
            }
        }
        
        if let bodyData = self.httpBody, let bodyString = String(data: bodyData, encoding: .utf8),  !bodyString.isEmpty {
            data = "--data '\(bodyString)'"
        }
        
        cURL += method + url + header + data
        
        return cURL
        #endif
    }
    
    public mutating func addApplicationJsonContentAndAcceptHeaders() {
        let value = "application/json"
        addValue(value, forHTTPHeaderField: "Content-Type")
        addValue(value, forHTTPHeaderField: "Accept")
    }
    
    public mutating func setBearerToken(_ token: String) {
        setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

extension URLComponents {
    mutating func addQueryParameters(params: [String: Any]) {
        queryItems = [URLQueryItem]()
        for (key, value) in params {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            queryItems?.append(queryItem)
        }
    }
}

enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

func buildRequest(url: String, parameters: [String: Any]? = nil, method: HttpMethod = .get, headers: [String: String]? = nil, body: [String: Any]? = nil) -> URLRequest {
    var components = URLComponents(string: url)

    // URLComponents(string: url) can't init with url params contains double quote
    if components == nil, let urlQueryAllowed = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
        components = URLComponents(string: urlQueryAllowed)
    }
    
    if let parameters = parameters {
        components?.addQueryParameters(params: parameters)
    }

    guard let urlWithParameters = components?.url else {
        return URLRequest(url: URL(fileURLWithPath: ""))
    }

    var urlRequest = URLRequest(url: urlWithParameters)
    urlRequest.httpMethod = method.rawValue
    urlRequest.addApplicationJsonContentAndAcceptHeaders()

    for (headerField, value) in headers ?? [:] {
        urlRequest.addValue(value, forHTTPHeaderField: headerField)
    }

    if let body = body, let data = try? JSONSerialization.data(withJSONObject: body) {
        urlRequest.httpBody = data
    }

    return urlRequest
}

extension Encodable {
    /// Returns a dictionary version of the Encodable object, if the conversion fails it throws an
    /// Error
    public func asDictionary(
        keyStrategy: JSONEncoder.KeyEncodingStrategy? = nil
    ) throws -> [String: Any] {
        let encoder = JSONEncoder()
        if let keyStrategy = keyStrategy {
            encoder.keyEncodingStrategy = keyStrategy
        }
        guard let json = try JSONSerialization.jsonObject(
            with: try encoder.encode(self),
            options: .allowFragments
        ) as? [String: Any] else {
            throw NSError(domain: "cannot encode", code: -1)
        }

        return json
    }
}
