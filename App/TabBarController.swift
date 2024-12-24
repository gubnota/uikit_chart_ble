import UIKit

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Home Tab
        let homeViewController = HomeViewController()
        homeViewController.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        // Glucose Tab
        let glucoseChartViewController = GlucoseChartViewController()
        glucoseChartViewController.tabBarItem = UITabBarItem(
            title: "Glucose",
            image: UIImage(systemName: "calendar"),
            selectedImage: UIImage(systemName: "calendar.fill")
        )
        
        // Messages Tab
        let messagesViewController = MessagesViewController()
        messagesViewController.tabBarItem = UITabBarItem(
            title: "Messages",
            image: UIImage(systemName: "book"),
            selectedImage: UIImage(systemName: "book.fill")
        )

        // Settings Tab
        let settingsViewController = SettingsViewController()
        settingsViewController.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        // Add Tabs
        self.viewControllers = [homeViewController, glucoseChartViewController, messagesViewController, settingsViewController]
    }
}
