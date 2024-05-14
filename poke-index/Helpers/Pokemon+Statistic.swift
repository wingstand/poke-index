//
//  Pokemon+Statistic.swift
//  poke-index
//
//  Created by Gary Meehan on 12/05/2024.
//

import Foundation

extension Pokemon {
  /// Returns the value for the given statisic.
  /// - Parameter statistic: the statistic to get.
  /// - Returns: the value for `statistic`.
//  func value(forStatistic statistic: PokemonStatistic) -> Int16 {
//    switch statistic {
//    case .hp:
//      return hp
//    case .attack:
//      return attack
//    case .defense:
//      return defense
//    case .specialAttack:
//      return specialAttack
//    case .specialDefense:
//      return specialDefense
//    case .speed:
//      return speed
//    }
//  }
//  
//  /// Sets the value for the given statistic,
//  /// - Parameter value: the value to set.
//  /// - Parameter statistic: the statistic to set.  
//  func setValue(_ value: Int16, forStatistic statistic: PokemonStatistic) {
//    switch statistic {
//    case .hp:
//      hp = value
//    case .attack:
//      attack = value
//    case .defense:
//      defense = value
//    case .specialAttack:
//      specialAttack = value
//    case .specialDefense:
//      specialDefense = value
//    case .speed:
//      speed = value
//    }
//  }
  
  /// The total value of all statistics for this Pokémon.
  var totalStatistic: Int {
    return statistics.reduce(0, { $0 + $1.value })
  }
}
