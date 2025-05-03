import Flutter
import UIKit
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Initialize Google Sign-In
    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
      if let error = error {
        print("Google Sign-In restore error: \(error.localizedDescription)")
      } else if let user = user {
        print("Google Sign-In restored user: \(user.profile?.email ?? "No Email")")
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
  }
}
