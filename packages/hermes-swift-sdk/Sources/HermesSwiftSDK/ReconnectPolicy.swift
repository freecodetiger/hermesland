public struct ReconnectPolicy {
    public let delays: [Int]

    public init(delays: [Int] = [1, 2, 5, 10, 30, 60]) {
        self.delays = delays
    }

    public func delay(forAttempt attempt: Int) -> Int {
        guard !delays.isEmpty else {
            return 60
        }

        let index = max(0, attempt)
        if index < delays.count {
            return min(delays[index], 60)
        }

        return 60
    }
}
