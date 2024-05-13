//
//  PokemonStatistic.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import Foundation

enum PokemonStatistic: Int, CaseIterable {
  case hp
  case attack
  case defense
  case specialAttack
  case specialDefense
  case speed
  
  static func from(name: String) -> Self? {
    return allCases.first(where: { $0.name == name })
  }
  
  var name: String {
    switch self {
    case .hp:
      return "hp"
    case .attack:
      return "attack"
    case .defense:
      return "defense"
    case .specialAttack:
      return "special-attack"
    case .specialDefense:
      return "special-defense"
    case .speed:
      return "speed"
    }
  }
}
