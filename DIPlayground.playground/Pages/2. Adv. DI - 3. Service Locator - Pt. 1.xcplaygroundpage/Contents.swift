import Foundation
import UIKit

public protocol Resolver {
    func resolve<T>(_ metaType: T.Type) -> T
    func autoResolve<T>() -> T
}

public protocol Container {
    func register<T>(instance: T, forMetaType metaType: T.Type)
    func register<T>(
        factory: @escaping (Resolver) -> T,
        forMetaType metaType: T.Type
    )
}
extension Container {
    func register<T>(
        factory: @escaping () -> T,
        forMetaType metaType: T.Type
    ) {
        self.register(
            factory: { _ in factory() },
            forMetaType: metaType
        )
    }
}

public typealias ServiceLocatorInterface = Resolver & Container
public final class ServiceLocator {
    public static let shared: ServiceLocatorInterface = ServiceLocator()
    
    var instances: [String: Any] = [:]
    var lazyInstances: NSMapTable<NSString, LazyInstanceWrapper> = .init(
        keyOptions: .strongMemory,
        valueOptions: .weakMemory
    )
    
    typealias LazyDependencyFactory = () -> Any
    var factories: [String: LazyDependencyFactory] = [:]
    
    final class LazyInstanceWrapper {
        let instance: Any
        init(instance: Any) {
            self.instance = instance
        }
    }
    
    private func getKey<T>(for metaType: T.Type) -> String {
        let key = String(describing: T.self)
        return key
    }
}

extension ServiceLocator: Container {
    public func register<T>(instance: T, forMetaType metaType: T.Type
    ) {
        let key = getKey(for: metaType)
        guard instances[key] == nil else {
            fatalError("You must not register something twice!")
        }
        instances[key] = instance
    }
    
    public func register<T>(factory: @escaping (Resolver) -> T, forMetaType metaType: T.Type) {
        let key = getKey(for: metaType)
        guard factories[key] == nil else {
            fatalError("You must not register something twice!")
        }
        factories[key] = { factory(self) }
    }
}

extension ServiceLocator: Resolver {
    public func resolve<T>(_ metaType: T.Type) -> T {
        guard let instance = getInstance(forMetatype: T.self) else {
            fatalError("There is no instance registered for `\(getKey(for: T.self))`!")
        }
        return instance
    }
    
    public func autoResolve<T>() -> T {
        guard let instance = getInstance(forMetatype: T.self) else {
            fatalError("There is no instance registered for `\(getKey(for: T.self))`!")
        }
        return instance
    }
}

extension ServiceLocator {
    private func getInstance<T>(forMetatype: T.Type) -> T? {
        let key = getKey(for: T.self)
        if let instance = instances[key] as? T {
            return instance
        } else if let lazyInstance = getLazyInstance(for: T.self, key: key)  {
            return lazyInstance
        } else {
            return nil
        }
    }
    
    private func getLazyInstance<T>(for _: T.Type, key: String) -> T? {
        let objectKey = key as NSString
        
        if let instanceInMemory = lazyInstances.object(forKey: objectKey)?.instance as? T {
            return instanceInMemory
        }
        
        guard
            let factory: LazyDependencyFactory = factories[key],
            let newInstance = factory() as? T
        else { return nil }
        
        let wrappedInstance = LazyInstanceWrapper(instance: newInstance)
        lazyInstances.setObject(wrappedInstance, forKey: objectKey)
        
        return newInstance
    }
}

protocol LoginServiceProtocol { /* ... */ }
struct LoginService: LoginServiceProtocol {
    private let urlSession: URLSession
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
}

protocol UserSessionProtocol { /* ... */ }
final class UserSession: UserSessionProtocol {
    init() {}
}

final class AppDelegate /*: UIResponder, UIApplicationDelegate */ {
    var serviceLocator: ServiceLocatorInterface = ServiceLocator.shared
    func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        registerDependencies()
        return true
    }

    private func registerDependencies() {
        serviceLocator.register(instance: URLSession.shared, forMetaType: URLSession.self)
        serviceLocator.register(
            factory: { resolver in
                let session: URLSession = resolver.autoResolve()
                return LoginService(urlSession: session)
            },
            forMetaType: LoginServiceProtocol.self
        )
        serviceLocator.register(
            factory: UserSession.init,
            forMetaType: UserSessionProtocol.self
        )
    }
}

final class LoginViewModel {
    private let loginService: LoginServiceProtocol
    private let userSession: UserSessionProtocol

    init(
        loginService: LoginServiceProtocol? = nil,
        userSession: UserSessionProtocol? = nil
    ) {
        // if you don't want to expose the ServiceLocator...
        self.loginService = loginService ?? ServiceLocator.shared.autoResolve()
        self.userSession = userSession ?? ServiceLocator.shared.resolve(UserSessionProtocol.self)
    }

    // ...
}

// Or

final class OtherLoginViewModel {
    private let loginService: LoginServiceProtocol
    private let userSession: UserSessionProtocol

    // If you don't mind exposing it...
    init(
        loginService: LoginServiceProtocol = ServiceLocator.shared.autoResolve(),
        userSession: UserSessionProtocol = ServiceLocator.shared.resolve(UserSessionProtocol.self)
    ) {
        self.loginService = loginService
        self.userSession = userSession
    }

    // ...
}

