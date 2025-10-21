import CoreData
import XCTest
@testable import BabyTrack
@testable import Measurements

final class MeasurementsRepositoryTests: XCTestCase {
    private var persistence: PersistenceController!
    private var repository: CoreDataMeasurementsRepository!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        repository = CoreDataMeasurementsRepository(context: persistence.viewContext)
    }

    override func tearDown() {
        persistence = nil
        repository = nil
        super.tearDown()
    }

    func testCreateMeasurement() async throws {
        let measurement = MeasurementDTO(type: .height, value: 52.3, unit: "cm", date: Date())
        let created = try await repository.create(measurement)
        XCTAssertEqual(created.value, 52.3, accuracy: 0.001)

        let fetched = try await repository.measurements(in: nil, type: .height)
        XCTAssertEqual(fetched.count, 1)
    }

    func testUpdateMeasurement() async throws {
        var measurement = MeasurementDTO(type: .weight, value: 4.2, unit: "kg", date: Date())
        measurement = try await repository.create(measurement)
        measurement.value = 4.4

        let updated = try await repository.update(measurement)
        XCTAssertEqual(updated.value, 4.4, accuracy: 0.001)
    }

    func testDeleteMeasurement() async throws {
        let measurement = MeasurementDTO(type: .head, value: 33.4, unit: "cm", date: Date())
        let created = try await repository.create(measurement)
        try await repository.delete(id: created.id)

        let all = try await repository.measurements(in: nil, type: nil)
        XCTAssertTrue(all.isEmpty)
    }
}
