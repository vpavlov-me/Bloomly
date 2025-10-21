import XCTest
@testable import BabyTrack
@testable import Tracking
@testable import Measurements

@MainActor
final class DataExportServiceTests: XCTestCase {
    private var persistence: PersistenceController!
    private var eventsRepository: CoreDataEventsRepository!
    private var measurementsRepository: CoreDataMeasurementsRepository!
    private var exportService: DataExportService!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        eventsRepository = CoreDataEventsRepository(context: persistence.viewContext)
        measurementsRepository = CoreDataMeasurementsRepository(context: persistence.viewContext)
        exportService = DataExportService(
            eventsRepository: eventsRepository,
            measurementsRepository: measurementsRepository
        )
    }

    override func tearDown() {
        persistence = nil
        eventsRepository = nil
        measurementsRepository = nil
        exportService = nil
        super.tearDown()
    }

    func testExportToCSV() async throws {
        // Create test data
        let event = EventDTO(kind: .sleep, start: Date(), end: Date().addingTimeInterval(1800))
        _ = try await eventsRepository.create(event)

        let measurement = MeasurementDTO(type: .height, value: 50.0, unit: "cm", date: Date())
        _ = try await measurementsRepository.create(measurement)

        // Export to CSV
        let fileURL = try await exportService.exportToCSV(dateRange: nil)

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        // Read and verify contents
        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(contents.contains("EVENTS"))
        XCTAssertTrue(contents.contains("MEASUREMENTS"))
        XCTAssertTrue(contents.contains("sleep"))
        XCTAssertTrue(contents.contains("height"))
    }

    func testExportToJSON() async throws {
        // Create test data
        let event = EventDTO(kind: .feed, start: Date(), end: Date().addingTimeInterval(1200))
        _ = try await eventsRepository.create(event)

        let measurement = MeasurementDTO(type: .weight, value: 5.2, unit: "kg", date: Date())
        _ = try await measurementsRepository.create(measurement)

        // Export to JSON
        let fileURL = try await exportService.exportToJSON(dateRange: nil)

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        // Read and verify JSON structure
        let data = try Data(contentsOf: fileURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["events"])
        XCTAssertNotNil(json?["measurements"])
        XCTAssertNotNil(json?["exportDate"])
    }

    func testExportEmptyData() async throws {
        // Export without any data
        let fileURL = try await exportService.exportToCSV(dateRange: nil)

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))

        let contents = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(contents.contains("EVENTS"))
        XCTAssertTrue(contents.contains("MEASUREMENTS"))
    }
}
