//
//  ContentView.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
  @Environment(\.managedObjectContext) private var viewContext

  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Pokemon.number, ascending: true),
                                  NSSortDescriptor(keyPath: \Pokemon.name, ascending: true)],
                animation: .default)
  private var allPokemon: FetchedResults<Pokemon>
  
  /// The persistence controller, which controls access to the Core Data
  /// store. Uses the shared one by default, but previews set it to the
  /// preview controller
  var persistence: PersistenceController = .shared

  @State private var searchText = ""
  
  var body: some View {
    NavigationStack {
      List {
        ForEach(allPokemon) {
          pokemon in
          
          NavigationLink {
            PokemonView(pokemon: pokemon)
          } label: {
            PokemonRowView(pokemon: pokemon)
          }
        }
      }
      .navigationTitle("Pokémon")
      .toolbar {
        ToolbarItem {
          Button(action: refreshAllPokemon) {
            Image(systemName: "arrow.clockwise")
          }
        }
      }
    }
    .searchable(text: $searchText, placement: .automatic, prompt: "Name or Number")
    .onChange(of: searchText) {
      _ in updatePredicate()
    }
    .onAppear {
      initializeAllPokemon()
      updatePredicate()
    }
  }
  
  private func updatePredicate() {
    if searchText.isEmpty {
      allPokemon.nsPredicate = NSPredicate(value: true)
    }
    else {
      if let number = Int16(searchText) {
        allPokemon.nsPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
          NSPredicate(format: "name CONTAINS[c] %@", searchText),
          NSPredicate(format: "number == %i", number)
        ])
      }
      else {
        allPokemon.nsPredicate = NSPredicate(format: "name CONTAINS[c] %@", searchText)
      }
    }
  }
  
  private func initializeAllPokemon() {
    if allPokemon.isEmpty {
      persistence.downloadAllPokemon()
    }
  }
  
  private func refreshAllPokemon() {
    persistence.deleteAllPokemon()
    persistence.downloadAllPokemon()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    let persistence = PersistenceController.preview
    
    ContentView(persistence: persistence)
      .environment(\.managedObjectContext, persistence.container.viewContext)
  }
}
