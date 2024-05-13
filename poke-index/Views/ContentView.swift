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

  /// The fetch request used to obtain Pokémon from the database.
  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Pokemon.number, ascending: true),
                                  NSSortDescriptor(keyPath: \Pokemon.name, ascending: true)],
                animation: .default)
  private var allPokemon: FetchedResults<Pokemon>
  
  /// The persistence controller, which controls access to the Core Data
  /// store. Uses the shared one by default, but previews set it to the
  /// preview controller
  var persistence: PersistenceController = .shared

  /// Whether the Pokémon are automatically downloaded. We don't want
  /// to do this if we're previewing
  var shouldAutomaticallyDownloadAllPokemon = true
  
  /// The search text used to filter the Pokémon we're displaying. This can either be part
  /// of  a name (case-insensitive), or an exact number.
  @State private var searchText = ""
  
  /// The visibility of the columns of our split view. By default, we show all (well, both.
  @State private var columnVisibility = NavigationSplitViewVisibility.all

  /// The body of this view.
  var body: some View {
    NavigationSplitView(columnVisibility: $columnVisibility) {
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
      .navigationDestination(for: Pokemon.self) {
        pokemon in PokemonView(pokemon: pokemon)
      }
      .toolbar {
        ToolbarItem {
          Button(action: refreshAllPokemon) {
            Image(systemName: "arrow.clockwise")
          }
          .accessibilityElement()
          .accessibilityLabel(Text("Refresh all Pokémon."))
        }
      }
    } detail: {
      Text("No Pokémon")
        .font(.largeTitle)
        .foregroundColor(.secondary)
    }
    .navigationSplitViewStyle(.balanced)
    .searchable(text: $searchText, placement: .automatic, prompt: "Name or Number")
    .onChange(of: searchText) {
      _ in updatePredicate()
    }
    .onAppear {
      initializeAllPokemon()
      updatePredicate()
    }
  }
  
  /// Updates the predicate used to control which Pokémon we display. If the search text
  /// is non-empty, we  apply that; otherwise, we show all the Pokémon.
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
  
  /// Downloads any remaining Pokémon that we haven't already done so. This is _not_
  /// done if we're previewing.
  private func initializeAllPokemon() {
    if shouldAutomaticallyDownloadAllPokemon {
      persistence.downloadAllPokemon()
    }
  }
  
  /// Deletes all Pokémon in the store and starts downloading them again.
  private func refreshAllPokemon() {
    persistence.deleteAllPokemon()
    persistence.downloadAllPokemon()
  }
}

// MARK: - previews

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    let persistence = PersistenceController.preview
    
    ContentView(persistence: persistence, shouldAutomaticallyDownloadAllPokemon: false)
      .environment(\.managedObjectContext, persistence.container.viewContext)
  }
}
