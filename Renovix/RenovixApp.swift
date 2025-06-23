//
//  RenovixApp.swift
//  Renovix
//
//  Created by Sandesh Raj on 24/06/25.
//

import SwiftUI

@main
struct RenovixApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
