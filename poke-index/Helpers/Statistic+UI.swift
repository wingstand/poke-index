//
//  Statistic+UI.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import SwiftUI

extension Statistic.Kind: CustomStringConvertible {
  var description: String {
    switch self {
    case .hp:
      return "HP"
    case .attack:
      return "Attack"
    case .defense:
      return "Defense"
    case .specialAttack:
      return "Special Attack"
    case .specialDefese:
      return "Special Defense"
    case .speed:
      return "Speed"
    }
  }
}

extension Statistic {
  var color: Color {
    if baseValue < 30 {
      return .red
    }
    else if baseValue < 60 {
      return .orange
    }
    else if baseValue < 90 {
      return .yellow
    }
    else if baseValue < 120 {
      return .green
    }
    else if baseValue < 150 {
      return .cyan
    }
    else if baseValue < 180 {
      return .blue
    }
    else {
      return .purple
    }
  }
}
