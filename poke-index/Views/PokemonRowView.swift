//
//  PokemonRowView.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import SwiftUI

/// The view for each row in the main Pokémon list view
struct PokemonRowView: View {
  // Scale the images so their height (and width) is 3 * the body height,
  // i.e., threee lines of text, which shuld be about what this row takes.
  @ScaledMetric(relativeTo: .body) var imageHeight = UIFont.preferredFont(forTextStyle: .body).lineHeight * 3
  
  @ObservedObject var pokemon: Pokemon
  
  var body: some View {
    let imageHeight = self.imageHeight
    let imageWidth = imageHeight
    
    HStack(alignment: .center, spacing: 10) {
      if let image {
        image
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: imageWidth, height: imageHeight, alignment: .center)
          .clipped()
      }
      else {
        Group {
          ProgressView()
        }
        .frame(width: imageWidth, height: imageHeight, alignment: .center)
      }
      
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
  }
  
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
