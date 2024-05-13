//
//  TotalStatisticView.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import SwiftUI

struct TotalStatisticView: View {
  @ObservedObject var pokemon: Pokemon
  
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
