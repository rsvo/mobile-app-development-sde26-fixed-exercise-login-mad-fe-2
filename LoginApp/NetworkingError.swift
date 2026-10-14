import Foundation

enum NetworkingError: Error {
    /// The request body (email/password dictionary) could not be serialized to JSON.
    case serializationFailed(String)
    /// The entered text is not a valid email address.
    case invalidEmail
    /// No account exists for the entered email address.
    case emailNotFound
    /// The email exists, but the password is wrong.
    case invalidPassword
    /// Firebase (with email enumeration protection enabled) doesn't say whether
    /// the email or the password was wrong.
    case invalidCredentials
    /// The device is offline or the server can't be reached.
    case offline(String)
    /// The response body couldn't be parsed into the expected format.
    case unexpectedResponseFormat
    /// The server answered with a non-successful HTTP status code.
    case unsuccessfulStatusCode(Int, String?)
    /// Anything else we didn't anticipate.
    case unknown(String)
}

extension NetworkingError {
    var title: String {
        switch self {
        case .serializationFailed:
            return "Request error"
        case .invalidEmail:
            return "Invalid email"
        case .emailNotFound:
            return "Unknown email"
        case .invalidPassword:
            return "Wrong password"
        case .invalidCredentials:
            return "Login failed"
        case .offline:
            return "No connection"
        case .unexpectedResponseFormat:
            return "Unexpected response"
        case .unsuccessfulStatusCode:
            return "Server error"
        case .unknown:
            return "Something went wrong"
        }
    }

    var message: String {
        switch self {
        case .serializationFailed(let description):
            return "The login request could not be created. (\(description))"
        case .invalidEmail:
            return "Please enter a valid email address."
        case .emailNotFound:
            return "There is no account for this email address."
        case .invalidPassword:
            return "The password you entered is incorrect."
        case .invalidCredentials:
            return "Email or password is incorrect. Please try again."
        case .offline(let description):
            return "Please check your internet connection and try again.\n\n\(description)"
        case .unexpectedResponseFormat:
            return "The server sent a response in an unexpected format."
        case .unsuccessfulStatusCode(let statusCode, let serverMessage):
            if let serverMessage {
                return "The server responded with status code \(statusCode): \(serverMessage)"
            }
            return "The server responded with status code \(statusCode)."
        case .unknown(let description):
            return description
        }
    }
}
