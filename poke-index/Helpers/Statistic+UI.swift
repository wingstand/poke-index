//
//  Statistic+UI.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import Foundation

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
