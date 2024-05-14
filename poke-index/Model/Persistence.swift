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
  
  /// Initializes this controller
  /// - Parameter inMemory: whether the underlying container should be constructed in memory only
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
  
  /// Searches for a Pokémon by name. The search is case sensitive and matches complete names.
  /// - Parameter name: the name of the Pokémon.
  /// - Returns: the Pokémon with the given name, `nil` if no such object.
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
  
  /// Searches for a Pokémon by number.
  /// - Parameter number: the number of the Pokémon.
  /// - Returns: the Pokémon with the given number, `nil` if no such object.
  func pokemon(forNumber number: Int16) -> Pokemon? {
    let request = Pokemon.fetchRequest()
    
    request.predicate = NSPredicate(format: "number = %i", number)
    
    do {
      return try container.viewContext.fetch(request).first
    }
    catch {
      NSLog("cannot search Pokémon with name \(number): \(error.localizedDescription)")
      
      return nil
    }
  }
  
  // MARK: - loading all Pokémon
  
  /// Synchronously deletes all Pokémon from the data store.
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
    
    Task.init {
      await downloadPokemon(from: url)
    }
  }
  
  /// Downloads a page of Pokémon from the server.
  /// - Parameter url: the URL used to request the page.
  private func downloadPokemon(from url: URL) async {
    guard !pendingUrls.contains(url) else {
      return
    }
    
    pendingUrls.insert(url)
    
    NSLog("downloading next page of Pokémon from \(url)")
    
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
  
  /// Creates Pokémon objects from a page of Pokémon data. Each result contains only a name and URL; we synthesize a nuber from the URL.
  /// - Parameter result: a page of Pokémon data.
  private func createPokemon(from page: Result.Page) {
    do {
      let context = container.viewContext
      
      for item in page.results {
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
  
  /// Starts the next necessary download for a Pokémon. If the details haven't been downloaded,
  /// the method starts downloading the details. If the Pokémon's image data hasn't been downloaded,
  /// the method starts dowloading said data. Otherwise, nothing is done.
  /// - Parameter pokemon: the Pokémon we might need to dowload.
  func startNextDownload(forPokemon pokemon: Pokemon) {
    if pokemon.imageData == nil {
      if pokemon.imageUrl == nil {
        if !pokemon.hasBeenDownloaded {
          Task.init {
            await self.downloadPokemon(pokemon)
          }
        }
      }
      else {
        Task.init {
          await self.downloadImage(forPokemon: pokemon)
        }
      }
    }
  }
  
  /// Start downloading the details for a Pokémon.
  /// - Parameter pokemon: the Pokémon whose details we need to dowload.
  private func downloadPokemon(_ pokemon: Pokemon) async {
    guard let url = pokemon.url, !pendingUrls.contains(url) else {
      return
    }
    
    pendingUrls.insert(url)
    
    NSLog("starting download of \(url)")
    
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
  
  /// Update a Pokémon with the given result.
  /// - Parameter pokemon: the Pokémon to update.
  /// - Parameter result: the details from the server.
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
  
  // MARK: - downloading Pokemon image data
  
  /// Start downloading the image data for a Pokémon.
  /// - Parameter pokemon: the Pokémon whose image data we need.
  private func downloadImage(forPokemon pokemon: Pokemon) async {
    guard let url = pokemon.imageUrl, !pendingUrls.contains(url) else {
      return
    }
    
    pendingUrls.insert(url)
    
    NSLog("starting download of \(url)")

    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      
      DispatchQueue.main.async {
        self.setImageData(data, forPokemon: pokemon)
        self.pendingUrls.remove(url)
        
        NSLog("finished download of \(url)")
      }
    }
    catch {
      NSLog("cannot download image for Pokémon: \(error.localizedDescription)")
    }
  }
  
  /// Sets the image data for a Pokémon.
  /// - Parameter data: the image data.
  /// - Parameter pokemon: the Pokémon to update.
  private func setImageData(_ data: Data, forPokemon pokemon: Pokemon) {
    pokemon.imageData = data
    
    let context = self.container.viewContext
    
    do {
      try context.save()
    }
    catch {
      NSLog("cannot save image for Pokémon: \(error.localizedDescription)")
    }
  }
}

// MARK: - previews

extension PersistenceController {
  /// An in-memory controller used by previews.
  static var preview: PersistenceController = {
    let result = PersistenceController(inMemory: true)
    let viewContext = result.container.viewContext
    
    result.createPokemon(from: clefairy)
    result.createPokemon(from: zygarde10PowerConstruct)
    
//    let pokemon = Pokemon(context: viewContext)
//
//    pokemon.number = 35
//    pokemon.url = URL(string: "https://pokeapi.co/api/v2/pokemon/35/")
//    pokemon.name = "clefairy"
//
//    do {
//      try viewContext.save()
//    }
//    catch {
//      NSLog("cannot save: \(error.localizedDescription)")
//    }
    
    return result
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
  private func createPokemon(from result: Result.Pokemon) {
    let context = container.viewContext
    let pokemon = pokemon(forName: result.name) ?? Pokemon(context: context)
    
    updatePokemon(pokemon, from: result)
  }
}
