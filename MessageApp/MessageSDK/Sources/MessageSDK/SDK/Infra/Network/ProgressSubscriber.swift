//
//  ProgressSubscriber.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 10/7/25.
//

import Foundation
import Combine

public protocol ProgressSubscriber {
    func subscribeProgress(url: URL) -> AnyPublisher<Double, Never>
}
