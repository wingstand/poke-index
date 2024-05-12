//
//  PokemonView.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import SwiftUI

struct PokemonView: View {
  /// Preference key used to track the height of text component of this view, which
  /// we use to constrain the image height
  private struct TextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
      value = max(value, nextValue())
    }
  }

  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  /// The persistence controller, which controls access to the Core Data
  /// store. Uses the shared one by default, but previews set it to the
  /// preview controller.
  var persistence: PersistenceController = .shared

  /// The Pokémon this view displays.
  @ObservedObject var pokemon: Pokemon
  
  /// The height of the image displayed by this view.
  @State private var imageHeight: CGFloat = 0

  var body: some View {
    List {
      Section {
        HStack(alignment: .center, spacing: 10) {
          imageView
          
          textView
            .background(
              // Whenever the height of the text view changes, we stash it in the preferences
              GeometryReader {
                proxy in Color.clear.preference(key: TextHeightKey.self, value: proxy.size.height)
              }
            )
        }
      }
      
      Section {
        StatisticView(pokemon: pokemon, statistic: .hp)
        StatisticView(pokemon: pokemon, statistic: .attack)
        StatisticView(pokemon: pokemon, statistic: .defense)
        StatisticView(pokemon: pokemon, statistic: .specialAttack)
        StatisticView(pokemon: pokemon, statistic: .specialDefense)
        StatisticView(pokemon: pokemon, statistic: .speed)
        
        TotalStatisticView(pokemon: pokemon)
      }
    }
    .navigationTitle(pokemon.name?.capitalized ?? "Pokémon")
    .onPreferenceChange(TextHeightKey.self) {
      value in
      
      // Constrain the image height to the text height. This is constrainted to a
      // maximim of 128 since we want to leave room for the text if we're using a
      // large font.
      DispatchQueue.main.async {
        imageHeight = min(128, value)
      }
    }
  }
  
  private var textView: some View {
    VStack(alignment: .leading, spacing: 3) {
      if horizontalSizeClass == .compact && verticalSizeClass == .compact {
          HStack {
            Text("#\(pokemon.number)")
              .font(.headline)
              .foregroundColor(.primary)
            
            Spacer()
            PokemonTypeView(pokemon: pokemon, slot: 1)
          }

        HStack {
          Text("\(pokemon.weightDescription), \(pokemon.heightDescription), base experience: \(pokemon.baseExperience)")
            .font(.body)
            .foregroundColor(.secondary)
          
          Spacer()
          PokemonTypeView(pokemon: pokemon, slot: 2)
        }
      }
      else {
        Text("#\(pokemon.number)")
          .font(.headline)
          .foregroundColor(.primary)
        
        Text("\(pokemon.weightDescription), \(pokemon.heightDescription)")
          .font(.body)
          .foregroundColor(.secondary)
        
        Text("Base experience: \(pokemon.baseExperience)")
          .font(.body)
          .foregroundColor(.primary)
        
        HStack(spacing: 10) {
          PokemonTypeView(pokemon: pokemon, slot: 1)
          PokemonTypeView(pokemon: pokemon, slot: 2)
        }
      }
    }
  }

  private var imageView: some View {
    Group {
      if let image = self.image {
        image
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: imageHeight, alignment: .center)
          .clipped()
      }
      else {
        ProgressView()
          .frame(width: imageHeight, height: imageHeight, alignment: .center)
      }
    }
  }
  
  private var image: Image? {
    if let imageData = pokemon.imageData, let uiImage = UIImage(data: imageData) {
      return Image(uiImage: uiImage)
    }
    else {
      persistence.startNextDownload(forPokemon: pokemon)
      
      return nil
    }
  }
}

struct PokemonView_Previews: PreviewProvider {
  struct Container: View {
    var persistence: PersistenceController
    @State var pokemon: Pokemon
    
    var body: some View {
      NavigationStack {
        PokemonView(persistence: persistence, pokemon: pokemon)
      }
      .environment(\.managedObjectContext, persistence.container.viewContext)
    }
  }
  
  static var previews: some View {
    let persistence = PersistenceController.preview
    let pokemon = persistence.pokemon(forName: "clefairy")!
    
    Container(persistence: persistence, pokemon: pokemon)
  }
}
