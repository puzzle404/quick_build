import UIKit
import HotwireNative

/// Root `UITabBarController` with five tabs that mirror the in-page bottom bar
/// rendered by `Qb::Mobile::TabBarComponent`. Each tab owns its own
/// `Navigator`, so swiping between tabs preserves their navigation stacks.
final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let env = AppEnvironment.shared
        viewControllers = [
            tab(title: "Inicio",    systemImage: "house.fill",       url: env.dashboardURL),
            tab(title: "Proyectos", systemImage: "folder.fill",      url: env.projectsURL),
            tab(title: "Buscar",    systemImage: "magnifyingglass",  url: env.searchURL),
            tab(title: "Biblioteca",systemImage: "books.vertical.fill", url: env.libraryURL),
            tab(title: "Perfil",    systemImage: "person.crop.circle.fill", url: env.profileURL),
        ]
    }

    private func tab(title: String, systemImage: String, url: URL) -> UIViewController {
        let navigator = Navigator()
        let nav = navigator.rootViewController
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: systemImage), tag: 0)
        navigator.route(url)
        // Hand the navigator's lifetime to the nav controller; release stays
        // tied to the tab's lifecycle.
        objc_setAssociatedObject(nav, &Self.navigatorKey, navigator, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return nav
    }

    private static var navigatorKey = "navigator"
}
