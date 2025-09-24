//
//  ContentView.swift
//  MessagingApp
//
//  Created by Sam on 20/5/25.
//

import SwiftUI

struct DocumentData: Identifiable {
    var id = UUID()
    let url: URL
}

struct ContentView: View {
    
    @State private var flow = Flow()
    @State private var documentURL: DocumentData?
    private let factory = Factory()
    
    var body: some View {
        NavigationStack(path: $flow.path) {
            factory.createRootView(didLogin: {
                flow.start(type: .root(ConversationDestination.logIn))
            }, didGoToConversation: { sender in
                flow.start(type: .root(ConversationDestination.conversation(sender: sender)))
            })
            .sheet(item: $documentURL, content: { data in
                PreviewController(url: data.url)
            })
            .navigationDestination(for: ConversationDestination.self) { destination in
                switch destination {
                case .logIn:
                    factory.createLogIn { sender in
                        flow.start(type: .pushTo(ConversationDestination.conversation(sender: sender)))
                    }
                case.conversation(let sender):
                    factory.createConversation(sender: sender, didTapItem: { sender, receiver in
                        flow.start(type: .pushTo(ConversationDestination.chat(sender: sender, receiver: receiver)))
                    }, didTapLogOut: {
                        flow.start(type: .root(ConversationDestination.logIn))
                    })
//                    factory.createProfile()
                case .chat(let sender, let receiver):
                    factory.createChat(sender: sender, receiver: receiver, didTapBack: {
                        flow.start(type: .popBack)
                    }, didDisplayDocument: { url in
                        documentURL = DocumentData(url: url)
                    })
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
