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
        
    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    func insertImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}
