//
//  CachedMessageImageView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 31/7/25.
//

import SwiftUI

struct CachedMessageImageView: View {
    
    private let geoEffectId: String
    private let nsAnimation: Namespace.ID
    private let image: UIImage
    private let didTapImage: (UIImage) -> Void
    
    init(image: UIImage, geoEffectId: String, nsAnimation: Namespace.ID, didTapImage: @escaping (UIImage) -> Void) {
        self.geoEffectId = geoEffectId
        self.image = image
        self.didTapImage = didTapImage
        self.nsAnimation = nsAnimation
    }
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .matchedGeometryEffect(id: geoEffectId, in: nsAnimation)
            .clipShape(.rect(cornerRadius: 10))
            .highPriorityGesture(
                TapGesture().onEnded {
                    didTapImage(image)
                })
    }
}
