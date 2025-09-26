//
//  MessageListViewModel.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 31/7/25.
//

import SwiftUI

@Observable
class MessageListViewModel {
    
    @ObservationIgnored
    private let cache = NSCache<NSString, UIImage>()
        
    func image(forKey key: UUID) -> UIImage? {
        cache.object(forKey: key.uuidString as NSString)
    }
    
    func insertImage(_ image: UIImage, forKey key: UUID) {
        debugPrint("[Cache] Insert image for key: \(key)")
        cache.setObject(image, forKey: key.uuidString as NSString)
    }
}
