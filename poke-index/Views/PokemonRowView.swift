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
  
  @Environment(\.managedObjectContext) private var viewContext
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.verticalSizeClass) private var verticalSizeClass
  
  /// The persistence controller, which controls access to the Core Data
  /// store. Uses the shared one by default, but previews set it to the
  /// preview controller
  var persistence: PersistenceController = .shared
  
  /// The Pokémon this row displays.
  @ObservedObject var pokemon: Pokemon
  
  /// The height of the image displayed by this row.
  @State private var imageHeight: CGFloat = 0
  
  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      imageView

      ZStack {
        imageGuideView
        textView
      }
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
  
  /// A view that isn't displayed but is used as a guide for the image's height. It uses one line in compact
  /// mode and three lines otherwise.
  private var imageGuideView: some View {
    VStack {
      if horizontalSizeClass == .compact && verticalSizeClass == .compact {
        Text("1")
      }
      else {
        Text("1")
        Text("2")
        Text("3")
      }
    }
    .font(.body)
    .foregroundColor(.clear)
    .background(
      // Whenever the height of the text view changes, we stash it in the preferences
      GeometryReader {
        proxy in Color.clear.preference(key: TextHeightKey.self, value: proxy.size.height)
      }
    )
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

struct PokemonRowView_Previews: PreviewProvider {
  static var previews: some View {
    let persistence = PersistenceController.preview
    let pokemon = persistence.pokemon(forNumber: 10118)!
    
    PokemonRowView(persistence: persistence, pokemon: pokemon)
      .environment(\.managedObjectContext, persistence.container.viewContext)
  }
}
