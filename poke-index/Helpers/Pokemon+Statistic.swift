//
//  Pokemon+Statistic.swift
//  poke-index
//
//  Created by Gary Meehan on 12/05/2024.
//

import Foundation

extension Pokemon {
  func value(forStatistic statistic: PokemonStatistic) -> Int16 {
    switch statistic {
    case .hp:
      return hp
    case .attack:
      return attack
    case .defense:
      return defense
    case .specialAttack:
      return specialAttack
    case .specialDefense:
      return specialDefense
    case .speed:
      return speed
    }
  }
  
  func setValue(_ value: Int16, forStatistic statistic: PokemonStatistic) {
    switch statistic {
    case .hp:
      hp = value
    case .attack:
      attack = value
    case .defense:
      defense = value
    case .specialAttack:
      specialAttack = value
    case .specialDefense:
      specialDefense = value
    case .speed:
      speed = value
    }
  }
  
  /// The total value of all statistics for this Pokémon.
  var totalStatistic: Int16 {
    return hp + attack + defense + specialAttack + specialDefense + speed
  }  
}
