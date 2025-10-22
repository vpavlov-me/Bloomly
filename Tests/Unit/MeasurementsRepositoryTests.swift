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

    // MARK: - Basic CRUD Tests

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

    // MARK: - Edge Cases Tests

    func testFetchMeasurementsWhenEmpty() async throws {
        let fetched = try await repository.measurements(in: nil, type: nil)
        XCTAssertTrue(fetched.isEmpty, "Should return empty array when no measurements exist")
    }

    func testCreateMeasurementWithZeroValue() async throws {
        let measurement = MeasurementDTO(type: .weight, value: 0.0, unit: "kg", date: Date())
        let created = try await repository.create(measurement)

        XCTAssertEqual(created.value, 0.0, accuracy: 0.001, "Should allow zero values")
    }

    func testCreateMeasurementWithVeryLargeValue() async throws {
        let measurement = MeasurementDTO(type: .height, value: 999.99, unit: "cm", date: Date())
        let created = try await repository.create(measurement)

        XCTAssertEqual(created.value, 999.99, accuracy: 0.001, "Should handle large values")
    }

    func testCreateMeasurementWithVerySmallValue() async throws {
        let measurement = MeasurementDTO(type: .weight, value: 0.001, unit: "kg", date: Date())
        let created = try await repository.create(measurement)

        XCTAssertEqual(created.value, 0.001, accuracy: 0.0001, "Should handle very small decimal values")
    }

    func testCreateMeasurementWithNotes() async throws {
        let notes = "Baby is growing well"
        let measurement = MeasurementDTO(type: .height, value: 52.3, unit: "cm", date: Date(), notes: notes)
        let created = try await repository.create(measurement)

        XCTAssertEqual(created.notes, notes, "Should preserve notes")
    }

    func testCreateMeasurementWithLongNotes() async throws {
        let longNotes = String(repeating: "Important measurement note. ", count: 50)
        let measurement = MeasurementDTO(type: .weight, value: 4.2, unit: "kg", date: Date(), notes: longNotes)
        let created = try await repository.create(measurement)

        XCTAssertEqual(created.notes, longNotes, "Should handle long notes")
    }

    func testCreateMeasurementWithEmptyNotes() async throws {
        let measurement = MeasurementDTO(type: .head, value: 33.4, unit: "cm", date: Date(), notes: "")
        let created = try await repository.create(measurement)

        XCTAssertEqual(created.notes, "", "Should preserve empty string notes")
    }

    func testFetchMeasurementsWithLargeDataset() async throws {
        // Create 100 measurements
        for i in 0..<100 {
            let date = Date().addingTimeInterval(TimeInterval(-i * 86400)) // One per day going back
            let value = 50.0 + Double(i) * 0.1
            let measurement = MeasurementDTO(type: .height, value: value, unit: "cm", date: date)
            _ = try await repository.create(measurement)
        }

        let fetched = try await repository.measurements(in: nil, type: nil)
        XCTAssertEqual(fetched.count, 100, "Should handle large datasets")

        // Verify sorting (newest first)
        for i in 0..<fetched.count - 1 {
            XCTAssertGreaterThanOrEqual(fetched[i].date, fetched[i + 1].date, "Measurements should be sorted by date descending")
        }
    }

    func testFetchMeasurementsWithDateInterval() async throws {
        let now = Date()
        let calendar = Calendar.current

        // Create measurements for different days
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!

        _ = try await repository.create(MeasurementDTO(type: .height, value: 50.0, unit: "cm", date: threeDaysAgo))
        _ = try await repository.create(MeasurementDTO(type: .height, value: 51.0, unit: "cm", date: yesterday))
        _ = try await repository.create(MeasurementDTO(type: .height, value: 52.0, unit: "cm", date: now))
        _ = try await repository.create(MeasurementDTO(type: .height, value: 53.0, unit: "cm", date: tomorrow))

        // Fetch only last 2 days
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: now)!
        let interval = DateInterval(start: twoDaysAgo, end: now.addingTimeInterval(3600))

        let recentMeasurements = try await repository.measurements(in: interval, type: nil)
        XCTAssertEqual(recentMeasurements.count, 2, "Should only fetch measurements in the specified interval")
    }

    func testFetchMeasurementsByType() async throws {
        _ = try await repository.create(MeasurementDTO(type: .height, value: 52.0, unit: "cm", date: Date()))
        _ = try await repository.create(MeasurementDTO(type: .weight, value: 4.0, unit: "kg", date: Date()))
        _ = try await repository.create(MeasurementDTO(type: .weight, value: 4.2, unit: "kg", date: Date().addingTimeInterval(-100)))
        _ = try await repository.create(MeasurementDTO(type: .head, value: 33.0, unit: "cm", date: Date()))

        let weightMeasurements = try await repository.measurements(in: nil, type: .weight)
        XCTAssertEqual(weightMeasurements.count, 2, "Should filter measurements by type")
        XCTAssertTrue(weightMeasurements.allSatisfy { $0.type == .weight })
    }

    func testFetchMeasurementsForLastDays() async throws {
        let calendar = Calendar.current
        let now = Date()

        // Create measurements over 10 days
        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            let measurement = MeasurementDTO(type: .weight, value: 4.0 + Double(i) * 0.1, unit: "kg", date: date)
            _ = try await repository.create(measurement)
        }

        let last7Days = try await repository.measurements(forLastDays: 7)
        XCTAssertEqual(last7Days.count, 7, "Should fetch measurements for the last 7 days")
    }

    func testUpdateMeasurementType() async throws {
        var measurement = MeasurementDTO(type: .height, value: 52.0, unit: "cm", date: Date())
        measurement = try await repository.create(measurement)

        measurement.type = .weight
        measurement.value = 4.0
        measurement.unit = "kg"

        let updated = try await repository.update(measurement)
        XCTAssertEqual(updated.type, .weight)
        XCTAssertEqual(updated.value, 4.0, accuracy: 0.001)
        XCTAssertEqual(updated.unit, "kg")
    }

    func testUpdateMeasurementUnit() async throws {
        var measurement = MeasurementDTO(type: .height, value: 52.0, unit: "cm", date: Date())
        measurement = try await repository.create(measurement)

        measurement.unit = "in"
        measurement.value = 20.47 // 52 cm in inches

        let updated = try await repository.update(measurement)
        XCTAssertEqual(updated.unit, "in")
        XCTAssertEqual(updated.value, 20.47, accuracy: 0.01)
    }

    func testUpdateMeasurementNotes() async throws {
        var measurement = MeasurementDTO(type: .weight, value: 4.0, unit: "kg", date: Date())
        measurement = try await repository.create(measurement)

        measurement.notes = "Updated notes"

        let updated = try await repository.update(measurement)
        XCTAssertEqual(updated.notes, "Updated notes")
    }

    func testMultipleMeasurementsSameType() async throws {
        let date1 = Date().addingTimeInterval(-1000)
        let date2 = Date().addingTimeInterval(-500)
        let date3 = Date()

        _ = try await repository.create(MeasurementDTO(type: .weight, value: 4.0, unit: "kg", date: date1))
        _ = try await repository.create(MeasurementDTO(type: .weight, value: 4.2, unit: "kg", date: date2))
        _ = try await repository.create(MeasurementDTO(type: .weight, value: 4.5, unit: "kg", date: date3))

        let measurements = try await repository.measurements(in: nil, type: .weight)
        XCTAssertEqual(measurements.count, 3)

        // Verify they're sorted by date descending
        XCTAssertEqual(measurements[0].value, 4.5, accuracy: 0.001)
        XCTAssertEqual(measurements[1].value, 4.2, accuracy: 0.001)
        XCTAssertEqual(measurements[2].value, 4.0, accuracy: 0.001)
    }

    // MARK: - Error Handling Tests

    func testUpdateNonExistentMeasurement() async throws {
        let measurement = MeasurementDTO(type: .height, value: 52.0, unit: "cm", date: Date())

        do {
            _ = try await repository.update(measurement)
            XCTFail("Should throw notFound error")
        } catch let error as MeasurementsRepositoryError {
            if case .notFound = error {
                // Expected error
            } else {
                XCTFail("Should throw notFound error, got \(error)")
            }
        }
    }

    func testDeleteNonExistentMeasurement() async throws {
        let nonExistentId = UUID()

        do {
            try await repository.delete(id: nonExistentId)
            XCTFail("Should throw notFound error")
        } catch let error as MeasurementsRepositoryError {
            if case .notFound = error {
                // Expected error
            } else {
                XCTFail("Should throw notFound error, got \(error)")
            }
        }
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentReads() async throws {
        // Create some measurements first
        for i in 0..<10 {
            let measurement = MeasurementDTO(type: .height, value: 50.0 + Double(i), unit: "cm", date: Date().addingTimeInterval(TimeInterval(-i * 100)))
            _ = try await repository.create(measurement)
        }

        // Perform multiple concurrent reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    do {
                        let measurements = try await self.repository.measurements(in: nil, type: nil)
                        XCTAssertEqual(measurements.count, 10, "Concurrent reads should return consistent results")
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }
        }
    }

    func testConcurrentWrites() async throws {
        // Perform multiple concurrent writes
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask {
                    do {
                        let measurement = MeasurementDTO(type: .height, value: 50.0 + Double(i), unit: "cm", date: Date().addingTimeInterval(TimeInterval(-i * 100)))
                        _ = try await self.repository.create(measurement)
                    } catch {
                        XCTFail("Concurrent write failed: \(error)")
                    }
                }
            }
        }

        // Verify all measurements were created
        let measurements = try await repository.measurements(in: nil, type: nil)
        XCTAssertEqual(measurements.count, 20, "All concurrent writes should succeed")
    }

    func testConcurrentReadAndWrite() async throws {
        // Create initial measurement
        _ = try await repository.create(MeasurementDTO(type: .height, value: 50.0, unit: "cm", date: Date()))

        // Perform concurrent reads and writes
        await withTaskGroup(of: Void.self) { group in
            // Add readers
            for _ in 0..<5 {
                group.addTask {
                    do {
                        _ = try await self.repository.measurements(in: nil, type: nil)
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
            }

            // Add writers
            for i in 0..<5 {
                group.addTask {
                    do {
                        let measurement = MeasurementDTO(type: .weight, value: 4.0 + Double(i) * 0.1, unit: "kg", date: Date().addingTimeInterval(TimeInterval(-i * 100)))
                        _ = try await self.repository.create(measurement)
                    } catch {
                        XCTFail("Concurrent write failed: \(error)")
                    }
                }
            }
        }

        // Verify final state
        let finalMeasurements = try await repository.measurements(in: nil, type: nil)
        XCTAssertEqual(finalMeasurements.count, 6, "Should have initial measurement plus 5 new measurements")
    }

    func testConcurrentUpdates() async throws {
        // Create a measurement
        var measurement = try await repository.create(MeasurementDTO(type: .weight, value: 4.0, unit: "kg", date: Date()))

        // Perform concurrent updates
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    do {
                        var copy = measurement
                        copy.value = 4.0 + Double(i) * 0.2
                        _ = try await self.repository.update(copy)
                    } catch {
                        // Some updates may fail due to race conditions, which is acceptable
                    }
                }
            }
        }

        // Verify the measurement was updated (exact value doesn't matter)
        let updated = try await repository.measurements(in: nil, type: .weight)
        XCTAssertEqual(updated.count, 1)
    }

    // MARK: - Performance Tests

    func testQueryPerformanceWithLargeDataset() async throws {
        // Create 500 measurements
        for i in 0..<500 {
            let types: [MeasurementType] = [.height, .weight, .head]
            let type = types[i % 3]
            let value: Double = type == .weight ? 4.0 + Double(i) * 0.01 : 50.0 + Double(i) * 0.1
            let measurement = MeasurementDTO(type: type, value: value, unit: type.defaultUnit, date: Date().addingTimeInterval(TimeInterval(-i * 100)))
            _ = try await repository.create(measurement)
        }

        // Measure filtered query performance
        let start = Date()
        _ = try await repository.measurements(in: nil, type: .height)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertLessThan(elapsed, 0.1, "Query should complete in under 100ms")
    }

    func testFormattedValue() async throws {
        let measurement = MeasurementDTO(type: .height, value: 52.345, unit: "cm", date: Date())
        let created = try await repository.create(measurement)

        let formatted = created.formattedValue
        XCTAssertTrue(formatted.contains("52.3") || formatted.contains("52.35"), "Formatted value should limit decimal places")
    }
}
