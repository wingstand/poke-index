//
//  StatisticView.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import SwiftUI

/// A view for a particular Pokémon statistic (e.g., Health Points).
struct StatisticView: View {
  @Environment(\.managedObjectContext) private var viewContext
 
  /// The statistic to display.
  let statistic: PokemonStatistic
  
  /// The body for this View.
  var body: some View {
    VStack {
      HStack {
        Text(statistic.kind.description)
          .font(.body)
          .foregroundColor(.primary)
        
        Spacer()
        
        Text(statistic.value.description)
          .font(.body)
          .foregroundColor(.secondary)
      }
      
      ProgressView(value: Double(statistic.value), total: 255)
        .progressViewStyle(.linear)
        .padding(.vertical, 0)
        .cornerRadius(4)
        .tint(statistic.color)
    }
    .accessibilityElement()
    .accessibilityLabel("\(statistic.kind.description): \(statistic.value)")
  }
}

// MARK: - previews

#Preview {
  return StatisticView(statistic: .init(kind: .hp, value: 99))
}
