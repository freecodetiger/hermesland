import Testing
@testable import HermesSwiftSDK

struct HermesAgentSSEParserTests {
    @Test func parserIgnoresCommentsAndParsesDataEvents() throws {
        let parser = HermesAgentSSEParser()
        let events = try parser.parse("""
        : keepalive

        data: {"event":"message.delta","run_id":"run_1","delta":"hello"}

        data: {"event":"run.completed","run_id":"run_1","output":"done"}

        """)

        #expect(events.count == 2)
        #expect(events[0].objectValue?["event"]?.stringValue == "message.delta")
        #expect(events[0].objectValue?["delta"]?.stringValue == "hello")
        #expect(events[1].objectValue?["event"]?.stringValue == "run.completed")
    }

    @Test func parserCombinesMultilineDataFields() throws {
        let parser = HermesAgentSSEParser()
        let events = try parser.parse("""
        data: {"event":"message.delta",
        data: "run_id":"run_1",
        data: "delta":"hello"}

        """)

        #expect(events.first?.objectValue?["delta"]?.stringValue == "hello")
    }

    @Test func parserReturnsEmptyForOnlyComments() throws {
        let parser = HermesAgentSSEParser()

        let events = try parser.parse("""
        : keepalive

        : stream closed

        """)

        #expect(events.isEmpty)
    }
}
