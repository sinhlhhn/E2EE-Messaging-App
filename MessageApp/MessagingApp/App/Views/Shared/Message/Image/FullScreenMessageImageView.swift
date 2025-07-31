//
//  FullScreenMessageImageView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 31/7/25.
//

import SwiftUI

struct FullScreenMessageImageView: View {
    private let image: UIImage
    private let geoEffectId: String
    private let nsAnimation: Namespace.ID
    
    init(image: UIImage, geoEffectId: String, nsAnimation: Namespace.ID) {
        self.image = image
        self.geoEffectId = geoEffectId
        self.nsAnimation = nsAnimation
    }
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .matchedGeometryEffect(id: geoEffectId, in: nsAnimation)
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.7))
    }
}
