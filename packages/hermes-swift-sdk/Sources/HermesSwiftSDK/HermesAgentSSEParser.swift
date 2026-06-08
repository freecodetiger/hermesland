import Foundation

public struct HermesAgentSSEParser {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func parse(_ text: String) throws -> [JSONValue] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        return try normalized
            .components(separatedBy: "\n\n")
            .compactMap { block in
                let dataLines = block
                    .split(separator: "\n", omittingEmptySubsequences: false)
                    .compactMap { line -> String? in
                        guard line.hasPrefix("data:") else {
                            return nil
                        }
                        return String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                    }
                guard !dataLines.isEmpty else {
                    return nil
                }
                let json = dataLines.joined()
                return try decoder.decode(JSONValue.self, from: Data(json.utf8))
            }
    }
}
