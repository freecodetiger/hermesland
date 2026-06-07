public struct LastSeqTracker {
    public private(set) var current: Int64

    public init(current: Int64 = 0) {
        self.current = current
    }

    @discardableResult
    public mutating func advanceIfGreater(_ seq: Int64) -> Bool {
        guard seq > current else {
            return false
        }

        current = seq
        return true
    }
}
