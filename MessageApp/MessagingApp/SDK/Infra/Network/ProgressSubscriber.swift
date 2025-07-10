//
//  ProgressSubscriber.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 10/7/25.
//

import Foundation
import Combine

protocol ProgressSubscriber {
    func subscribeProgress(url: URL) -> AnyPublisher<Double, Never>
}
