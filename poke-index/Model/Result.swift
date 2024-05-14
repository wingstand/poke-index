//
//  Result.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import Foundation

/// Objects used to parse JSON results from the server.
struct Result {
  struct Page: Decodable {
    struct Item : Decodable {
      let name: String
      let url: String
    }
    
    let count: Int
    let next: String?
    let results: [Item]
  }
  
  struct Pokemon: Decodable {
    struct Sprites: Decodable {
      let front_default: String?
      let front_shiny: String?
    }
    
    struct Kind: Decodable {
      struct Kind: Decodable {
        let name: String
      }
      
      let slot: Int
      let type: Kind
    }
    
    struct Statistic: Decodable {
      struct Stat: Decodable {
        let name: String
      }
     
      let base_stat: Int
      let effort: Int
      let stat: Stat
    }
    
    let id: Int
    let name: String
    let sprites: Sprites
    let height: Int
    let weight: Int
    let base_experience: Int
    let stats: [Statistic]
    let types: [Kind]
  }
}
