import Foundation

/// Handles all communication with the Firebase Auth REST API.
final class NetworkingService {

    private static let apiKey = "AIzaSyDeLs8S6Hpy642JUPC3Pft-xVx8Ocs-uXY"
    private static let signInURL = URL(
        string: "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=\(apiKey)"
    )!

    private let session = URLSession(configuration: .default)

    /// Signs in with email and password.
    ///
    /// `completionHandler` is called exactly once, always on the main thread,
    /// with either a `User` or a `NetworkingError`.
    func login(
        email: String,
        password: String,
        completionHandler: @escaping (User?, NetworkingError?) -> Void
    ) {
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "returnSecureToken": true,
        ]

        var request = URLRequest(url: Self.signInURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, .serializationFailed(error.localizedDescription))
            }
            return
        }

        let task = session.dataTask(with: request) { data, response, error in
            #if DEBUG
            print("Data:", data.flatMap { String(data: $0, encoding: .utf8) } ?? "nil")
            print("Response:", response.map { "\($0)" } ?? "nil")
            print("Error:", error.map { "\($0)" } ?? "nil")
            #endif

            let result = Self.parseLoginResponse(data: data, response: response, error: error)

            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    completionHandler(user, nil)
                case .failure(let networkingError):
                    completionHandler(nil, networkingError)
                }
            }
        }
        task.resume()
    }

    /// Turns the raw output of a `URLSessionDataTask` into a `User` or a `NetworkingError`.
    static func parseLoginResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) -> Result<User, NetworkingError> {
        if let error = error as NSError? {
            return .failure(networkingError(for: error))
        }

        guard let httpResponse = response as? HTTPURLResponse, let data else {
            return .failure(.unexpectedResponseFormat)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            guard let responseError = try? JSONDecoder().decode(ResponseError.self, from: data) else {
                return .failure(.unsuccessfulStatusCode(httpResponse.statusCode, nil))
            }
            return .failure(networkingError(for: responseError, statusCode: httpResponse.statusCode))
        }

        guard let user = try? JSONDecoder().decode(User.self, from: data) else {
            return .failure(.unexpectedResponseFormat)
        }

        #if DEBUG
        print("User:", user)
        #endif

        return .success(user)
    }

    private static func networkingError(for error: NSError) -> NetworkingError {
        let offlineCodes: Set<Int> = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorCannotFindHost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorTimedOut,
            NSURLErrorDataNotAllowed,
            NSURLErrorInternationalRoamingOff,
        ]

        if error.domain == NSURLErrorDomain, offlineCodes.contains(error.code) {
            return .offline(error.localizedDescription)
        }
        return .unknown(error.localizedDescription)
    }

    private static func networkingError(for responseError: ResponseError, statusCode: Int) -> NetworkingError {
        // Some messages carry extra detail, e.g. "TOO_MANY_ATTEMPTS_TRY_LATER : Access to this account …".
        let code = responseError.message
            .components(separatedBy: " : ")
            .first?
            .trimmingCharacters(in: .whitespaces) ?? responseError.message

        switch code {
        case "INVALID_EMAIL", "MISSING_EMAIL":
            return .invalidEmail
        case "EMAIL_NOT_FOUND":
            return .emailNotFound
        case "INVALID_PASSWORD", "MISSING_PASSWORD":
            return .invalidPassword
        case "INVALID_LOGIN_CREDENTIALS":
            return .invalidCredentials
        default:
            return .unsuccessfulStatusCode(statusCode, responseError.message)
        }
    }
}
