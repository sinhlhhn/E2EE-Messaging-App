//
//  Flow.swift
//  ReplaceNotificationCenterWithAdapter
//

import SwiftUI



enum ConversationDestination: Hashable {
    case logIn
    case conversation(sender: User)
    case chat(sender: User, receiver: String)
}

@Observable
class Flow {
    var path: NavigationPath = .init()
    
    enum NavigationType {
        case pushTo(any Hashable)
        case popBack
        case popToRoot
        case root(any Hashable)
    }
    
    func start(type: NavigationType) {
        DispatchQueue.main.async {
            switch type {
            case .pushTo(let destination):
                self.path.append(destination)
            case .popBack:
                self.path.removeLast()
            case .popToRoot:
                self.path.removeLast(self.path.count)
            case .root(let destination):
                self.path = NavigationPath()
                self.path.append(destination)
            }
        }
    }
}
