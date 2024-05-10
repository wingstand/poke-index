//
//  ImageLoader.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import SwiftUI
import CoreData

/// Errors thrown/returned during the loading of data
enum DataServiceError: LocalizedError {
  /// A bad URL was encounted
  case badUrl
  
  /// No data was found when some was expected
  case noData
  
  /// Data was in the incorrect format
  case badData
  
  /// The context used to access the CoreData stroe wasn't set
  case noContext
  
  var errorDescription: String? {
    switch self {
    case .badUrl:
      return "bad URL"
      
    case .noData:
      return "no data"

    case .badData:
      return "bad data"
      
    case .noContext:
      return "managed-object-context has not been set"
    }
  }
}

/// Helper routines for the asynchronous loading of JSON, images, etc from an external source
/// and saving them to the CoreData database
class DataService {
  /// The single shared instance of this type
  static var shared: DataService = DataService()
  
  /// context to be used when saving loaded items to the database
  var context: NSManagedObjectContext?
  
  // MARK: - look-up functions
  
  func pokemon(forName name: String) -> Pokemon? {
    guard let context else {
      return nil
    }
    
    let request = Pokemon.fetchRequest()
    
    request.predicate = NSPredicate(format: "name = %@", name)
    
    do {
      return try context.fetch(request).first
    }
    catch {
      NSLog("cannot search Pokémon with name \(name): \(error.localizedDescription)")
      
      return nil
    }
  }
  
  // MARK: internal helper functions
  
  private func save() {
    do {
      guard let context else {
        throw DataServiceError.noContext
      }
      
      try context.save()
    }
    catch {
      NSLog("cannot save: \(error.localizedDescription)")
    }
  }
  
  // MARK: - loading the Pokémon
  
  func deleteAllPokemon() {
    do {
      guard let context else {
        throw DataServiceError.noContext
      }
      
      let request = Pokemon.fetchRequest()
      let pokemon = try context.fetch(request)
     
      pokemon.forEach({ context.delete($0) })
      
      try context.save()
    }
    catch {
      NSLog("cannot delete Pokémon: \(error.localizedDescription)")
    }
  }
  
  func loadPokemon() {
    do {
      guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon/") else {
        throw DataServiceError.badUrl
      }
      
      loadPokemon(from: url)
    }
    catch {
      NSLog("cannot load Pokémon: \(error.localizedDescription)")
    }
  }
  
  private func loadPokemon(from url: URL) {
    let request = URLRequest(url: url)
    
    let task = URLSession.shared.downloadTask(with: request) {
      url, response, error in self.didLoadPokemon(response: response, error: error)
    }
    
    task.resume()
  }
  
  private func didLoadPokemon(response: URLResponse?, error: Error?) {
    do {
      guard let localUrl = response?.url else {
        throw DataServiceError.noData
      }
      
      let data = try Data(contentsOf: localUrl)
      let result = try JSONDecoder().decode(Result.AllPokemon.self, from: data)
      
      DispatchQueue.main.async {
        self.createPokemon(from: result)
      }
      
      if let nextPageUrl = URL(string: result.next) {
        loadPokemon(from: nextPageUrl)
      }
    }
    catch {
      NSLog("failed to download Pokémon: \(error.localizedDescription)")
    }
  }
  
  private func createPokemon(from result: Result.AllPokemon) {
    do {
      guard let context else {
        throw DataServiceError.noContext
      }
      
      for item in result.results {
        let pokemon = Pokemon(context: context)
        
        pokemon.name = item.name
        
        if let url = URL(string: item.url) {
          pokemon.url = url
          
          // We guess the number (ID) of the Pokémon from the last component
          // of the URL path. It'll be corrected, if necessary, when we load
          // the URL itself to get the data. Doing this stops the list being
          // manically resorted when we load the URLs and set the number.
          if let number = Int16(url.lastPathComponent) {
            pokemon.number = number
          }
        }
      }
      
      try context.save()
    }
    catch {
      NSLog("cannot save Pokémon: \(error.localizedDescription)")
    }
  }
  
  // MARK: - loading individual Pokémon
  
  func loadPokemon(_ pokemon: Pokemon) {
    do {
      guard let url = pokemon.url else {
        throw DataServiceError.badUrl
      }
      
      let request = URLRequest(url: url)
      
      let task = URLSession.shared.downloadTask(with: request) {
        url, response, error in self.didLoadPokemon(pokemon, response: response, error: error)
      }
      
      task.resume()
    }
    catch {
      NSLog("cannot load Pokémon: \(error.localizedDescription)")
    }
  }
  
  private func didLoadPokemon(_ pokemon: Pokemon, response: URLResponse?, error: Error?) {
    do {
      if let error {
        throw error
      }
      
      guard let localUrl = response?.url else {
        throw DataServiceError.noData
      }
      
      let data = try Data(contentsOf: localUrl)
      let result = try JSONDecoder().decode(Result.Pokemon.self, from: data)
      
      DispatchQueue.main.async {
        self.updatePokemon(pokemon, from: result)
      }
    }
    catch {
      NSLog("cannot load Pokémon: \(error.localizedDescription)")
    }
  }
  
  private func updatePokemon(_ pokemon: Pokemon, from result: Result.Pokemon) {
    do {
      guard let context else {
        throw DataServiceError.noContext
      }
      
      if let urlString = result.sprites.front_default, let url = URL(string: urlString) {
        pokemon.imageUrl = url
      }
      
      pokemon.name = result.name
      pokemon.number = Int16(result.id)
      pokemon.height = Int16(result.height)
      pokemon.weight = Int16(result.weight)
      pokemon.order = Int16(result.order)
      pokemon.baseExperience = Int16(result.base_experience)
      
      for stat in result.stats {
        guard let kind = Statistic.Kind.from(name: stat.stat.name) else {
          continue
        }
         
        let statistic = Statistic(context: context)
        
        statistic.pokemon = pokemon
        statistic.kind = kind
        statistic.baseValue = Int16(stat.base_stat)
        statistic.effort = Int16(stat.effort)
      }
      
      for type in result.types {
        guard let kind = PokemonType.Kind.from(name: type.type.name) else {
          continue
        }
        
        let pokemonType = PokemonType(context: context)
        
        pokemonType.pokemon = pokemon
        pokemonType.slot = Int16(type.slot)
        pokemonType.kind = kind
      }
      
      try context.save()
    }
    catch {
      NSLog("cannot save Pokémon: \(error.localizedDescription)")
    }
  }
  
  func createPokemon(from result: Result.Pokemon) {
    do {
      guard let context else {
        throw DataServiceError.noContext
      }
      
      let pokemon = Pokemon(context: context)

      updatePokemon(pokemon, from: result)
    }
    catch {
      NSLog("cannot save Pokémon: \(error.localizedDescription)")
    }    
  }
  
  // MARK: - loading Pokemon image data
  
  func loadImage(for pokemon: Pokemon) {
    guard let url = pokemon.imageUrl else {
      return
    }
    
    let request = URLRequest(url: url)
    
    let task = URLSession.shared.downloadTask(with: request) {
      url, response, error in self.didLoadImage(for: pokemon, response: response, error: error)
    }
    
    task.resume()
  }
  
  private func didLoadImage(for pokemon: Pokemon, response: URLResponse?, error: Error?) {
    do {
      guard let localUrl = response?.url else {
        throw DataServiceError.noData
      }
      
      let data = try Data(contentsOf: localUrl)
      
      DispatchQueue.main.async {
        pokemon.imageData = data
        self.save()
      }
    }
    catch {
      NSLog("cannot save image for Pokémon: \(error.localizedDescription)")
    }
  }
}
