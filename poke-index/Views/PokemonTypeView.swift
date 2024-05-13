//
//  PokemonTypeView.swift
//  poke-index
//
//  Created by Gary Meehan on 12/05/2024.
//

import SwiftUI

/// A view for displaying a type of a Pokémon
struct PokemonTypeView: View {
  /// The Pokémon whose type to display.
  @ObservedObject var pokemon: Pokemon

  /// The slot of the type to display.
  let slot: Int
  
  /// The body for this view.
  var body: some View {
    if let type = pokemon.type(forSlot: slot) {
      Group {
        Text(type.description.uppercased())
          .font(.footnote)
          .foregroundColor(.white)
          .padding(.vertical, 2)
          .padding(.horizontal, 6)
      }
      .background(type.color)
      .cornerRadius(4)
      .padding(.top, 2)
    }
    else {
      EmptyView()
    }
  }
}

// MARK: - previews

struct PokemonTypeView_Previews: PreviewProvider {
  static var previews: some View {
    let persistence = PersistenceController.preview
    let pokemon = persistence.pokemon(forName: "clefairy")!
    
    PokemonTypeView(pokemon: pokemon, slot: 1)
      .environment(\.managedObjectContext, persistence.container.viewContext)
  }
}
