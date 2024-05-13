//
//  StatisticView.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import SwiftUI

struct StatisticView: View {
  @Environment(\.managedObjectContext) private var viewContext

  @ObservedObject var pokemon: Pokemon
  let statistic: PokemonStatistic
  
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
