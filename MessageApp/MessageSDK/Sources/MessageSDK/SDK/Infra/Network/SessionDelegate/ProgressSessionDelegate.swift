//
//  ProgressSessionDelegate.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 26/6/25.
//

import Foundation
@preconcurrency import Combine


// This class is marked as unchecked Sendable. So we are responsible to prevent the data race by ourselves.
// Currently, there are only one mutable property `progressDictionary` that is prevented by the `progressQueue`
public nonisolated
final class ProgressSessionDelegate : NSObject, URLSessionDelegate, URLSessionTaskDelegate, ProgressSubscriber, URLSessionDownloadDelegate, @unchecked Sendable {
    private let pinning: PinningDelegate
    
    private let progressQueue = DispatchQueue(label: "com.example.URLSession.progressQueue")
    private var progressDictionary: [URL: PassthroughSubject<Double, Never>] = [:]
    
    public init(pinning: PinningDelegate) {
        self.pinning = pinning
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        pinning.handleChallenge(session, didReceive: challenge, completionHandler: completionHandler)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let value = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        print("didSendBodyData \(value)")
        guard let url = task.originalRequest?.url  else {
            return
        }
        let subject = getProgressSubject(for: url)
        subject.send(value)
        
        if value == 1 {
            subject.send(completion: .finished)
        }
    }
    
    public func subscribeProgress(url: URL) -> AnyPublisher<Double, Never> {
        updateProgressSubject(PassthroughSubject<Double, Never>(), with: url)
        
        return getProgressSubject(for: url).eraseToAnyPublisher()
    }
    
    private func getProgressSubject(for url: URL) -> PassthroughSubject<Double, Never> {
        progressQueue.sync {
            self.progressDictionary[url] ?? .init()
        }
    }
    
    private func updateProgressSubject(_ subject: PassthroughSubject<Double, Never>, with url: URL) {
        progressQueue.async {
            self.progressDictionary[url] = subject
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let value = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        print("didWriteData \(value)")
        guard let url = downloadTask.originalRequest?.url  else {
            return
        }
        let subject = getProgressSubject(for: url)
        subject.send(value)
        
        if value == 1 {
            subject.send(completion: .finished)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
    }
}
