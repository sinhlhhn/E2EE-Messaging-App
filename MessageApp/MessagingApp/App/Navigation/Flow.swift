//
//  Flow.swift
//  ReplaceNotificationCenterWithAdapter
//

import SwiftUI



enum ConversationDestination: Hashable {
    case logIn
    case conversation(sender: String)
    case chat(sender: String, receiver: String)
}

class Flow: ObservableObject {
    @Published var path: NavigationPath = .init()
    @Published var type: NavigationType = .root
    
    enum NavigationType {
        case pushTo(any Hashable)
        case popBack
        case popToRoot
        case root
    }
    
    func start(type: NavigationType) {
        DispatchQueue.main.async {
            switch type {
            case .pushTo(let destination):
                self.path.append(destination)
            case .popBack:
                self.path.removeLast()
            case .popToRoot, .root:
                self.path.removeLast(self.path.count)
            }
        }
    }
}
