//
//  PokemonView.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import SwiftUI

struct PokemonView: View {
  /// The height of the image in compact view. This is scaled according to the dynamic type settings
  @ScaledMetric var compactImageHeight: CGFloat = 40

  /// The height of the image in regular view. This is scaled according to the dynamic type settings
  @ScaledMetric var regularImageHeight: CGFloat = 80

  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  /// The persistence controller, which controls access to the Core Data
  /// store. Uses the shared one by default, but previews set it to the
  /// preview controller.
  var persistence: PersistenceController = .shared

  /// The Pokémon this view displays.
  @ObservedObject var pokemon: Pokemon
  
  /// The body for this view
  var body: some View {
    List {
      Section {
        HStack(alignment: .center, spacing: 10) {
          imageView
          textView
        }
        .accessibilityElement()
        .accessibilityLabel(detailsAccessibilityText)
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
    .navigationTitle(pokemon.displayName)
  }
  
  /// A view hosting the text displayed at the top of this view.
  private var textView: some View {
    VStack(alignment: .leading, spacing: 3) {
      if horizontalSizeClass == .compact && verticalSizeClass == .compact {
          HStack {
            Text("#\(pokemon.number) \(pokemon.displayName)")
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
        Text("#\(pokemon.number) \(pokemon.displayName)")
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
  
  /// The accessibility text for the details (top) section
  private var detailsAccessibilityText: String {
    var components: [String] = []
    
    components.append("Pokémon number \(pokemon.number)")
    components.append(pokemon.displayName)
    components.append("Weight: \(pokemon.fullWeightDescription)")
    components.append("Height: \(pokemon.fullHeightDescription)")
    components.append("Base experience: \(pokemon.baseExperience)")
   
    if let type1 = pokemon.type(forSlot: 1) {
      if let type2 = pokemon.type(forSlot: 2) {
        components.append("Types: \(type1) and \(type2)")
      }
      else {
        components.append("Type: \(type1)")
      }
    }
    else {
      if let type2 = pokemon.type(forSlot: 2) {
        components.append("Type: \(type2)")
      }
      else {
        components.append("No types")
      }
    }
                        
    return components.joined(separator: ". ")
  }

  /// The view hosting the image displayed by this view
  private var imageView: some View {
    Group {
      if let image = self.image {
        image
          .resizable()
          .aspectRatio(contentMode: .fit)
          .clipped()
      }
      else {
        ProgressView()
      }
    }
    .frame(width: imageHeight, height: imageHeight, alignment: .center)
  }
  
  /// The height of the image, which is dependent on whether we're compact or not.
  private var imageHeight: CGFloat {
    return horizontalSizeClass == .compact && verticalSizeClass == .compact ? compactImageHeight : regularImageHeight
  }
  
  /// The image displayed by this view. If no image data or URL is defined in the associated Pokémon,
  /// a dowbload is triggered.
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

// MARK: - previews

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
    let pokemon = persistence.pokemon(forNumber: 10118)!
    
    Container(persistence: persistence, pokemon: pokemon)
  }
}
