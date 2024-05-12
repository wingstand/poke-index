//
//  StatisticView.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import SwiftUI

struct StatisticView: View {
  @Environment(\.managedObjectContext) private var viewContext

  @State private var animatedValue: Int16 = 0
  @State private var timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

  @ObservedObject var pokemon: Pokemon
  let statistic: PokemonStatistic
  
  @State var ticks: Int = 0
  
  var body: some View {
    let value = pokemon.value(forStatistic: statistic)
    
    VStack {
      HStack {
        Text(statistic.description)
          .font(.body)
          .foregroundColor(.primary)
        
        Spacer()
        
        Text(animatedValue.description)
          .font(.body)
          .foregroundColor(.secondary)
      }
      
      ProgressView(value: Float(animatedValue) / 255.0)
        .progressViewStyle(.linear)
        .padding(.vertical, 0)
        .cornerRadius(4)
        .tint(PokemonStatistic.color(forValue: animatedValue))
    }
    .onReceive(timer) {
      input in
      
      ticks += 1
      
      if value > 0 {
        animatedValue = min(value, animatedValue + 3)
        
        if animatedValue == value {
          self.timer.upstream.connect().cancel()
        }
      }
    }
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
