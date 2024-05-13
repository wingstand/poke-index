//
//  PokemonStatistic.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import Foundation

/// A wrapper around a statistic of a Pokémon, used for type correctness.
enum PokemonStatistic: Int, CaseIterable {
  case hp
  case attack
  case defense
  case specialAttack
  case specialDefense
  case speed

  /// Constructs a statistic from a name.
  /// - Parameter name: the name of the type
  /// - Returns: the statistic with the givem name, `nil` if no such type.
  static func from(name: String) -> Self? {
    return allCases.first(where: { $0.name == name })
  }
  
  /// The name of the statistic.
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
