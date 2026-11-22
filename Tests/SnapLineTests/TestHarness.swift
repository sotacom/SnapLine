import Foundation
import CoreGraphics

struct TestFailure: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}

func expect(
    _ condition: @autoclosure () -> Bool,
    _ message: String = "Expectation failed",
    file: String = #fileID,
    line: Int = #line
) throws {
    if !condition() {
        throw TestFailure(message: "\(file):\(line) — \(message)")
    }
}

func expectApprox(
    _ lhs: CGFloat,
    _ rhs: CGFloat,
    accuracy: CGFloat,
    _ message: String = "Values not approximately equal",
    file: String = #fileID,
    line: Int = #line
) throws {
    if abs(lhs - rhs) > accuracy {
        throw TestFailure(message: "\(file):\(line) — \(message) (\(lhs) vs \(rhs), tol \(accuracy))")
    }
}

@MainActor
final class TestRunner {
    private var tests: [(name: String, body: @MainActor () throws -> Void)] = []

    func add(_ name: String, _ body: @escaping @MainActor () throws -> Void) {
        tests.append((name: name, body: body))
    }

    func runAll() -> Int32 {
        var passed = 0
        var failed = 0

        for test in tests {
            do {
                try test.body()
                passed += 1
                print("✓ \(test.name)")
            } catch {
                failed += 1
                print("✗ \(test.name): \(error)")
            }
        }

        print("\nSummary: \(passed)/\(tests.count) tests passed, \(failed) failed.")
        return failed == 0 ? 0 : 1
    }
}
