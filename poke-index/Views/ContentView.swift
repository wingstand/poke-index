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
      initializeDataService()
      updatePredicate()
    }
    .navigationTitle("Select Contact")
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
  
  private func initializeDataService() {
    let dataService = DataService.shared
    
    dataService.context = viewContext
  
    if allPokemon.isEmpty {
      dataService.loadPokemon()
    }
  }
  
  private func refreshAllPokemon() {
    let dataService = DataService.shared
    
    dataService.deleteAllPokemon()
    dataService.loadPokemon()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
  }
}
