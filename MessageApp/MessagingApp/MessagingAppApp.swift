//
//  MessagingAppApp.swift
//  MessagingApp
//
//  Created by Sam on 20/5/25.
//

import SwiftUI

@main
struct MessagingAppApp: App {
    
    init() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            // If `granted` is `true`, you're good to go!
            if granted {
                debugPrint("User granted notification permission ✅")
            } else {
                debugPrint("User denied notification permission ❌")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
