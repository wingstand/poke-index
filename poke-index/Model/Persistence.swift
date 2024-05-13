//
//  Persistence.swift
//  poke-index
//
//  Created by Gary Meehan on 09/05/2024.
//

import CoreData

/// Errors thrown/returned during the loading of data
enum PersistenceControllerError: LocalizedError {
  /// A bad URL was encounted
  case badUrl
  
  /// No data was found when some was expected
  case noData
  
  /// Data was in the incorrect format
  case badData
  
  var errorDescription: String? {
    switch self {
    case .badUrl:
      return "bad URL"
      
    case .noData:
      return "no data"

    case .badData:
      return "bad data"
    }
  }
}

/// Controller for  the underlying CoreData store.
class PersistenceController {
  /// User-defaults keys
  private struct Key {
    static let currentPageUrl = "currentPageUrl"
    static let haveDownloadedAllPages = "haveDownloadedAllPages"
  }
  
  static let shared = PersistenceController()
   
  let container: NSPersistentContainer
  
  /// The URLs that are currently being downloaded. Tracked so we don't make multiple requests
  private var pendingUrls: Set<URL> = []
  
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
  
  // MARK: - look-up functions
  
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
  
  // MARK: - loading all Pokémon
  
  func deleteAllPokemon() {
    do {
      let context = container.viewContext

      (try context.fetch(Pokemon.fetchRequest())).forEach({ context.delete($0) })
      
      try context.save()
      
      let userDefaults = UserDefaults.standard

      userDefaults.set(false, forKey: Key.haveDownloadedAllPages)
      userDefaults.removeObject(forKey: Key.currentPageUrl)
      
      NSLog("deleted all Pokémon")
    }
    catch {
      NSLog("cannot delete Pokémon: \(error.localizedDescription)")
    }
  }
  
  /// Download all the Pokémon from the server
  func downloadAllPokemon() {
    do {
      let userDefaults = UserDefaults.standard
      
      if userDefaults.bool(forKey: Key.haveDownloadedAllPages) {
        NSLog("have already downloaded all pages of Pokémon")
      }
      else if let url = userDefaults.url(forKey: Key.currentPageUrl) {
        // Pick up from where we left off
        downloadPokemon(from: url)
      }
      else {
        // Start from scratch, specify our own limit as the default (20) is a little low
        // and leads to lots of requests.
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon/?offset=0&limit=100") else {
          throw PersistenceControllerError.badUrl
        }
 
        downloadPokemon(from: url)
      }
    }
    catch {
      NSLog("cannot download Pokémon: \(error.localizedDescription)")
    }
  }
  
  private func downloadPokemon(from url: URL) {
    guard !pendingUrls.contains(url) else {
      return
    }
    
    pendingUrls.insert(url)
    UserDefaults.standard.set(url, forKey: Key.currentPageUrl)
    
    NSLog("downloading next page of Pokémon from \(url)")
    
    let request = URLRequest(url: url)
    
    let task = URLSession.shared.downloadTask(with: request) {
      _, response, error in self.didDownloadPokemon(from: url, response: response, error: error)
    }
    
    task.resume()
  }
  
  private func didDownloadPokemon(from url: URL, response: URLResponse?, error: Error?) {
    do {
      guard let localUrl = response?.url else {
        throw PersistenceControllerError.noData
      }
      
      let data = try Data(contentsOf: localUrl)
      let result = try JSONDecoder().decode(Result.AllPokemon.self, from: data)
      
      DispatchQueue.main.async {
        self.createPokemon(from: result)
        self.pendingUrls.remove(url)

        if let next = result.next, let nextPageUrl = URL(string: next) {
          self.downloadPokemon(from: nextPageUrl)
        }
        else {
          let userDefaults = UserDefaults.standard

          userDefaults.set(true, forKey: Key.haveDownloadedAllPages)
          userDefaults.removeObject(forKey: Key.currentPageUrl)

          NSLog("finished loading all pages of Pokémon")
        }
      }
    }
    catch {
      NSLog("failed to download Pokémon: \(error.localizedDescription)")
    }
  }
  
  private func createPokemon(from result: Result.AllPokemon) {
    do {
      let context = container.viewContext
      
      for item in result.results {
        let pokemon = pokemon(forName: item.name) ?? Pokemon(context: context)
        
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
  
  private func downloadPokemon(_ pokemon: Pokemon) {
    guard let url = pokemon.url, !pendingUrls.contains(url) else {
      return
    }
    
    pendingUrls.insert(url)
    
    NSLog("starting download of \(url)")
    
    let request = URLRequest(url: url)
    
    let task = URLSession.shared.downloadTask(with: request) {
      _, response, error in self.didDownLoadPokemon(pokemon, from: url, response: response, error: error)
    }
    
    task.resume()
  }
  
  private func didDownLoadPokemon(_ pokemon: Pokemon, from url: URL, response: URLResponse?, error: Error?) {
    do {
      if let error {
        throw error
      }
      
      guard let localUrl = response?.url else {
        throw PersistenceControllerError.noData
      }
      
      let data = try Data(contentsOf: localUrl)
      let result = try JSONDecoder().decode(Result.Pokemon.self, from: data)
      
      DispatchQueue.main.async {
        self.updatePokemon(pokemon, from: result)
        
        NSLog("finished download of \(url)")
        
        self.pendingUrls.remove(url)
      }
    }
    catch {
      NSLog("cannot download Pokémon: \(error.localizedDescription)")
    }
  }
  
  private func updatePokemon(_ pokemon: Pokemon, from result: Result.Pokemon) {
    do {
      let context = container.viewContext
      
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
      
      pokemon.name = result.name
      pokemon.number = Int16(result.id)
      pokemon.height = Int16(result.height)
      pokemon.weight = Int16(result.weight)
      pokemon.order = Int16(result.order)
      pokemon.baseExperience = Int16(result.base_experience)
      
      result.stats.forEach {
        if let statistic = PokemonStatistic.from(name: $0.stat.name) {
          pokemon.setValue(Int16($0.base_stat), forStatistic: statistic)
        }
      }
      
      result.types.forEach {
        if let type = PokemonType.from(name: $0.type.name) {
          pokemon.setType(type, forSlot: $0.slot)
        }
      }
        
      try context.save()
    }
    catch {
      NSLog("cannot save Pokémon: \(error.localizedDescription)")
    }
  }
  
 private func createPokemon(from result: Result.Pokemon) {
    let context = container.viewContext
    let pokemon = pokemon(forName: result.name) ?? Pokemon(context: context)
    
    updatePokemon(pokemon, from: result)
  }
  
  // MARK: - downloading Pokemon image data
  
  private func downloadImage(forPokemon pokemon: Pokemon) {
    guard let url = pokemon.imageUrl, !pendingUrls.contains(url) else {
      return
    }
    
    pendingUrls.insert(url)
    
    NSLog("starting download of \(url)")
    
    let request = URLRequest(url: url)
    
    let task = URLSession.shared.downloadTask(with: request) {
      _, response, error in self.didDownLoadImage(for: pokemon, from: url, response: response, error: error)
    }
    
    task.resume()
  }
  
  private func didDownLoadImage(for pokemon: Pokemon, from url: URL, response: URLResponse?, error: Error?) {
    do {
      guard let localUrl = response?.url else {
        throw PersistenceControllerError.noData
      }
      
      let data = try Data(contentsOf: localUrl)
      
      DispatchQueue.main.async {
        pokemon.imageData = data
        
        do {
          let context = self.container.viewContext
          
          try context.save()
        }
        catch {
          NSLog("cannot save image for Pokémon: \(error.localizedDescription)")
        }

        self.pendingUrls.remove(url)
      }
    }
    catch {
      NSLog("cannot save image for Pokémon: \(error.localizedDescription)")
    }
  }

  // MARK: - previews and sample date
  
  static var preview: PersistenceController = {
    let result = PersistenceController(inMemory: true)
    let viewContext = result.container.viewContext
    
    //result.createPokemon(from: clefairy)
    
    let pokemon = Pokemon(context: viewContext)

    pokemon.number = 35
    pokemon.url = URL(string: "https://pokeapi.co/api/v2/pokemon/35/")
    pokemon.name = "clefairy"

    do {
      try viewContext.save()
    }
    catch {
      NSLog("cannot save: \(error.localizedDescription)")
    }
    
    return result
  }()
  
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
}
