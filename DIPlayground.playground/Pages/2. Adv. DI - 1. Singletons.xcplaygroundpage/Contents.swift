import Foundation

// MARK: - Common Singleton Implementation

struct LoggedUser {
    let id: String
    let username: String
    let token: String
}

struct LoginResponse {
    let id: String
    let token: String
}

final class UserSesssion {
    static let shared = UserSesssion()
    
    private(set) var currentUser: LoggedUser?
    var isValid: Bool { currentUser?.token.isEmpty == false }
    
    private init() {}
    
    func login(
        username: String,
        password: String,
        then completion: @escaping (Result<Void, Error>) -> Void
    ) {
        dispatchLoginRequest(username: username, password: password) { [weak self] result in
            do {
                let response = try result.get()
                self?.currentUser = .init(id: response.id, username: username, token: response.token)
                completion(.success(()))
            } catch {
                self?.currentUser = nil
                completion(.failure(error))
            }
        }
    }
    
    private func dispatchLoginRequest(
        username: String,
        password: String,
        then completion: @escaping (Result<LoginResponse, Error>) -> Void
    ) { /* ... */ }
}

// Making it testable...
protocol UserSesssionProtocol {
    var currentUser: LoggedUser? { get }
    var isValid: Bool { get }
    func login(
        username: String,
        password: String,
        then completion: @escaping (Result<Void, Error>) -> Void
    )
}
extension UserSesssion: UserSesssionProtocol {}

final class SomeViewModelThatNeedsUserSession {
    let userSession: UserSesssionProtocol
    init(userSession: UserSesssionProtocol) {
        self.userSession = userSession
    }
}

// MARK: - Exemple: AppDependencies

protocol HasURLSession {
    var urlSession: URLSession { get }
}

protocol HasUserDefaults {
    var userDefaults: UserDefaults { get }
}

protocol HasUserSession {
    var userSession: UserSesssionProtocol { get }
}

protocol AppDependenciesContainer: HasURLSession, HasUserDefaults, HasUserSession  {}

final class AppDependenciesEnvironment: AppDependenciesContainer {
    static let shared = AppDependenciesEnvironment()
    
    private(set) var urlSession: URLSession
    private(set) var userDefaults: UserDefaults
    private(set) var userSession: UserSesssionProtocol
    
    private init() {
        self.urlSession = .shared
        self.userDefaults = .standard
        self.userSession = UserSesssion.shared
    }
}

final class SomeViewModel {
    typealias Dependencies = HasUserSession & HasUserDefaults
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies = AppDependenciesEnvironment.shared) {
        self.dependencies = dependencies
    }
}

// MARK: - Example: Singleton + or Singleton Extended

open class PersistencyManager {
    // MARK: - Single Instance
    static let shared = PersistencyManager(userDefaults: .standard)
    
    // MARK: - Dependencies
    
    private let userDefaults: UserDefaults
    
    // MARK: - Public Properties
    
    private(set) var values: [String] = []
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Public Functions
    
    func save(_ value: String) -> Bool {
        var newValues = values
        newValues.append(value)
        userDefaults.set(value, forKey: "valuesKey")
        
        let sincronizationSucceeded = userDefaults.synchronize()
        if sincronizationSucceeded { values = newValues }
        return sincronizationSucceeded
    }
    /* ... */
}

import XCTest

final class DefaultsManagerTests: XCTestCase {
    func test_whenAddIsCalled_userDefaultsShouldReceiveValue_andSyncronize() {
        // Given
        let userDefaultsSpy = UserDefaultsSpy()
        let sut = PersistencyManager(
            userDefaults: userDefaultsSpy
        )
        let valueToAdd = "some value"
        // When
        let addSucceeded = sut.save(valueToAdd)
        // Then
        XCTAssertTrue(addSucceeded)
        XCTAssertTrue(userDefaultsSpy.setValueCalled)
        XCTAssertEqual(1, sut.values.count)
        XCTAssertTrue(userDefaultsSpy.synchronizeCalled)
    }

}

final class UserDefaultsSpy: UserDefaults {
    private(set) var setValueCalled = false
    private(set) var setValuePassed: Any?
    private(set) var setValueKeyPassed: String?

    override func set(_ value: Any?, forKey defaultName: String) {
        setValueCalled = true
        setValuePassed = value
        setValueKeyPassed = defaultName
    }

    private(set) var synchronizeCalled = false
    override func synchronize() -> Bool {
        synchronizeCalled = true
        return true
    }
}

DefaultsManagerTests.defaultTestSuite.run()




