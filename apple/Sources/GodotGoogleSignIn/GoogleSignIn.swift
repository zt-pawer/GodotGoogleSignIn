import Foundation
#if os(iOS)
import UIKit
import GoogleSignIn
#endif
@preconcurrency import SwiftGodotRuntime

@Godot
class GodotGoogleSignIn: RefCounted, @unchecked Sendable {
    @Signal var googleSignInSuccess: SignalWithArguments<String, String>
    @Signal var googleSignInFailed: SignalWithArguments<String>
    @Signal var googleSignInCancelled: SimpleSignal

    @Callable
    func configure(clientId: String) {
        #if os(iOS)
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        #endif
    }

    @Callable
    func signIn() {
        DispatchQueue.main.async {
            #if os(iOS)
            guard let presentingViewController = Self.rootViewController() else {
                self.googleSignInFailed.emit("No presenting view controller available")
                return
            }
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error {
                    let nsError = error as NSError
                    if nsError.code == GIDSignInError.canceled.rawValue {
                        self.googleSignInCancelled.emit()
                    } else {
                        self.googleSignInFailed.emit(error.localizedDescription)
                    }
                    return
                }
                guard let idToken = result?.user.idToken?.tokenString else {
                    self.googleSignInFailed.emit("Missing idToken in Google Sign-In result")
                    return
                }
                let accessToken = result?.user.accessToken.tokenString ?? ""
                self.googleSignInSuccess.emit(idToken, accessToken)
            }
            #else
            self.googleSignInFailed.emit("Google Sign-In is not supported on this platform")
            #endif
        }
    }

    @Callable
    func signOut() {
        #if os(iOS)
        GIDSignIn.sharedInstance.signOut()
        #endif
    }

    @Callable
    func handleOpenURL(urlString: String) {
        #if os(iOS)
        guard let url = URL(string: urlString) else { return }
        GIDSignIn.sharedInstance.handle(url)
        #endif
    }

    #if os(iOS)
    private static func rootViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
        return scene?.windows.first { $0.isKeyWindow }?.rootViewController
    }
    #endif
}
