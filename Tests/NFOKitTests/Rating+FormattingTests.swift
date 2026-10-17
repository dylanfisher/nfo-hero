import NFOKit
import Testing

private func rating(_ value: Double, max: Double?) -> Rating {
    Rating(name: nil, value: value, max: max, votes: nil, isDefault: false)
}

@Test func formatsAValueOutOfItsScale() {
    #expect(rating(8.2, max: 10).formattedValue == "8.2/10")
    #expect(rating(92, max: 100).formattedValue == "92/100")
}

@Test func roundsToOneDecimalPlace() {
    #expect(rating(7.912, max: 10).formattedValue == "7.9/10")
    #expect(rating(7.96, max: 10).formattedValue == "8/10")
}

@Test func assumesAScaleOfTenWhenTheFileHasNone() {
    #expect(rating(8.5, max: nil).formattedValue == "8.5/10")
}
