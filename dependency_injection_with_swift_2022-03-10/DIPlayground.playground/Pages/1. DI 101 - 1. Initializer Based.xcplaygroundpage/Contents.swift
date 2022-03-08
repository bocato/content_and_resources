import Foundation

// MARK: - Implementation

protocol NetworkProtocol {
    func getData(from url: URL, completion: (Result<Data?, Error>) -> Void)
}

final class Network: NetworkProtocol {
    static let shared = Network()
    func getData(from url: URL, completion: (Result<Data?, Error>) -> Void) { /* ... */ }
}

struct User: Codable {
    let name: String /* ... */
}

final class UserService {
    private let network: NetworkProtocol
    private let jsonDecoder: JSONDecoder
    
    init(network: NetworkProtocol = Network.shared, jsonDecoder: JSONDecoder = .init()) {
        self.network = network
        self.jsonDecoder = jsonDecoder
    }
    
    func getUserData(_ completion: @escaping (Result<User, Error>) -> Void) {
        let userServiceURL = URL(string: "www.someapi.com/userdata")!
        network.getData(from: userServiceURL) { [jsonDecoder] result in
            guard
                let data = try? result.get(),
                let user = try? jsonDecoder.decode(User.self, from: data)
            else {
                completion(.failure(NSError(domain: "UserService", code: -999, userInfo: nil)))
                return
            }
            completion(.success(user))
        }
    }
}

// MARK: - Tests

import XCTest

final class NetworkStub: NetworkProtocol {
    var getDataResultToBeReturned: Result<Data?, Error> = .success(Data())
    func getData(from url: URL, completion: (Result<Data?, Error>) -> Void) {
        completion(getDataResultToBeReturned)
    }
}

extension User {
    func asData(using encoder: JSONEncoder = .init()) -> Data? {
        try? encoder.encode(self)
    }
}

final class UserServiceTests: XCTestCase {
    func test_getUser_whenDataIsValid_thenItWillReturnSomeUser() throws {
        // Given
        let userMock: User = .init(name: "Random User")
        let userDataMock: Data = try XCTUnwrap(userMock.asData())
        
        let networkStub: NetworkStub = .init()
        networkStub.getDataResultToBeReturned = .success(userDataMock)
        
        let sut = UserService(network: networkStub)
        
        // When
        var userReturned: User?
        let getUserDataExpectation = expectation(description: "UserService.getUserData was called.")
        sut.getUserData { result in
            userReturned = try? result.get()
            getUserDataExpectation.fulfill()
        }
        
        // Then
        wait(for: [getUserDataExpectation], timeout: 1.0)
        XCTAssertNotNil(userReturned)
    }
}

UserServiceTests.defaultTestSuite.run() // Run the tests
