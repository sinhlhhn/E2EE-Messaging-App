//
//  ListProgressView.swift
//  MessagingApp
//
//  Created by SinhLH.AVI on 17/9/25.
//

import SwiftUI

struct ListProgressView: View {
    @State private var progressViewID = UUID()
    
    var body: some View {
        ProgressView()
            .id(progressViewID)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDisappear {
                progressViewID = UUID()
            }
    }
}
