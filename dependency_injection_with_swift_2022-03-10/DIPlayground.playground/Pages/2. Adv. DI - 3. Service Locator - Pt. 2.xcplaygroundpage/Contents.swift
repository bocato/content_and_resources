import Foundation

// MARK: - Property Wrappers Example
@propertyWrapper
struct Capitalized {
    var wrappedValue: String {
        didSet { wrappedValue = wrappedValue.capitalized }
    }

    init(wrappedValue: String) {
        self.wrappedValue = wrappedValue.capitalized
    }
}

struct User {
    @Capitalized var firstName: String
    @Capitalized var lastName: String
}

// Example
var user = User(firstName: "eduardo", lastName: "bocato")
print(user.firstName, user.lastName)

// John Sundell
user.lastName = "sundell"


// MARK: - Changes to the ServiceLocator

public protocol Resolver {
    func resolve<T>(_ metaType: T.Type) -> T?
    func autoResolve<T>() -> T?
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
    public func register<T>(instance: T, forMetaType metaType: T.Type) {
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
    public func resolve<T>(_ metaType: T.Type) -> T? {
        getInstance(forMetatype: T.self)
    }
    
    public func autoResolve<T>() -> T? {
        getInstance(forMetatype: T.self)
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

// MARK: - Making DI pretty

@propertyWrapper
public final class Dependency<T> {
    // MARK: - Dependencies
    
    private let resolver: Resolver?
    private let failureHandler: (String) -> Void
    private(set) var resolvedValue: T!

    // MARK: - Properties
    
    public var wrappedValue: T {
        resolveIfNeeded()
        return resolvedValue!
    }

    // MARK: - Initialization
    
    public convenience init() {
        self.init(
            resolvedValue: nil,
            resolver: ServiceLocator.shared,
            failureHandler: { preconditionFailure($0) }
        )
    }

    fileprivate init(
        resolvedValue: T?,
        resolver: Resolver?,
        failureHandler: @escaping (String) -> Void
    ) {
        self.resolvedValue = resolvedValue
        self.resolver = resolver
        self.failureHandler = failureHandler
    }

    // MARK: - Private Functions
    
    private func resolveIfNeeded() {
        guard resolvedValue == nil else {
            failureHandler("\(type(of: self)) shouldn't be resolved twice!")
            return
        }
        guard let instanceFromContainer = resolver?.resolve(T.self) else {
            failureHandler("Could not resolve \(type(of: self)), check it it was registered!")
            return
        }
        resolvedValue = instanceFromContainer
    }
}

protocol LoginServiceProtocol { /* ... */ }
final class LoginService: LoginServiceProtocol {
    init() {}
}

protocol UserSessionProtocol { /* ... */ }
final class UserSession: UserSessionProtocol {
    init() {}
}

final class ViewModelWithoutPropertyWrappers {
    private let loginService: LoginServiceProtocol
    private let userSession: UserSessionProtocol

    init(
        loginService: LoginServiceProtocol? = nil,
        userSession: UserSessionProtocol? = nil
    ) {
        self.loginService = loginService ?? ServiceLocator.shared.autoResolve()!
        self.userSession = userSession ?? ServiceLocator.shared.resolve(UserSessionProtocol.self)!
    }

    // ...
}

final class ViewModelWithPropertyWrappers {
    @Dependency var loginService: LoginServiceProtocol
    @Dependency var userSession: UserSessionProtocol
    // ...
}

// Making it testable...
//#if DEBUG
extension Dependency {
    // To enable testing @Dependency
    convenience init(resolver: Resolver, failureHandler: @escaping (String) -> Void) {
        self.init(resolvedValue: nil, resolver: resolver, failureHandler: failureHandler)
    }
    
    // To enable mocking from outside
    static func resolved(_ value: T) -> Self {
        .init(resolvedValue: value, resolver: nil, failureHandler: { _ in })
    }
}
//#endif

struct LoginViewEnvironment {
    @Dependency var loginService: LoginServiceProtocol
    @Dependency var userSession: UserSessionProtocol
}

final class LoginViewModel {
    private let environment: LoginViewEnvironment
    init(environment: LoginViewEnvironment) {
        self.environment = environment
    }
    // ...
}

//#if DEBUG
extension LoginViewEnvironment {
    static func mocking(
        loginService: LoginServiceProtocol,
        userSession: UserSessionProtocol
    ) -> Self {
        .init(
            loginService: .resolved(loginService),
            userSession: .resolved(userSession)
        )
    }
}
//#endif

import XCTest

struct LoginServiceMock: LoginServiceProtocol {}
struct UserSessionMock: UserSessionProtocol {}

final class LoginViewModelTests: XCTestCase {
    func test_something() {
        // Given
        let sut: LoginViewModel = .init(
            environment: .mocking(
                loginService: LoginServiceMock(),
                userSession: UserSessionMock()
            )
        )
        _ = sut // ... Test your stuff!
    }
}
