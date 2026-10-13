import Foundation

extension JSONDecoder {
    /// Decodes, or reports the shape that did not match. The throw stops here:
    /// above this line, failure is a value.
    func decode<Value: Decodable>(
        _ type: Value.Type,
        from data: Data,
        label: String
    ) -> KnotenResult<Value> {
        guard let value = try? decode(Value.self, from: data) else {
            return .failure(.invalidResponse(label))
        }
        return .success(value)
    }
}
