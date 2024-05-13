//
//  StatisticView.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import SwiftUI

/// A view for a particular Pokémon statistic (e.g., Health Points).
struct StatisticView: View {
  @Environment(\.managedObjectContext) private var viewContext

  /// The Pokémon for which to display the statistic.
  @ObservedObject var pokemon: Pokemon
  
  /// The statistic to display.
  let statistic: PokemonStatistic
  
  /// The body for this View.
  var body: some View {
    let value = pokemon.value(forStatistic: statistic)
    
    VStack {
      HStack {
        Text(statistic.description)
          .font(.body)
          .foregroundColor(.primary)
        
        Spacer()
        
        Text(value.description)
          .font(.body)
          .foregroundColor(.secondary)
      }
      
      ProgressView(value: Double(value), total: 255)
        .progressViewStyle(.linear)
        .padding(.vertical, 0)
        .cornerRadius(4)
        .tint(PokemonStatistic.color(forValue: value))
    }
    .accessibilityElement()
    .accessibilityLabel("\(statistic.description): \(value)")
  }
}

// MARK: - previews

struct StatisticView_Previews: PreviewProvider {
  struct Container: View {
    var persistence: PersistenceController
   
    var body: some View {
      StatisticView(pokemon: pokemon, statistic: .hp)
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
