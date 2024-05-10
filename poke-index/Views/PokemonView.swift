//
//  PokemonView.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import SwiftUI

struct PokemonView: View {
  // Scale the images so their height (and width) is 3 * the body height
  @ScaledMetric(relativeTo: .body) var imageHeight = UIFont.preferredFont(forTextStyle: .body).lineHeight * 3

  @Environment(\.managedObjectContext) private var viewContext

  @ObservedObject var pokemon: Pokemon
  @FetchRequest private var statistics: FetchedResults<Statistic>

  init(pokemon: Pokemon) {
    self.pokemon = pokemon
    
    _statistics = FetchRequest<Statistic>(sortDescriptors: [NSSortDescriptor(keyPath: \Statistic.rawKind, ascending: true)],
                                          predicate: NSPredicate(format: "pokemon = %@", pokemon),
                                          animation: .default)
  }
  
  var body: some View {
    List {
      Section {
        HStack(alignment: .center, spacing: 10) {
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: imageHeight, height: imageHeight, alignment: .center)
          
          VStack(alignment: .leading) {
            Text(pokemon.name?.capitalized ?? "Anonymous")
              .font(.headline)
            
            if pokemon.number > 0 {
              Text(String(format: "%04d", pokemon.number))
                .font(.body)
                .foregroundColor(.secondary)
            }
          }
        }
      }
      
      Section {
        HStack {
          Text("Height")
          Spacer()
          Text(pokemon.height == 0 ? "Unknown" : pokemon.heightDescription)
            .font(.body)
            .foregroundColor(.secondary)
        }
        
        HStack {
          Text("Weight")
          Spacer()
          Text(pokemon.weight == 0 ? "Unknown" : pokemon.weightDescription)
            .font(.body)
            .foregroundColor(.secondary)
        }
      }
      
      if !statistics.isEmpty {
        Section {
          ForEach(statistics) {
            statistic in StatisticView(statistic: statistic)
          }

          TotalStatisticView(total: totalStatistic)
        }
      }
    }
    .navigationTitle(pokemon.name?.capitalized ?? "Pokémon")
  }
  
  private var image: Image {
    if let imageData = pokemon.imageData, let uiImage = UIImage(data: imageData) {
      return Image(uiImage: uiImage)
    }
    else if pokemon.imageUrl != nil {
      DataService.shared.loadImage(for: pokemon)
    }
    else if pokemon.imageUrl == nil  {
      DataService.shared.loadPokemon(pokemon)
    }
    
    return Image(systemName: "questionmark")
  }
  
  private var totalStatistic: Int {
    return statistics.reduce(0, { $0 + Int($1.baseValue) })
  }
}

struct PokemonView_Previews: PreviewProvider {
  static var previews: some View {
    let persistence = PersistenceController.preview
    let pokemon = persistence.pokemon(forName: "clefairy")!
    
    NavigationStack {
      PokemonView(pokemon: pokemon)
        .environment(\.managedObjectContext, persistence.container.viewContext)
    }
  }
}
