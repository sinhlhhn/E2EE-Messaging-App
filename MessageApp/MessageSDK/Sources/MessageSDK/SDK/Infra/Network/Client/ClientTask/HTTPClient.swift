//
//  HTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 5/6/25.
//

import Foundation
import Combine

struct InvalidHTTPResponseError: Error {}

public protocol HTTPClient<Request, Response> {
    associatedtype Request
    associatedtype Response
    func perform(request: Request) -> AnyPublisher<Response, Error>
}

public protocol TaskCancelHTTPClient {
    func cancel(url: URL)
    func suspend(url: URL)
}

public enum UploadResponse: Equatable {
    case uploaded(data: Data?, response: HTTPURLResponse)
    case uploading(percentage: Double)
}

public enum UploadData {
    case data(Data)
    case file(URL)
}

public protocol UploadTaskHTTPClient {
    func upload(request: (URLRequest, UploadData)) -> AnyPublisher<UploadResponse, Error>
    func resumeUpload(url: URL) -> AnyPublisher<UploadResponse, any Error>
}

public enum DownloadResponse: Equatable {
    case downloaded(url: URL?, response: HTTPURLResponse)
    case downloading(percentage: Double)
}

public protocol DownloadTaskHTTPClient {
    func download(request: URLRequest) -> AnyPublisher<DownloadResponse, any Error>
    func resumeDownload(url: URL) -> AnyPublisher<DownloadResponse, any Error>
}

public protocol StreamUploadTaskHTTPClient {
    func upload(request: URLRequest) -> AnyPublisher<Void, Error>
}


