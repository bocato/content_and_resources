import Foundation
import UIKit

struct Pokemon {
    let id: String
    let name: String
}

protocol PokemonsServiceProtocol {
    func loadPokemons(
        for userID: String,
        then completion: @escaping (Result<[Pokemon], Error>) -> Void
    )
}

final class PokemonsService: PokemonsServiceProtocol {
    func loadPokemons(
        for userID: String,
        then completion: @escaping (Result<[Pokemon], Error>) -> Void
    ) { /* ... */ }
}

protocol TradingManagerProtocol {
    func exchange(
        myPokemon: Pokemon,
        for otherPokemon: Pokemon,
        with userID: String,
        then completion: @escaping (Result<Void, Error>) -> Void
    )
}

final class TradingManager: TradingManagerProtocol {
    func exchange(
        myPokemon: Pokemon,
        for otherPokemon: Pokemon,
        with userID: String,
        then completion: @escaping (Result<Void, Error>) -> Void
    ) { /* ... */ }
}

final class PokemonListViewController: UITableViewController {
    // MARK: - Dependencies
    
    private let userToTradeWithID: String
    private let pokemonsService: PokemonsServiceProtocol
    
    // MARK: - Properties
    
    private var pokemons: [Pokemon] = []
    
    // MARK: - Initialization

    init(
        userToTradeWithID: String,
        pokemonsService: PokemonsServiceProtocol
    ) {
        self.userToTradeWithID = userToTradeWithID
        self.pokemonsService = pokemonsService
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Lifecycle

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pokemonsService.loadPokemons(for: userToTradeWithID) { [weak self] result in
            do {
                let pokemons = try result.get()
                self?.reloadTableView(with: pokemons)
            } catch { print(error) }
        }
    }
}
extension PokemonListViewController {
    // MARK: - Private API
    
    private func reloadTableView(with pokemons: [Pokemon]) { /* ... */ }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pokemonIWant = pokemons[indexPath.row]
        let tradeViewController: PokemonTradeViewController = .init(
            pokemonIWant: pokemonIWant,
            userToTradeWithID: userToTradeWithID,
            tradingManager: TradingManager(),
            pokemonsService: pokemonsService
        )
        navigationController?.pushViewController(tradeViewController, animated: true)
    }
}

final class PokemonTradeViewController: UIViewController {
    // MARK: - Dependencies
    
    private let pokemonIWant: Pokemon
    private let userToTradeWithID: String
    private let tradingManager: TradingManagerProtocol
    private let pokemonsService: PokemonsServiceProtocol
    
    // MARK: - Initialization

    init(
        pokemonIWant: Pokemon,
        userToTradeWithID: String,
        tradingManager: TradingManagerProtocol,
        pokemonsService: PokemonsServiceProtocol
    ) {
        self.pokemonIWant = pokemonIWant
        self.userToTradeWithID = userToTradeWithID
        self.tradingManager = tradingManager
        self.pokemonsService = pokemonsService
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Lifecycle

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
