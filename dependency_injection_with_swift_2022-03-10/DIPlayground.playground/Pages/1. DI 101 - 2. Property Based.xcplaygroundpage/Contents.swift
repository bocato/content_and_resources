import XCTest
import Foundation

// MARK: - Implementation

protocol NetworkProtocol {
    func getData(from url: URL, completion: (Result<Data?, Error>) -> Void)
}

final class Network: NetworkProtocol {
    static let shared = Network()
    func getData(from url: URL, completion: (Result<Data?, Error>) -> Void) { /* ... */ }
}

final class ViewController: UIViewController {
    var network: NetworkProtocol = Network.shared
    
    init() { super.init(nibName: "", bundle: .main) } // just to make it compile
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
    }
    
    func loadData() {
        network.getData(from: URL(string: "www.someapi.com/userdata")!) { result in
            /* ... */
        }
    }
}

// MARK: - Tests

import XCTest

final class NetworkSpy: NetworkProtocol {
    private(set) var getDataCalled = false
    func getData(from url: URL, completion: (Result<Data?, Error>) -> Void) {
        getDataCalled = true
    }
}

final class ViewControllerTests: XCTestCase {
    func test_networkIsCalled() {
        // Given
        let sut: ViewController = .init() // in real live, this can be different
        
        let networkSpy: NetworkSpy = .init()
        sut.network = networkSpy
        
        // When
        sut.loadData()
        
        // Then
        XCTAssertTrue(networkSpy.getDataCalled)
    }
}

ViewControllerTests.defaultTestSuite.run() // Run the tests







