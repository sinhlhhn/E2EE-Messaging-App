//
//  DefaultSessionDelegate.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 26/6/25.
//

import Foundation
import Combine


final class DefaultSessionDelegate : NSObject, URLSessionDelegate {
    private let pinning: PinningDelegate
    
    private var progress = PassthroughSubject<Double, Error>()
    var progressPublisher: AnyPublisher<Double, Error> {
        progress.eraseToAnyPublisher()
    }
    
    init(pinning: PinningDelegate) {
        self.pinning = pinning
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        pinning.handleChallenge(session, didReceive: challenge, completionHandler: completionHandler)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let value = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        progress.send(value)
        if value == 1 {
            progress.send(completion: .finished)
        }
        print("sinhlh: \(value)")
        print("sinhlh: progress \(task.progress.fractionCompleted)")
        print("sinhlh: totalBytesSent \(totalBytesSent)")
        print("sinhlh: totalBytesExpectedToSend \(totalBytesExpectedToSend)")
    }
}
