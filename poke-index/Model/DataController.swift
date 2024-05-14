//
//  Persistence.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import Foundation
import SwiftData

/// Controller for  the underlying model container, which also provides methods for populating that container.
class DataController {
  /// User-defaults keys
  private struct Key {
    static let currentPageUrl = "currentPageUrl"
    static let haveDownloadedAllPages = "haveDownloadedAllPages"
  }
  
  /// The default, shared controller used by apps that are acutally run.
  static var shared: DataController = {
    let schema = Schema([
      Pokemon.self,
    ])
    
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    
    do {
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      
      return DataController(container: container)
    }
    catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
  
  /// Constructs a new instance of this class. This should not be used directly,
  /// but via the shared or preview static members
  private init(container: ModelContainer) {
    self.container = container
  }
  
  /// The model container used by this controller.
  let container: ModelContainer
  
  /// The URLs that are currently being downloaded. Tracked so we don't make multiple requests
  private var pendingUrls: Set<URL> = []
  
  // MARK: - look-up functions
  
  /// Searches for a Pokémon by name. The search is case sensitive and matches complete names.
  /// - Parameter name: the name of the Pokémon.
  /// - Returns: the Pokémon with the given name, `nil` if no such object.
  @MainActor func pokemon(forName name: String) -> Pokemon? {
    let pokemon = FetchDescriptor<Pokemon>(predicate: #Predicate{ $0.name == name })
    
    return try? container.mainContext.fetch(pokemon).first
  }
  
  /// Searches for a Pokémon by number.
  /// - Parameter number: the number of the Pokémon.
  /// - Returns: the Pokémon with the given number, `nil` if no such object.
  @MainActor func pokemon(forNumber number: Int) -> Pokemon? {
    let pokemon = FetchDescriptor<Pokemon>(predicate: #Predicate{ $0.number == number })
    
    return try? container.mainContext.fetch(pokemon).first
  }
  
  // MARK: - loading all Pokémon
  
  /// Synchronously deletes all Pokémon from the data store.
  @MainActor func deleteAllPokemon() {
    do {
      try container.mainContext.delete(model: Pokemon.self)
      
      let userDefaults = UserDefaults.standard
      
      userDefaults.set(false, forKey: Key.haveDownloadedAllPages)
      userDefaults.removeObject(forKey: Key.currentPageUrl)
      
      NSLog("deleted all Pokémon")
    }
    catch {
      NSLog("cannot delete Pokémon: \(error.localizedDescription)")
    }
  }
  
  /// Starts or resumes downloading all Pokémon from the server. If all Pokémon are on the
  /// device, no download is made.
  func downloadAllPokemon() {
    downloadNextPage()
  }
  
  /// Starts or resumes downloading the next page of Pokémon from the server. If all Pokémon are on the
  /// device, no download is made.
  private func downloadNextPage() {
    let userDefaults = UserDefaults.standard
    
    guard !userDefaults.bool(forKey: Key.haveDownloadedAllPages) else {
      NSLog("have already downloaded all pages of Pokémon")
      
      return
    }
    
    guard let url = userDefaults.url(forKey: Key.currentPageUrl) ?? URL(string: "https://pokeapi.co/api/v2/pokemon/?offset=0&limit=100") else {
      NSLog("can't get URL for next page")
      
      return
    }
    
    guard !pendingUrls.contains(url) else {
      return
    }
    
    pendingUrls.insert(url)
    
    NSLog("downloading next page of Pokémon from \(url)")
    
    Task.init {
      do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let result = try JSONDecoder().decode(Result.Page.self, from: data)
        
        DispatchQueue.main.async {
          let userDefaults = UserDefaults.standard
          
          self.createPokemon(from: result)
          self.pendingUrls.remove(url)
          
          if let next = result.next, let nextPageUrl = URL(string: next) {
            userDefaults.set(nextPageUrl, forKey: Key.currentPageUrl)
            self.downloadNextPage()
          }
          else {
            userDefaults.set(true, forKey: Key.haveDownloadedAllPages)
            userDefaults.removeObject(forKey: Key.currentPageUrl)
            
            NSLog("finished loading all pages of Pokémon")
          }
        }
      }
      catch {
        NSLog("cannot download page of Pokémon: \(error.localizedDescription)")
      }
    }
  }
  
  /// Creates Pokémon objects from a page of Pokémon data. Each result contains only a name and URL; we synthesize a nuber from the URL.
  /// - Parameter result: a page of Pokémon data.
  @MainActor private func createPokemon(from page: Result.Page) {
    let context = container.mainContext
    
    for item in page.results {
      guard let url = URL(string: item.url) else {
        continue
      }
      
      let pokemon = Pokemon(name: item.name, url: url)
      
      // We guess the number (ID) of the Pokémon from the last component
      // of the URL path. It'll be corrected, if necessary, when we load
      // the URL itself to get the data. Doing this stops the list being
      // manically resorted when we load the URLs and set the number.
      if let number = Int(url.lastPathComponent) {
        pokemon.number = number
      }
      
      context.insert(pokemon)
    }
  }
  
  // MARK: - loading individual Pokémon
  
  /// Starts the next necessary download for a Pokémon. If the details haven't been downloaded,
  /// the method starts downloading the details. If the Pokémon's image data hasn't been downloaded,
  /// the method starts dowloading said data. Otherwise, nothing is done.
  /// - Parameter pokemon: the Pokémon we might need to dowload.
  func startNextDownload(forPokemon pokemon: Pokemon) {
    if pokemon.imageData == nil {
      if pokemon.imageUrl == nil {
        if !pokemon.hasBeenDownloaded {
          downloadPokemon(pokemon)
        }
      }
      else {
        downloadImage(forPokemon: pokemon)
      }
    }
  }
  
  /// Start downloading the details for a Pokémon.
  /// - Parameter pokemon: the Pokémon whose details we need to dowload.
  private func downloadPokemon(_ pokemon: Pokemon) {
    let url = pokemon.url
    
    guard !pendingUrls.contains(url) else {
      return
    }
    
    pendingUrls.insert(url)
    
    NSLog("starting download of \(url)")
    
    Task.init {
      do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let result = try JSONDecoder().decode(Result.Pokemon.self, from: data)
        
        DispatchQueue.main.async {
          self.updatePokemon(pokemon, from: result)
          self.pendingUrls.remove(url)
          
          NSLog("finished download of \(url)")
        }
      }
      catch {
        NSLog("cannot download Pokémon: \(error.localizedDescription)")
      }
    }
  }
  
  /// Update a Pokémon with the given result.
  /// - Parameter pokemon: the Pokémon to update.
  /// - Parameter result: the details from the server.
  private func updatePokemon(_ pokemon: Pokemon, from result: Result.Pokemon) {
    if let urlString = result.sprites.front_default ?? result.sprites.front_shiny {
      if let url = URL(string: urlString) {
        pokemon.imageUrl = url
      }
      else {
        NSLog("can't parse \(urlString)")
      }
    }
    else {
      NSLog("missing image URL")
    }
    
    //pokemon.name = result.name
    pokemon.number = result.id
    pokemon.height = result.height
    pokemon.weight = result.weight
    pokemon.order = result.order
    pokemon.baseExperience = result.base_experience
    
    result.stats.forEach {
      if let kind = PokemonStatistic.Kind(rawValue: $0.stat.name) {
        pokemon.statistics.append(PokemonStatistic(kind: kind, value: $0.base_stat))
      }
    }
    
    result.types.forEach {
      if let type = PokemonType(rawValue: $0.type.name) {
        pokemon.types.append(type)
      }
    }
  }
  
  // MARK: - downloading Pokemon image data
  
  /// Start downloading the image data for a Pokémon.
  /// - Parameter pokemon: the Pokémon whose image data we need.
  private func downloadImage(forPokemon pokemon: Pokemon) {
    guard let url = pokemon.imageUrl, !pendingUrls.contains(url) else {
      return
    }
    
    pendingUrls.insert(url)
    
    NSLog("starting download of \(url)")

    Task.init {
      do {
        let (data, _) = try await URLSession.shared.data(from: url)
        
        DispatchQueue.main.async {
          pokemon.imageData = data
          self.pendingUrls.remove(url)
          
          NSLog("finished download of \(url)")
        }
      }
      catch {
        NSLog("cannot download image for Pokémon: \(error.localizedDescription)")
      }
    }
  }
}

// MARK: - previews

extension DataController {
  @MainActor
  static var preview: DataController = {
    let schema = Schema([
      Pokemon.self,
    ])
    
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    
    do {
      let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
      let controller = DataController(container: container)
      
      if let url = URL(string: "https://pokeapi.co/api/v2/pokemon/35/") {
        controller.createPokemon(from: clefairy, url: url)
      }
      
      if let url = URL(string: "https://pokeapi.co/api/v2/pokemon/35/") {
        controller.createPokemon(from: zygarde10PowerConstruct, url: url)
      }
      
      return controller
    }
    catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
  
  /// A sample result, based on Clefairy, used in previews.
  private static var clefairy: Result.Pokemon {
    Result.Pokemon(id: 35,
                   name: "clefairy",
                   sprites: .init(front_default: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/35.png",
                                  front_shiny: nil),
                   height: 6,
                   weight: 75,
                   base_experience: 113,
                   order: 64,
                   stats: [
                    .init(base_stat: 70, effort: 2, stat: .init(name: "hp")),
                    .init(base_stat: 45, effort: 9, stat: .init(name: "attack")),
                    .init(base_stat: 190, effort: 0, stat: .init(name: "special-attack")),
                    .init(base_stat: 65, effort: 0, stat: .init(name: "special-defense")),
                    .init(base_stat: 148, effort: 0, stat: .init(name: "defense")),
                    .init(base_stat: 35, effort: 2, stat: .init(name: "speed"))
                   ],
                   types: [
                    .init(slot: 1, type: .init(name: "fairy")),
                    .init(slot: 2, type: .init(name: "poison"))
                   ])
    
  }
  
  /// A sample result, based on Zygarde 10 Power Construct, used in previews for testing long names
  private static var zygarde10PowerConstruct: Result.Pokemon {
    Result.Pokemon(id: 10118,
                   name: "zygarde-10-power-construct",
                   sprites: .init(front_default: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/10118.png",
                                  front_shiny: nil),
                   height: 12,
                   weight: 335,
                   base_experience: 243,
                   order: 64,
                   stats: [
                    .init(base_stat: 70, effort: 2, stat: .init(name: "hp")),
                    .init(base_stat: 45, effort: 9, stat: .init(name: "attack")),
                    .init(base_stat: 190, effort: 0, stat: .init(name: "special-attack")),
                    .init(base_stat: 65, effort: 0, stat: .init(name: "special-defense")),
                    .init(base_stat: 148, effort: 0, stat: .init(name: "defense")),
                    .init(base_stat: 35, effort: 2, stat: .init(name: "speed"))
                   ],
                   types: [
                    .init(slot: 1, type: .init(name: "fairy")),
                    .init(slot: 2, type: .init(name: "poison"))
                   ])
    
  }
  
  /// Create a Pokémon from the given result.
  /// - Parameter result: the details from the server.
  @MainActor private func createPokemon(from result: Result.Pokemon, url: URL) {
    let context = container.mainContext
    let pokemon = Pokemon(name: result.name, url: url)

    context.insert(pokemon)
    updatePokemon(pokemon, from: result)
  }
}
