import Testing
import HealthKit
@testable import HealthQL

@Suite("HealthStoreProtocol Tests")
struct HealthStoreProtocolTests {

    @Test("MockHealthStore can be created")
    func mockHealthStoreCreation() {
        let mock = MockHealthStore()
        #expect(mock != nil)
    }

    @Test("MockHealthStore can provide canned samples")
    func mockHealthStoreWithSamples() {
        let samples: [HKSample] = []
        let mock = MockHealthStore(samples: samples)
        #expect(mock.samples.isEmpty)
    }

    @Test("HKHealthStore conforms to protocol")
    func hkHealthStoreConformance() {
        // This test verifies the extension exists
        let store: any HealthStoreProtocol = HKHealthStore()
        #expect(store != nil)
    }
}
