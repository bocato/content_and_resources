import XCTest
import UIKit

// MARK: - Implementation

protocol NetworkProtocol {
    func getData(from url: URL, completion: (Result<Data?, Error>) -> Void)
}

final class Network: NetworkProtocol {
    static let shared = Network()
    func getData(from url: URL, completion: (Result<Data?, Error>) -> Void) { /* ... */ }
}

extension UIImageView {
    func setImageFromURL(
        _ url: URL,
        network: NetworkProtocol = Network.shared,
        mainQueue: DispatchQueue = .main
    ) {
        network.getData(from: url) { result in
            guard
                let data = try? result.get(),
                let remoteImage = UIImage(data: data)
            else { return }
            mainQueue.async { self.image = remoteImage }
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

final class UIImageViewTests: XCTestCase {
    func test_whenDataIsValid_thenItShouldReturnTheExpectedImage() throws {
        // Given
        
        let imageMock: UIImage = .add
        let imageDataMock = try XCTUnwrap(imageMock.pngData())
        
        let networkStub: NetworkStub = .init()
        networkStub.getDataResultToBeReturned = .success(imageDataMock)
        
        let sut: UIImageView = .init()
        
        let dummyURL: URL = try XCTUnwrap(.init(string: "www.something.com/image.png"))
        
        // When
        sut.setImageFromURL(dummyURL, network: networkStub, mainQueue: .global())
        
        // Then
        XCTAssertNotNil(sut.image)
    }
}

UIImageViewTests.defaultTestSuite.run()
