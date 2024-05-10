//
//  Persistence.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import CoreData

/// Controller for  the underlying CoreData store.
struct PersistenceController {
  static let shared = PersistenceController()
   
  let container: NSPersistentContainer
  
  init(inMemory: Bool = false) {
    container = NSPersistentContainer(name: "poke_index")
    
    if inMemory {
      container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
    }
    
    container.loadPersistentStores(completionHandler: {
      (storeDescription, error) in
      
      if let error {
        NSLog("cannot load stores: \(error.localizedDescription)")
      }
    })
   
    container.viewContext.automaticallyMergesChangesFromParent = true
  }
}

// MARK: - previews and sample date

extension PersistenceController {
  static var preview: PersistenceController = {
    let result = PersistenceController(inMemory: true)
    let viewContext = result.container.viewContext
    let dataService = DataService()
    
    dataService.context = viewContext
    dataService.createPokemon(from: clefairy)
    
    return result
  }()
  
  private static var clefairy: Result.Pokemon {
    Result.Pokemon(id: 35,
                   name: "clefairy",
                   sprites: .init(front_default: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/back/35.png"),
                   height: 6,
                   weight: 75,
                   base_experience: 113,
                   order: 64,
                   stats: [
                    .init(base_stat: 70, effort: 2, stat: .init(name: "hp")),
                    .init(base_stat: 45, effort: 9, stat: .init(name: "attack")),
                    .init(base_stat: 60, effort: 0, stat: .init(name: "special-attack")),
                    .init(base_stat: 65, effort: 0, stat: .init(name: "special-defense")),
                    .init(base_stat: 48, effort: 0, stat: .init(name: "defense")),
                    .init(base_stat: 35, effort: 2, stat: .init(name: "speed"))
                   ])
  }
  
  private func makePokemon(number: Int, name: String, imageUrl: String, weight: Int, height: Int, order: Int) -> Pokemon {
    let pokemon = Pokemon(context: container.viewContext)
    
    pokemon.number = Int16(number)
    pokemon.name = name
    pokemon.imageUrl = URL(string: imageUrl)
    pokemon.weight = Int16(weight)
    pokemon.height = Int16(height)
    pokemon.order = Int16(order)
    
    return pokemon
  }
  
  func pokemon(forName name: String) -> Pokemon? {
    let request = Pokemon.fetchRequest()
    
    request.predicate = NSPredicate(format: "name = %@", name)
    
    do {
      return try container.viewContext.fetch(request).first
    }
    catch {
      NSLog("cannot search Pokémon with name \(name): \(error.localizedDescription)")
      
      return nil
    }
  }
}
