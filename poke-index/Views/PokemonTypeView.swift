//
//  PokemonTypeView.swift
//  poke-index
//
//  Created by Gary Meehan on 12/05/2024.
//

import SwiftUI

/// A view for displaying a type of a Pokémon
struct PokemonTypeView: View {
  /// The type to display.
  let type: PokemonType
  
  /// The body for this view.
  var body: some View {
    Group {
      Text(type.description.uppercased())
        .font(.footnote)
        .foregroundColor(.white)
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
    }
    .background(type.color)
    .cornerRadius(4)
    .padding(.top, 2)
  }
}

// MARK: - previews

#Preview {
  PokemonTypeView(type: .bug)
}
