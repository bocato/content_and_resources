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

protocol HasPokemonsService {
    var pokemonsService: PokemonsServiceProtocol { get }
}

protocol HasTradingManager {
    var tradingManager: TradingManagerProtocol { get }
}

protocol AppDependenciesContainer: HasPokemonsService, HasTradingManager {}

final class AppDependenciesEnvironment: AppDependenciesContainer {
    private static var sharedInstance: AppDependenciesContainer?
    static var shared: AppDependenciesContainer {
        guard let instance = sharedInstance else { fatalError("You should call `initialize` once!") }
        return instance
    }
    
    private(set) var pokemonsService: PokemonsServiceProtocol
    private(set) var tradingManager: TradingManagerProtocol
    
    private init(
        pokemonsService: PokemonsServiceProtocol,
        tradingManager: TradingManagerProtocol
    ) {
        self.pokemonsService = pokemonsService
        self.tradingManager = tradingManager
    }
    
    static func initialize(
        pokemonsService: PokemonsServiceProtocol = PokemonsService(),
        tradingManager: TradingManagerProtocol = TradingManager()
    ) {
        guard sharedInstance == nil else {
            fatalError("`initialize` should not be called more than once.")
        }
        Self.sharedInstance = AppDependenciesEnvironment(
            pokemonsService: pokemonsService,
            tradingManager: tradingManager
        )
    }
}

protocol ViewControllersFactoryProtocol {
    func makePokemonTradeViewController(for pokemonIWant: Pokemon, userToTradeWithID: String) -> UIViewController
}

struct ViewControllersFactory: ViewControllersFactoryProtocol {
    typealias Dependencies = HasPokemonsService & HasTradingManager
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies = AppDependenciesEnvironment.shared) {
        self.dependencies = dependencies
    }
    
    func makePokemonTradeViewController(for pokemonIWant: Pokemon, userToTradeWithID: String) -> UIViewController {
        let viewController: PokemonTradeViewController = .init(
            pokemonIWant: pokemonIWant,
            userToTradeWithID: userToTradeWithID,
            tradingManager: dependencies.tradingManager,
            pokemonsService: dependencies.pokemonsService
        )
        return viewController
    }
}

final class PokemonListViewController: UITableViewController {
    // MARK: - Dependencies
    
    private let pokemonsService: PokemonsServiceProtocol
    private let userToTradeWithID: String
    private let viewControllersFactory: ViewControllersFactoryProtocol
    
    // MARK: - Properties
    
    private var pokemons: [Pokemon] = []
    
    // MARK: - Initialization

    init(
        pokemonsService: PokemonsServiceProtocol,
        userToTradeWithID: String,
        viewControllersFactory: ViewControllersFactoryProtocol
    ) {
        self.pokemonsService = pokemonsService
        self.userToTradeWithID = userToTradeWithID
        self.viewControllersFactory = viewControllersFactory
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
        let tradeViewController = viewControllersFactory.makePokemonTradeViewController(
            for: pokemonIWant,
            userToTradeWithID: userToTradeWithID
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
