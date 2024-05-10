//
//  Stat+UI.swift
//  poke-index
//
//  Created by Gary Meehan on 10/05/2024.
//

import Foundation

extension Statistic {
  enum Kind: Int16, CaseIterable {
    case hp
    case attack
    case defense
    case specialAttack
    case specialDefese
    case speed

    static func from(name: String) -> Kind? {
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
      case .specialDefese:
        return "special-defense"
      case .speed:
        return "speed"
      }
    }
  }
  
  var kind: Kind {
    get {
      return Kind(rawValue: rawKind) ?? .hp
    }
    set {
      rawKind = newValue.rawValue
    }
  }
}
