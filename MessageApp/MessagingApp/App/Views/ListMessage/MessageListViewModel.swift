//
//  MessageListViewModel.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 31/7/25.
//

import SwiftUI

@Observable
class MessageListViewModel {
    private let cache = NSCache<NSString, UIImage>()
    var messages: [MessageGroup]
    
    init(messages: [MessageGroup]) {
        self.messages = messages
    }
        
    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    func insertImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
