//
//  HTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Foundation
import Combine

struct InvalidHTTPResponseError: Error {}

protocol HTTPClient<Request, Response> {
    associatedtype Request
    associatedtype Response
    func perform(request: Request) -> AnyPublisher<Response, Error>
}

protocol TaskCancelHTTPClient {
    func cancel(url: URL)
    func suspend(url: URL)
}

enum UploadResponse: Equatable {
    case uploaded(data: Data?, response: HTTPURLResponse)
    case uploading(percentage: Double)
}

protocol UploadTaskHTTPClient {
    func upload(request: (URLRequest, Data)) -> AnyPublisher<UploadResponse, Error>
    func resumeUpload(url: URL) -> AnyPublisher<UploadResponse, any Error>
}

enum DownloadResponse: Equatable {
    case downloaded(url: URL?, response: HTTPURLResponse)
    case downloading(percentage: Double)
}

protocol DownloadTaskHTTPClient {
    func download(request: URLRequest) -> AnyPublisher<DownloadResponse, any Error>
    func resumeDownload(url: URL) -> AnyPublisher<DownloadResponse, any Error>
}

protocol StreamUploadTaskHTTPClient {
    func upload(request: URLRequest) -> AnyPublisher<Void, Error>
}


