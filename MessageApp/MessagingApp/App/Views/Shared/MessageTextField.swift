//
//  MessageTextField.swift
//  MessagingApp
//
//  Created by Sam on 20/5/25.
//

import SwiftUI

struct MessageTextField: View {
    @State var text: String = ""
    private let didTapSend: (String) -> Void
    
    fileprivate init(text: String, didTapSend: @escaping (String) -> Void) {
        self.text = text
        self.didTapSend = didTapSend
    }
    
    init(didTapSend: @escaping (String) -> Void) {
        self.didTapSend = didTapSend
    }
    
    var body: some View {
        HStack(alignment: .bottomAligned) {
            textFieldView
            sendButton
        }
    }
    
    private var textFieldView: some View {
        TextField(text: $text, axis: .vertical) {
            Text("Write something...")
        }
        .alignmentGuide(.bottomAligned, computeValue: { d in
            d[.bottom]
        })
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .stroke(.gray)
        )
    }
    
    private var sendButton: some View {
        Button {
            didTapSend(text)
            text = ""
        } label: {
            Image(systemName: "paperplane")
                .font(.title2)
                .alignmentGuide(.bottomAligned, computeValue: { d in
                    d[.bottom]
                })
                .padding(.trailing)
        }

        
    }
}

#Preview {
    MessageTextField(text: "", didTapSend: { _ in })
        .padding()
    MessageTextField(text: "Short text", didTapSend: { _ in })
        .padding()
    MessageTextField(text: "Very long long long long long long long long text", didTapSend: { _ in })
        .padding()
}
