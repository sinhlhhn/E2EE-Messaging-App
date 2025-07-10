//
//  URLSessionDownloadTaskHTTPClient.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 26/6/25.
//

import Foundation
import Combine

final class URLSessionDownloadTaskHTTPClient: DownloadTaskHTTPClient, TaskCancelHTTPClient {
    private let session: URLSession
    
    private let queue: DispatchQueue = .init(label: "com.slh.URLSessionDownloadTaskHTTPClient")
    private var taskDictionary: [URL?: URLSessionDownloadTask] = [:]
    private var taskSubjectDictionary: [URL?: PassthroughSubject<DownloadResponse, Error>] = [:]
    private var resumeDataDictionary: [URL?: Data] = [:]
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func download(request: URLRequest) -> AnyPublisher<DownloadResponse, any Error> {
        debugPrint("☁️ CURL: \(request.curlString())")
        let subject: PassthroughSubject<DownloadResponse, Error> = .init()
        
        guard let url = request.url else {
            return Fail(error: NSError(domain: "cannot create url", code: 0)).eraseToAnyPublisher()
        }
        
        // Using a completion handler with a download task prevents `urlSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)` from being called.
        // If we want to track progress while using a completion handler, we must use `task.progress.publisher`.
        let task = session.downloadTask(with: request)
        
        updateTask(task, url: url)
        updateTaskSubject(subject, url: url)
        
        task.resume()
        return subject
            .handleEvents(receiveCancel: {
                task.cancel()
            })
            .eraseToAnyPublisher()
    }
    
    func suspend(url: URL) {
        let task = getTask(url: url)
        task?.suspend()
    }
    
    func cancel(url: URL) {
        let task = getTask(url: url)
        task?.cancel { [weak self] data in
            self?.resumeDataDictionary[url] = data
        }
    }
    
    var cancellables: Set<AnyCancellable> = []
    
    func resumeDownload(url: URL) -> AnyPublisher<DownloadResponse, any Error> {
        guard let data = getResumeData(url: url) else {
            debugPrint("Cannot resume task with url \(url): no resume data found.")
            return Empty<DownloadResponse, any Error>().eraseToAnyPublisher()
        }
        guard let subject = getTaskSubject(url: url) else {
            debugPrint("Cannot resume task with url \(url): no task subject found.")
            return Empty<DownloadResponse, any Error>().eraseToAnyPublisher()
        }
        
        debugPrint("Resume task with url \(url)")
        
        let task = session.downloadTask(withResumeData: data) { url, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                subject.send(completion: .failure(InvalidHTTPResponseError()))
                return
            }
            debugPrint("🌪️ Status code: \(httpResponse.statusCode)")
            subject.send(.downloaded(url: url, response: httpResponse))
            subject.send(completion: .finished)
        }
        
        task.progress.publisher(for: \.fractionCompleted)
            .sink { progress in
                subject.send(.downloading(percentage: progress))
            }
            .store(in: &cancellables)
        
        updateTask(task, url: url)
        updateTaskSubject(subject, url: url)
        
        task.resume()
        return subject
            .handleEvents(receiveCancel: {
                task.cancel()
            })
            .eraseToAnyPublisher()
    }
    
    private func updateTask(_ task: URLSessionDownloadTask?, url: URL) {
        queue.async(flags: .barrier) {
            self.taskDictionary[url] = task
        }
    }
    
    private func getTask(url: URL) -> URLSessionDownloadTask? {
        queue.sync {
            self.taskDictionary[url]
        }
    }
    
    private func getResumeData(url: URL) -> Data? {
        queue.sync {
            self.resumeDataDictionary[url]
        }
    }
    
    private func updateTaskSubject(_ subject: PassthroughSubject<DownloadResponse, Error>, url: URL) {
        queue.async(flags: .barrier) {
            self.taskSubjectDictionary[url] = subject
        }
    }
    
    private func getTaskSubject(url: URL) -> PassthroughSubject<DownloadResponse, Error>? {
        queue.sync {
            self.taskSubjectDictionary[url]
        }
    }
}
