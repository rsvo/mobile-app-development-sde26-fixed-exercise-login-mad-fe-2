import Foundation

/// A signed-in user as returned by the Firebase `signInWithPassword` endpoint.
struct User: Codable {
    let localId: String
    let email: String
    let displayName: String
    let idToken: String
    let registered: Bool
    let refreshToken: String
    let expiresIn: String
}
