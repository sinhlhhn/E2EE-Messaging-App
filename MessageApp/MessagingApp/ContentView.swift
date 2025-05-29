//
//  ContentView.swift
//  MessagingApp
//
//  Created by Sam on 20/5/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var flow = Flow()
    private let factory = Factory()
    
    var body: some View {
        NavigationStack(path: $flow.path) {
            factory.createRootView(didLogin: {
                flow.start(type: .pushTo(ConversationDestination.logIn))
            }, didGoToConversation: { sender in
                flow.start(type: .pushTo(ConversationDestination.conversation(sender: sender)))
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
                        flow.start(type: .popToRoot)
                    })
                case .chat(let sender, let receiver):
                    factory.createChat(sender: sender, receiver: receiver, didTapBack: {
                        flow.start(type: .popBack)
                    })
                }
            }
        }
        
    }
}

#Preview {
    ContentView()
}
