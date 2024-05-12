//
//  PokemonRowView.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import SwiftUI

/// The view for each row in the main Pokémon list view. This adjusts depending on
/// whether we are in compact mode (i.e., landscape mode on an iPhone) or regular
/// (everything else).
struct PokemonRowView: View {
  /// Preference key used to track the height of text component of this row, which
  /// we use to constrain the image height
  private struct TextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
      value = max(value, nextValue())
    }
  }

  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  @Environment(\.verticalSizeClass) var verticalSizeClass
  
  /// The Pokémon this row displays.
  @ObservedObject var pokemon: Pokemon
  
  /// The height of the image displayed by this row.
  @State private var imageHeight: CGFloat = 0
  
  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      Group {
        if let image {
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
        }
        else {
          ProgressView()
        }
      }
      .frame(width: imageHeight, height: imageHeight, alignment: .center)
      
      textView
        .background(
          // Whenever the height of the text view changes, we stash it in the preferences
          GeometryReader {
            proxy in Color.clear.preference(key: TextHeightKey.self, value: proxy.size.height)
          }
        )
    }
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
  
  /// - Returns: The text component of this row in regular mode. This displays three lines of text.
  private var regularTextView: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(pokemon.name?.capitalized ?? "Anonymous")
        .font(.headline)
      
      if pokemon.number > 0 {
        Text(String(format: "%04d", pokemon.number))
          .font(.body)
          .foregroundColor(.secondary)
      }
      
      if pokemon.weight > 0 && pokemon.height > 0 {
        Text("\(pokemon.weightDescription), \(pokemon.heightDescription)")
          .font(.callout)
          .foregroundColor(.primary)
      }
    }
  }
  
  /// - Returns: The text component of this row in compact mode. This displays only one
  /// line of text, so we can fit more rows onto the screen.
  private var compactTextView: some View {
    HStack(alignment: .center, spacing: 1) {
      Text(pokemon.name?.capitalized ?? "Anonymous")
        .font(.headline)
      
      Spacer()
      
      if pokemon.number > 0 {
        Text(String(format: "%04d", pokemon.number))
          .font(.body)
          .foregroundColor(.secondary)
      }
    }
  }
  
  /// - Returns: The image component of this row.
  private var image: Image? {
    if let imageData = pokemon.imageData, let uiImage = UIImage(data: imageData) {
      return Image(uiImage: uiImage)
    }
    else {
      DataService.shared.startAnyNecessaryDownloads(forPokemon: pokemon)
    
      return nil
    }
  }
}

struct PokemonRowView_Previews: PreviewProvider {
  static var previews: some View {
    let persistence = PersistenceController.preview
    let pokemon = persistence.pokemon(forName: "clefairy")!
    
    PokemonRowView(pokemon: pokemon)
  }
}
