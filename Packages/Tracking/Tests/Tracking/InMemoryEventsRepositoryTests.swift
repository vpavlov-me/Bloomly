import XCTest
@testable import Tracking

final class InMemoryEventsRepositoryTests: XCTestCase {
    func testEventDraftProducesDTO() {
        let start = Date()
        let draft = EventDraft(kind: .feeding, start: start, notes: "120ml")

        let dto = draft.makeDTO()

        XCTAssertEqual(dto.kind, .feed)
        XCTAssertEqual(dto.start.timeIntervalSince1970, start.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(dto.notes, "120ml")
    }

    func testInMemoryRepositoryStoresAndFetchesEvents() async throws {
        let repository = InMemoryEventsRepository()
        let dto = EventDraft(kind: .sleep, start: Date()).makeDTO()

        let created = try await repository.create(dto)
        XCTAssertEqual(created.id, dto.id)

        let fetched = try await repository.events(in: nil, kind: nil)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, dto.id)

        try await repository.delete(id: dto.id)
        let afterDeletion = try await repository.events(in: nil, kind: nil)
        XCTAssertTrue(afterDeletion.isEmpty)
    }
}
