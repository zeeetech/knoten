import Foundation

public typealias KnotenResult<Value> = Result<Value, KnotenError>

extension Result {
    /// Sequences a step that can fail. Same shape as `with` in the Elixir
    /// sources: the first failure short circuits the rest.
    func then<Value>(_ next: (Success) async -> Result<Value, Failure>) async -> Result<Value, Failure> {
        switch self {
        case .success(let value):
            return await next(value)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// The success, when there is one. Lets a caller branch without a switch.
    var value: Success? {
        if case .success(let value) = self { return value }
        return nil
    }

    /// The failure, when there is one.
    var error: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
}
