import Foundation
import Testing
@testable import LoginApp

struct LoginAppTests {

    private let url = URL(string: "https://example.com")!

    private func httpResponse(_ statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    private func errorBody(_ message: String, code: Int = 400) -> Data {
        Data("""
        {
          "error": {
            "code": \(code),
            "message": "\(message)",
            "errors": [{ "message": "\(message)", "domain": "global", "reason": "invalid" }]
          }
        }
        """.utf8)
    }

    @Test func parsesSuccessfulLogin() throws {
        let body = Data("""
        {
          "kind": "identitytoolkit#VerifyPasswordResponse",
          "localId": "abc",
          "email": "mad-fe@mad.at",
          "displayName": "",
          "idToken": "token",
          "registered": true,
          "refreshToken": "refresh",
          "expiresIn": "3600"
        }
        """.utf8)

        let result = NetworkingService.parseLoginResponse(data: body, response: httpResponse(200), error: nil)
        let user = try result.get()
        #expect(user.email == "mad-fe@mad.at")
        #expect(user.localId == "abc")
        #expect(user.registered)
    }

    @Test func decodesResponseError() throws {
        let error = try JSONDecoder().decode(ResponseError.self, from: errorBody("INVALID_EMAIL"))
        #expect(error.code == 400)
        #expect(error.message == "INVALID_EMAIL")
        #expect(error.errors.first?.reason == "invalid")
    }

    @Test(arguments: [
        ("INVALID_EMAIL", "invalidEmail"),
        ("EMAIL_NOT_FOUND", "emailNotFound"),
        ("INVALID_PASSWORD", "invalidPassword"),
        ("INVALID_LOGIN_CREDENTIALS", "invalidCredentials"),
    ])
    func mapsFirebaseErrorMessages(message: String, expectedCase: String) {
        let result = NetworkingService.parseLoginResponse(
            data: errorBody(message), response: httpResponse(400), error: nil
        )
        guard case .failure(let error) = result else {
            Issue.record("Expected failure")
            return
        }
        #expect("\(error)" == expectedCase)
    }

    @Test func mapsOfflineError() {
        let nsError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        let result = NetworkingService.parseLoginResponse(data: nil, response: nil, error: nsError)
        guard case .failure(.offline) = result else {
            Issue.record("Expected .offline, got \(result)")
            return
        }
    }

    @Test func mapsUnknownTransportError() {
        let nsError = NSError(domain: "Other", code: 1)
        let result = NetworkingService.parseLoginResponse(data: nil, response: nil, error: nsError)
        guard case .failure(.unknown) = result else {
            Issue.record("Expected .unknown, got \(result)")
            return
        }
    }

    @Test func mapsUnexpectedFormat() {
        let result = NetworkingService.parseLoginResponse(
            data: Data("not json".utf8), response: httpResponse(200), error: nil
        )
        guard case .failure(.unexpectedResponseFormat) = result else {
            Issue.record("Expected .unexpectedResponseFormat, got \(result)")
            return
        }
    }

    @Test func mapsServerErrorStatusCode() {
        let result = NetworkingService.parseLoginResponse(
            data: Data("<html>Internal Server Error</html>".utf8), response: httpResponse(500), error: nil
        )
        guard case .failure(.unsuccessfulStatusCode(500, nil)) = result else {
            Issue.record("Expected .unsuccessfulStatusCode(500, nil), got \(result)")
            return
        }
    }

    @Test func mapsUnknownFirebaseErrorToStatusCode() {
        let result = NetworkingService.parseLoginResponse(
            data: errorBody("TOO_MANY_ATTEMPTS_TRY_LATER : Try again later."),
            response: httpResponse(400),
            error: nil
        )
        guard case .failure(.unsuccessfulStatusCode(400, .some)) = result else {
            Issue.record("Expected .unsuccessfulStatusCode(400, message), got \(result)")
            return
        }
    }
}
