//
//  TotalStatisticView.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import SwiftUI

struct TotalStatisticView: View {
  @State private var animatedValue: Int16 = 0
  @State private var timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

  @ObservedObject var pokemon: Pokemon
  
  var body: some View {
    let value = pokemon.totalStatistic

    HStack {
      Text("Total")
        .font(.headline)
        .foregroundColor(.primary)
      
      Spacer()
      
      Text(animatedValue.description)
        .font(.body)
        .foregroundColor(.primary)
    }
    .onReceive(timer) {
      input in
      
      if value > 0 {
        animatedValue = min(value, animatedValue + 10)
        
        if animatedValue == value {
          self.timer.upstream.connect().cancel()
        }
      }
    }
  }
}

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
