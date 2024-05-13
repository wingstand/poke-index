//
//  TotalStatisticView.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import SwiftUI

/// A view for displaying the total statistics for a Pokémon.
struct TotalStatisticView: View {
  /// The Pokémon for which to display the statisic.
  @ObservedObject var pokemon: Pokemon
  
  /// The body for this view.
  var body: some View {
    let value = pokemon.totalStatistic

    HStack {
      Text("Total")
        .font(.headline)
        .foregroundColor(.primary)
      
      Spacer()
      
      Text(value.description)
        .font(.body)
        .foregroundColor(.primary)
    }
    .accessibilityElement()
    .accessibilityLabel("Total: \(value)")
  }
}

// MARK: - previews

struct TotalStatisticView_Previews: PreviewProvider {
  struct Container: View {
    var persistence: PersistenceController
    
    var body: some View {
      TotalStatisticView(pokemon: pokemon)
        .environment(\.managedObjectContext, persistence.container.viewContext)
    }
    
    var pokemon: Pokemon {
      let pokemon = persistence.pokemon(forName: "clefairy")!
      
      persistence.startNextDownload(forPokemon: pokemon)
      
      return pokemon
    }
  }
  
  static var previews: some View {
    Container(persistence: PersistenceController.preview)
  }
}
