//
//  poke_indexApp.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import SwiftUI

@main
struct poke_indexApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
