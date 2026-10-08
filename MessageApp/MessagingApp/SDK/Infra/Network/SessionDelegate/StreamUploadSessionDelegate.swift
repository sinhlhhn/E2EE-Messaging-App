//
//  StreamUploadSessionDelegate.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 30/6/25.
//

import Foundation
@preconcurrency import Combine

/// `InputStream`/`OutputStream` aren't marked `Sendable` by Foundation, even
/// though bound streams (`Stream.getBoundStreams`) are explicitly designed for
/// cross-thread use: one end is written on one thread/run loop while the other
/// is read on a different one (e.g. URLSession reading `InputStream` on its own
/// internal queue). The OS-level implementation already synchronizes this, so
/// this retroactive `@unchecked Sendable` reflects an existing safety
/// guarantee rather than silencing a genuine, unmitigated race.
extension InputStream: @unchecked @retroactive Sendable {}
extension OutputStream: @unchecked @retroactive Sendable {}

/// Responsibilities:
///     - Handle streaming upload data when triggering `uploadTask(withStreamedRequest:)`.
///     - Observe the data upload progress.
@MainActor
final class StreamUploadSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    private let pinning: PinningDelegate
    
    struct Streams {
        let input: InputStream
        let output: OutputStream
    }
    
    private var writingTask: Task<Void, Never>?
    private var canWrite = true
    private var boundStreams: [Int: Streams] = [:]
    
    nonisolated private let progress = PassthroughSubject<Double, Error>()
    var progressPublisher: AnyPublisher<Double, Error> {
        progress.eraseToAnyPublisher()
    }
    
    init(pinning: PinningDelegate) {
        self.pinning = pinning
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        await pinning.handleChallenge(didReceive: challenge)
    }
    
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let value = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        progress.send(value)
        if value == 1 {
            progress.send(completion: .finished)
        }
    }
}

extension StreamUploadSessionDelegate: StreamDelegate {
    nonisolated func createStream(for id: Int) {
        
    }
    
    private func createStream() -> Streams {
        var inputOrNil: InputStream? = nil
        var outputOrNil: OutputStream? = nil
        Stream.getBoundStreams(withBufferSize: 1024,
                               inputStream: &inputOrNil,
                               outputStream: &outputOrNil)
        guard let input = inputOrNil, let output = outputOrNil else {
            fatalError("On return of `getBoundStreams`, both `inputStream` and `outputStream` will contain non-nil streams.")
        }
        // configure and open output stream
        output.delegate = self
        output.schedule(in: .main, forMode: .default)
        output.open()
    
        return Streams(input: input, output: output)
    }
    
//    nonisolated func urlSession(_ session: URLSession, needNewBodyStreamForTask task: URLSessionTask) async -> InputStream? {
//        await createStreamAndStartSending(taskIdentifier: task.taskIdentifier)
//    }
//
//    @MainActor
//    private func createStreamAndStartSending(taskIdentifier: Int) -> InputStream? {
//        print("Delegate: needNewBodyStream")
//        let boundStream = createStream()
//        print("Create streams with \(taskIdentifier)")
//        startSendingData(boundStream)
//        print("Delegate: start sending data")
//        return boundStream.input
//    }
    
    // `needNewBodyStream` is called by URLSession on its own background delegate
    // queue. We hop onto `@MainActor` to create the stream (via `await`), then
    // call `completionHandler` from this `nonisolated` (non-actor-isolated)
    // `Task` body — not from inside a `@MainActor`-labeled closure — so the
    // compiler can prove `completionHandler` isn't captured across isolation
    // domains. Marking the parameter `sending` tells the compiler that
    // ownership of `completionHandler` fully transfers into the `Task`
    // closure, so it's no longer considered "accessible" from the enclosing
    // (nonisolated) function scope after the `Task` is spawned.
    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask,
                    needNewBodyStream completionHandler: sending @escaping (InputStream?) -> Void) {
        Task {
            print("Delegate: needNewBodyStream")
            let boundStream = await createStream()
            print("Create streams with \(task.taskIdentifier)")
            completionHandler(boundStream.input)
            await startSendingData(boundStream)
            print("Delegate: start sending data")
        }
    }
    
    /// Replaces the old `Timer.scheduledTimer(withTimeInterval:repeats:block:)`
    /// polling loop. That API's `block` parameter is declared `NS_SWIFT_SENDABLE`
    /// in Foundation, so it's imported into Swift as `@Sendable` — capturing the
    /// non-`Sendable` `boundStream` in it is illegal under strict concurrency. A
    /// cancellable `@MainActor`-confined `Task` loop needs no `@Sendable` closure
    /// at all, since the loop body runs on the same actor as `self`.
    private func startSendingData(_ boundStream: Streams) {
        writingTask?.cancel()
        writingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                
                if canWrite {
                    let message = "*** \(Date())\r\n"
                    guard let messageData = message.data(using: .utf8) else { continue }
                    let messageCount = messageData.count
                    let bytesWritten: Int = messageData.withUnsafeBytes({ buffer in
                        canWrite = false
                        print("streaming: \(message)")
                        if let pointer = buffer.baseAddress {
                            return boundStream.output.write(pointer, maxLength: messageCount)
                        } else {
                            debugPrint("Error: could not get buffer pointer")
                            return -1
                        }
                    })
                    if bytesWritten < messageCount {
                        // Handle writing less data than expected.
                        print("Delegate: Write less data than expected. \(bytesWritten) - \(messageCount)")
                    }
                }
            }
        }
    }
    
    // `stream(_:handle:)` already fires on the main run loop (the output stream
    // was scheduled with `.main` above), but the protocol requirement itself is
    // `nonisolated`, so we still hop explicitly to satisfy the compiler.
//    nonisolated func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
//        Task { @MainActor in
//            if eventCode.contains(.hasSpaceAvailable) {
//                print("Delegate: Has space available")
//                canWrite = true
//            }
//            if eventCode.contains(.errorOccurred) {
//                // Close the streams and alert the user that the upload failed.
//                print("Delegate: Error occurred")
//                closeStream(aStream)
//            }
//            
//            if eventCode.contains(.endEncountered) {
//                // Close the streams and alert the user that the upload failed.
//                print("Delegate: Encountered")
//                closeStream(aStream)
//            }
//            
//            print("Delegate: Stream event: \(eventCode)")
//        }
//    }
    
    private func closeStream(_ stream: Stream) {
        stream.close()
        writingTask?.cancel()
        writingTask = nil
    }
}
