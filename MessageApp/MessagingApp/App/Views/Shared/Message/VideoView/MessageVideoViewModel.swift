//
//  MessageVideoViewModel.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 17/7/25.
//

import SwiftUI

@Observable
class MessageVideoViewModel {
    enum ViewState {
        case loading
        case completed(URL)
    }
    
    private(set) var viewState: ViewState = .loading
    
    private let source: String
    private let fileExtension: String?
    
    init(source: String, fileExtension: String? = nil) {
        self.source = source
        self.fileExtension = fileExtension
    }
    
    func getImage() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            guard let url = Bundle.main.url(
                forResource: source,
                withExtension: fileExtension
            ) else {
                fetchImageFromCloud()
                return
            }
            
            viewState = .completed(url)
        }
        
    }
    
    private func fetchImageFromCloud() {
        let url = URL(fileURLWithPath: source)
        viewState = .completed(url)
    }
}
