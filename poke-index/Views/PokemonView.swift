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

  @Environment(\.modelContext) private var modelContext
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  /// The controller used for downloading data from the server. Defaults to shared
  /// but previews have their own in-memory versions
  var controller: DataController = .shared
  
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
        ForEach(pokemon.statistics) {
          statistic in StatisticView(statistic: statistic)
        }
        
        TotalStatisticView(total: pokemon.totalStatistic)
      }
    }
    .navigationTitle(pokemon.displayName)
  }
  
  /// A view hosting the text displayed at the top of this view.
  private var textView: some View {
    VStack(alignment: .leading, spacing: 3) {
      if horizontalSizeClass == .compact && verticalSizeClass == .compact {
        HStack {
          VStack {
            Text("#\(pokemon.number) \(pokemon.displayName)")
              .font(.headline)
              .foregroundColor(.primary)
            
            Text("\(pokemon.weightDescription), \(pokemon.heightDescription), base experience: \(pokemon.baseExperience)")
              .font(.body)
              .foregroundColor(.secondary)
          }
          
          Spacer()
          
          VStack(spacing: 5) {
            ForEach(pokemon.types, id: \.self) {
              type in PokemonTypeView(type: type)
            }
          }
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
          ForEach(pokemon.types, id: \.self) {
            type in PokemonTypeView(type: type)
          }
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
   
    switch pokemon.types.count {
    case 0:
      components.append("No types")
    case 1:
      components.append("Type: \(pokemon.types[0])")
    case 2:
      components.append("Type: \(pokemon.types[0]) and \(pokemon.types[1])")
    default:
      // There should be at most two types
      break
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
      controller.startNextDownload(forPokemon: pokemon)
      
      return nil
    }
  }
}

// MARK: - previews

#Preview {
  let controller = DataController.preview
  let pokemon = controller.pokemon(forNumber: 10118)!
  
  return PokemonView(controller: controller, pokemon: pokemon)
    .modelContainer(controller.container)
}
