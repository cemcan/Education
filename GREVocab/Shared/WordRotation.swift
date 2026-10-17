import Foundation

/// Picks the word for a moment in time. The same date always yields the same word,
/// so the app, the widget and the Shortcuts wallpaper all agree without syncing.
enum WordRotation {
    /// Index of the time slot containing `date`, aligned to local midnight.
    static func slot(for date: Date, interval: RotationInterval, timeZone: TimeZone = .current) -> Int {
        let local = date.timeIntervalSince1970 + TimeInterval(timeZone.secondsFromGMT(for: date))
        return Int((local / interval.seconds).rounded(.down))
    }

    static func startOfSlot(_ slot: Int, interval: RotationInterval, timeZone: TimeZone = .current) -> Date {
        let local = Double(slot) * interval.seconds
        let guess = Date(timeIntervalSince1970: local)
        return Date(timeIntervalSince1970: local - TimeInterval(timeZone.secondsFromGMT(for: guess)))
    }

    /// The next `count` moments after `date` at which the word changes.
    static func upcomingBoundaries(after date: Date, count: Int,
                                   interval: RotationInterval = AppSettings.interval) -> [Date] {
        let current = slot(for: date, interval: interval)
        return (1...max(count, 1))
            .map { startOfSlot(current + $0, interval: interval) }
            .filter { $0 > date }
    }

    static func word(for date: Date,
                     in words: [VocabWord],
                     interval: RotationInterval,
                     offset: Int) -> VocabWord? {
        guard !words.isEmpty else { return nil }
        let order = shuffledOrder(of: words)
        let index = positiveModulo(slot(for: date, interval: interval) + offset, order.count)
        return order[index]
    }

    /// Convenience that reads the shared settings and repository.
    static func currentWord(at date: Date = Date()) -> VocabWord? {
        word(for: date,
             in: WordRepository.shared.words,
             interval: AppSettings.interval,
             offset: AppSettings.skipOffset)
    }

    // MARK: - Deterministic shuffle

    private static func shuffledOrder(of words: [VocabWord]) -> [VocabWord] {
        var result = words.sorted { $0.id < $1.id }
        var rng = SplitMix64(seed: 0x6E5_0CAB_2026)
        // Hand-rolled Fisher–Yates so the order never depends on stdlib implementation details.
        if result.count > 1 {
            for i in stride(from: result.count - 1, to: 0, by: -1) {
                let j = Int(rng.next() % UInt64(i + 1))
                result.swapAt(i, j)
            }
        }
        return result
    }

    private static func positiveModulo(_ value: Int, _ modulus: Int) -> Int {
        ((value % modulus) + modulus) % modulus
    }
}

private struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
