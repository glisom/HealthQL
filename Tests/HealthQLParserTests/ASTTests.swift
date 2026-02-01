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

        if case .aggregate(let fn, let inner) = expr {
            #expect(fn == .sum)
            if case .identifier(let name) = inner {
                #expect(name == "value")
            }
        }
    }

    @Test("Expression can represent date arithmetic")
    func dateArithmetic() {
        let expr = Expression.binary(
            .function(.today, []),
            .minus,
            .duration(7, .days)
        )

        if case .binary(_, let op, _) = expr {
            #expect(op == .minus)
        }
    }
}
