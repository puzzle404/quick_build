import Foundation

/// Backend URLs. The Rails app exposes its Hotwire Native path-configuration at
/// `/configurations/ios_v1`, and every tab's initial URL is just a regular path
/// (Rails detects Hotwire Native via the UA suffix we set in `AppDelegate`).
struct AppEnvironment {
    static let shared = AppEnvironment(
        // Override at build time with a custom user-defined Xcode setting, or
        // edit the default here. For local development pointing at `bin/dev`
        // on the host machine, use the LAN IP (Simulator can reach `localhost`,
        // physical devices cannot).
        baseURL: URL(string: Bundle.main.object(forInfoDictionaryKey: "QB_BASE_URL") as? String
                     ?? "http://localhost:3000")!
    )

    let baseURL: URL

    var pathConfigurationURL: URL { baseURL.appendingPathComponent("configurations/ios_v1") }

    // Tab roots — these match `Qb::Mobile::TabBarComponent::TABS` on the Rails
    // side so the QA preview (plain browser) renders the same chrome.
    var dashboardURL: URL { baseURL.appendingPathComponent("constructors") }
    var projectsURL: URL  { baseURL.appendingPathComponent("constructors/projects") }
    var searchURL: URL    { baseURL.appendingPathComponent("constructors/search") }
    var libraryURL: URL   { baseURL.appendingPathComponent("constructors/biblioteca") }
    var profileURL: URL   { baseURL.appendingPathComponent("registration/edit") }
}
