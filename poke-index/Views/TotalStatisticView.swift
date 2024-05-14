//
//  TotalStatisticView.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import SwiftUI

/// A view for displaying the total statistics for a Pokémon.
struct TotalStatisticView: View {
  let total: Int
  
  /// The body for this view.
  var body: some View {
    HStack {
      Text("Total")
        .font(.headline)
        .foregroundColor(.primary)
      
      Spacer()
      
      Text(total.description)
        .font(.body)
        .foregroundColor(.primary)
    }
    .accessibilityElement()
    .accessibilityLabel("Total: \(total)")
  }
}

// MARK: - previews

#Preview {
  return TotalStatisticView(total: 99)
}

