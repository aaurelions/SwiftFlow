import Testing
import Foundation
@testable import SwiftFlow

@Suite("Connection")
struct ConnectionTests {

    @Test func initWithDefaults() {
        let conn = Connection(source: "1", target: "2")
        #expect(conn.source == "1")
        #expect(conn.target == "2")
        #expect(conn.sourceHandle == nil)
        #expect(conn.targetHandle == nil)
    }

    @Test func initWithHandles() {
        let conn = Connection(source: "1", target: "2", sourceHandle: "out", targetHandle: "in")
        #expect(conn.sourceHandle == "out")
        #expect(conn.targetHandle == "in")
    }

    @Test func equatable() {
        let a = Connection(source: "1", target: "2")
        let b = Connection(source: "1", target: "2")
        let c = Connection(source: "1", target: "3")
        #expect(a == b)
        #expect(a != c)
    }

    @Test func codable() throws {
        let conn = Connection(source: "1", target: "2", sourceHandle: "out")
        let data = try JSONEncoder().encode(conn)
        let decoded = try JSONDecoder().decode(Connection.self, from: data)
        #expect(decoded == conn)
    }

    @Test func hashable() {
        let a = Connection(source: "1", target: "2")
        let b = Connection(source: "1", target: "2")
        var set: Set<Connection> = []
        set.insert(a)
        set.insert(b)
        #expect(set.count == 1)
    }
}
