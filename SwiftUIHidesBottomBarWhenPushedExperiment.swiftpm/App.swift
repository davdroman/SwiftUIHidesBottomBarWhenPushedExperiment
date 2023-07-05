import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

@main
struct App: SwiftUI.App {
	init() {
		if
			let originalMethod = class_getInstanceMethod(
				UIViewController.self,
				#selector(getter: UIViewController.hidesBottomBarWhenPushed)
			),
			let swizzledMethod = class_getInstanceMethod(
				UIViewController.self,
				#selector(getter: UIViewController.swizzled_hidesBottomBarWhenPushed)
			)
		{
			method_exchangeImplementations(originalMethod, swizzledMethod)
		}
	}

	var body: some Scene {
		WindowGroup {
			TabView {
				NavigationView {
					NavigationLink("Link") {
						Text("Detail")
					}
					.navigationBarTitle("Root")
				}
				.navigationViewStyle(.stack)
				.tabItem {
					Image(systemName: "1.circle")
					Text("Tab")
				}
			}
			.introspect(.tabView, on: .iOS(.v13...)) { tabBarController in
				print("root", tabBarController.viewControllers?.first) // UIHostingController
				print("child", tabBarController.viewControllers?.first?.children.first) // UINavigationController
			}
		}
	}
}

extension UIViewController {
	@objc dynamic var swizzled_hidesBottomBarWhenPushed: Bool {
		true
	}
}

extension UITabBarController {
	// This is a private API that gets called whenever a push navigation transition occurs,
	// to determine whether the selected tab is a UINavigationController,
	// and whether the tab bar should be hidden as a result of `hidesBottomBarWhenPushed`.
	//
	// Since TabView (UITabBarController)'s tabs are always a UIHostingController,
	// `hidesBottomBarWhenPushed` is never respected, so what we're doing here is override
	// this entry point and hand out the `UINavigationController` inside the UIHostingController.
	//
	// This along with swizzling `hidesBottomBarWhenPushed` to always be true makes the tab bar finally hide,
	// but the animation and layout are messy and buggy.
	@objc dynamic var _selectedViewControllerInTabBar: UIViewController? {
		guard
			let selectedItem = tabBar.selectedItem,
			let index = tabBar.items?.firstIndex(of: selectedItem)
		else {
			return nil
		}

		if let navigationController = viewControllers?[index].children.first as? UINavigationController {
			return navigationController
		} else {
			return viewControllers?[index]
		}
	}
}
