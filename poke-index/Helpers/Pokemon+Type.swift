//
//  Pokemon+Type.swift
//  poke-index
//
//  Created by Gary Meehan on 12/05/2024.
//

import Foundation

extension Pokemon {
  func type(forSlot slot: Int) -> PokemonType? {
    switch slot {
    case 1:
      return PokemonType(rawValue: rawType1)
    case 2:
      return PokemonType(rawValue: rawType2)
    default:
      return nil
    }
  }
  
  func setType(_ type: PokemonType, forSlot slot: Int) {
    switch slot {
    case 1:
      rawType1 = type.rawValue
    case 2:
      rawType2 = type.rawValue
    default:
      break
    }
  }
}
