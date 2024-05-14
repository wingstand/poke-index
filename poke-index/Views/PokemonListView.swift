//
//  PokemonListView.swift
//  poke-index
//
//  Created by Gary Meehan on 14/05/2024.
//

import SwiftUI
import SwiftData

/// A list of Pokémon that can be filtered on a passed-in search text. We need to do
/// this via a child view because SwiftData doesn't yet support dynamic queries.
struct PokemonListView: View {
  @Environment(\.modelContext) private var modelContext

  /// The query use to fetch the Pokémon
  @Query var allPokemon: [Pokemon]
 
  init(searchText: String) {
    if searchText.isEmpty {
      _allPokemon = Query(sort: [SortDescriptor(\Pokemon.number, order: .forward)])
    }
    else if let searchNumber = Int(searchText) {
      _allPokemon = Query(filter: #Predicate{ $0.number == searchNumber || $0.name.localizedStandardContains(searchText) },
                          sort: [SortDescriptor(\Pokemon.number, order: .forward)])
    }
    else {
      _allPokemon = Query(filter: #Predicate{ $0.name.localizedStandardContains(searchText) },
                          sort: [SortDescriptor(\Pokemon.number, order: .forward)])
      
    }
  }
  
  var body: some View {
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
  }
}

// MARK: - previews

#Preview {
  let controller = DataController.preview
  
  return PokemonListView(searchText: "35")
    .modelContainer(controller.container)
}

