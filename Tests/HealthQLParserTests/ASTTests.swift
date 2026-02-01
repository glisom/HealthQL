import Testing
@testable import HealthQLParser

@Suite("AST Tests")
struct ASTTests {

    @Test("SelectStatement holds query components")
    func selectStatement() {
        let stmt = SelectStatement(
            selections: [.aggregate(.sum, .identifier("count"))],
            from: "steps",
            whereClause: nil,
            groupBy: nil,
            having: nil,
            orderBy: nil,
            limit: nil
        )

        #expect(stmt.from == "steps")
        #expect(stmt.selections.count == 1)
    }

    @Test("Expression can represent aggregates")
    func aggregateExpression() {
        let expr = Expression.aggregate(.sum, .identifier("value"))

        guard case .aggregate(let fn, let inner) = expr else {
            Issue.record("Expected aggregate expression")
            return
        }
        #expect(fn == .sum)
        guard case .identifier(let name) = inner else {
            Issue.record("Expected identifier in aggregate")
            return
        }
        #expect(name == "value")
    }

    @Test("Expression can represent date arithmetic")
    func dateArithmetic() {
        let expr = Expression.binary(
            .function(.today, []),
            .minus,
            .duration(7, .days)
        )

        guard case .binary(let left, let op, let right) = expr else {
            Issue.record("Expected binary expression")
            return
        }
        #expect(op == .minus)
        guard case .function(.today, _) = left else {
            Issue.record("Expected today function on left")
            return
        }
        guard case .duration(7, .days) = right else {
            Issue.record("Expected 7 day duration on right")
            return
        }
    }
}
