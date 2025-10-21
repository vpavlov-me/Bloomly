import XCTest
@testable import Measurements

final class WHOPercentilesTests: XCTestCase {
    func testWeightPercentileData() {
        // Test male 50th percentile weight
        let maleP50 = WHOPercentiles.weightPercentile(for: .male, curve: .p50)
        XCTAssertFalse(maleP50.isEmpty)
        XCTAssertTrue(maleP50.contains(where: { $0.ageMonths == 0 }))
        XCTAssertTrue(maleP50.contains(where: { $0.ageMonths == 12 }))

        // Test female 50th percentile weight
        let femaleP50 = WHOPercentiles.weightPercentile(for: .female, curve: .p50)
        XCTAssertFalse(femaleP50.isEmpty)

        // Male should be slightly heavier than female at same age
        let male6Mo = maleP50.first(where: { $0.ageMonths == 6 })
        let female6Mo = femaleP50.first(where: { $0.ageMonths == 6 })
        XCTAssertNotNil(male6Mo)
        XCTAssertNotNil(female6Mo)
        if let male = male6Mo, let female = female6Mo {
            XCTAssertGreaterThan(male.value, female.value)
        }
    }

    func testHeightPercentileData() {
        // Test height percentiles
        let maleHeightP50 = WHOPercentiles.heightPercentile(for: .male, curve: .p50)
        XCTAssertFalse(maleHeightP50.isEmpty)

        let femaleHeightP50 = WHOPercentiles.heightPercentile(for: .female, curve: .p50)
        XCTAssertFalse(femaleHeightP50.isEmpty)

        // Birth height should be around 50cm
        let birthHeight = maleHeightP50.first(where: { $0.ageMonths == 0 })
        XCTAssertNotNil(birthHeight)
        if let height = birthHeight {
            XCTAssertGreaterThan(height.value, 45)
            XCTAssertLessThan(height.value, 55)
        }
    }

    func testHeadPercentileData() {
        // Test head circumference percentiles
        let maleHeadP50 = WHOPercentiles.headPercentile(for: .male, curve: .p50)
        XCTAssertFalse(maleHeadP50.isEmpty)

        let femaleHeadP50 = WHOPercentiles.headPercentile(for: .female, curve: .p50)
        XCTAssertFalse(femaleHeadP50.isEmpty)

        // Birth head circumference should be around 33-35cm
        let birthHead = maleHeadP50.first(where: { $0.ageMonths == 0 })
        XCTAssertNotNil(birthHead)
        if let head = birthHead {
            XCTAssertGreaterThan(head.value, 30)
            XCTAssertLessThan(head.value, 40)
        }
    }

    func testPercentileCurves() {
        // Test that 3rd < 50th < 97th percentile
        let p3 = WHOPercentiles.weightPercentile(for: .male, curve: .p3)
        let p50 = WHOPercentiles.weightPercentile(for: .male, curve: .p50)
        let p97 = WHOPercentiles.weightPercentile(for: .male, curve: .p97)

        // Find common age point
        if let weight3 = p3.first(where: { $0.ageMonths == 6 }),
           let weight50 = p50.first(where: { $0.ageMonths == 6 }),
           let weight97 = p97.first(where: { $0.ageMonths == 6 }) {
            XCTAssertLessThan(weight3.value, weight50.value)
            XCTAssertLessThan(weight50.value, weight97.value)
        }
    }

    func testAllCurveTypes() {
        // Ensure all curve types return data
        for curve in WHOPercentiles.Curve.allCases {
            let data = WHOPercentiles.weightPercentile(for: .male, curve: curve)
            XCTAssertFalse(data.isEmpty, "Curve \(curve) should have data")
        }
    }
}
