//
//  PokemonStatistic+UI.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import SwiftUI

extension PokemonStatistic: CustomStringConvertible {
  var description: String {
    switch self {
    case .hp:
      return "Health Points"
    case .attack:
      return "Attack"
    case .defense:
      return "Defense"
    case .specialAttack:
      return "Special Attack"
    case .specialDefense:
      return "Special Defense"
    case .speed:
      return "Speed"
    }
  }
}

extension PokemonStatistic {
  static func color(forValue value: Int16) -> Color {
    if value < 30 {
      return .red
    }
    else if value < 60 {
      return .orange
    }
    else if value < 90 {
      return .yellow
    }
    else if value < 120 {
      return .green
    }
    else if value < 150 {
      return .cyan
    }
    else if value < 180 {
      return .blue
    }
    else {
      return .purple
    }
  }
}
