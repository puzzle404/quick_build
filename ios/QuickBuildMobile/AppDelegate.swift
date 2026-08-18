import UIKit
import HotwireNative

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        configureHotwire()
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connecting: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default", sessionRole: connecting.role)
    }

    private func configureHotwire() {
        // Mark every web view request with `Hotwire Native` so Rails' `hotwire_native_app?`
        // returns true and Rails serves the `:mobile` variant.
        Hotwire.config.applicationUserAgent = "Hotwire Native iOS; QuickBuild/\(appVersion)"

        // Tell each navigator how to present screens by loading the path config
        // we already host at /configurations/ios_v1.
        Hotwire.loadPathConfiguration(from: [
            .file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!),
            .server(AppEnvironment.shared.pathConfigurationURL)
        ])

        // Register the only native screen we currently override.
        Hotwire.registerBridgeComponents([])
        Hotwire.registerStimulusSubmodules([])
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(v) (\(b))"
    }
}
