import Foundation

/// Error payload returned by the Firebase REST API, e.g.:
///
/// ```json
/// {
///   "error": {
///     "code": 400,
///     "message": "INVALID_EMAIL",
///     "errors": [{ "message": "INVALID_EMAIL", "domain": "global", "reason": "invalid" }]
///   }
/// }
/// ```
struct ResponseError: Codable {
    let code: Int
    let message: String
    let errors: [ErrorDetail]

    struct ErrorDetail: Codable {
        let message: String
        let domain: String
        let reason: String
    }

    private enum RootCodingKeys: String, CodingKey {
        case error
    }

    private enum ErrorCodingKeys: String, CodingKey {
        case code
        case message
        case errors
    }

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: RootCodingKeys.self)
        let error = try root.nestedContainer(keyedBy: ErrorCodingKeys.self, forKey: .error)
        code = try error.decode(Int.self, forKey: .code)
        message = try error.decode(String.self, forKey: .message)
        errors = try error.decodeIfPresent([ErrorDetail].self, forKey: .errors) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var root = encoder.container(keyedBy: RootCodingKeys.self)
        var error = root.nestedContainer(keyedBy: ErrorCodingKeys.self, forKey: .error)
        try error.encode(code, forKey: .code)
        try error.encode(message, forKey: .message)
        try error.encode(errors, forKey: .errors)
    }
}
