//
//  PokemonRowView.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import SwiftUI

/// A view for each row in the main Pokémon list view. This adjusts depending on
/// whether we are in compact mode (i.e., landscape mode on an iPhone) or regular
/// (everything else).
struct PokemonRowView: View {
  /// The height of the image in compact view. This is scaled according to the dynamic type settings
  @ScaledMetric var compactImageHeight: CGFloat = 32

  /// The height of the image in regular view. This is scaled according to the dynamic type settings
  @ScaledMetric var regularImageHeight: CGFloat = 64
  
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass

  /// The persistence controller, which controls access to the Core Data
  /// store. Uses the shared one by default, but previews set it to the
  /// preview controller
  var persistence: PersistenceController = .shared
  
  /// The Pokémon this row displays.
  @ObservedObject var pokemon: Pokemon
  
  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      imageView
        textView
    }
    .accessibilityElement()
    .accessibility(label: Text("Pokémon number \(pokemon.number). \(pokemon.displayName)."))
  }
  
  /// - Returns: The text component of this view.
  private var textView: some View {
    Group {
      if horizontalSizeClass == .compact && verticalSizeClass == .compact {
        compactTextView
      }
      else {
        regularTextView
      }
    }
  }
  
  /// - Returns: The text component of this row in regular mode. This displays three lines of text
  /// (assuming the fonts are small enough),
  private var regularTextView: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(pokemon.displayName)
        .font(.headline)
        .foregroundColor(.primary)
      
      Text("#\(pokemon.number)")
        .font(.body)
        .foregroundColor(.secondary)
      
      if pokemon.weight > 0 && pokemon.height > 0 {
        Text("\(pokemon.weightDescription), \(pokemon.heightDescription)")
          .font(.callout)
          .foregroundColor(.primary)
      }
      else {
        Text("Unknown weight and height")
          .font(.callout)
          .foregroundColor(.secondary)
      }
    }
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
  
  /// - Returns: The text component of this row in compact mode. This displays only one
  /// line of text, so we can fit more rows onto the screen.
  private var compactTextView: some View {
    HStack(alignment: .center, spacing: 1) {
      Text(pokemon.displayName)
        .font(.headline)
      
      Spacer()
      
      if pokemon.number > 0 {
        Text(String(format: "#\(pokemon.number)", pokemon.number))
          .font(.body)
          .foregroundColor(.secondary)
      }
    }
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

struct PokemonRowView_Previews: PreviewProvider {
  static var previews: some View {
    let persistence = PersistenceController.preview
    let pokemon = persistence.pokemon(forNumber: 10118)!
    
    PokemonRowView(persistence: persistence, pokemon: pokemon)
      .environment(\.managedObjectContext, persistence.container.viewContext)
  }
}
