//
//  FullScreenGroupMessageImageView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 9/9/25.
//

import SwiftUI

struct FullScreenGroupMessageImageView: View {
    private let images: [UIImage]
    private let geoEffectId: String
    private let nsAnimation: Namespace.ID
    
    init(images: [UIImage], geoEffectId: String, nsAnimation: Namespace.ID) {
        self.images = images
        self.geoEffectId = geoEffectId
        self.nsAnimation = nsAnimation
    }
    
    var body: some View {
        content
    }
    
    private var content: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(images, id: \.self) { image in
                    createImageViews(image: image)
                        .padding(.horizontal)
                        .containerRelativeFrame(.horizontal) // Makes each item a full "page"
                }
            }
            .scrollTargetLayout() // Designates items as scroll targets
        }
        .matchedGeometryEffect(id: geoEffectId, in: nsAnimation)
        .scrollTargetBehavior(.paging) // Enables paging behavior
        .safeAreaPadding(.horizontal) // Add padding to avoid content hiding under safe areas
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    private func createImageViews(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
            )
    }
}

#Preview {
    FullScreenGroupMessageImageView(images: [
        .init(named: "lion")!,
        .init(named: "elephant")!,
        .init(named: "dog")!,
        .init(named: "horse")!,
    ], geoEffectId: "id", nsAnimation: Namespace().wrappedValue)
}
