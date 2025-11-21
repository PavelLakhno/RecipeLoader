//
//  MainTabBarController.swift
//  RecipeLoader
//
//  Created by user on 18.11.2025.
//

import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewControllers()
        setupTabBar()
    }
    
    private func setupViewControllers() {
        let povarenokVC = createRecipeListViewController(with: PovarenokSource(), title: "Povarenok", imageName: "fork.knife")
        let koolinarVC = createRecipeListViewController(with: KoolinarSource(), title: "Koolinar", imageName: "flame")
        let gastronomVC = createRecipeListViewController(with: GastronomSource(), title: "Gastronom", imageName: "flame")
        
        viewControllers = [povarenokVC, koolinarVC, gastronomVC]
    }
    
    private func setupTabBar() {
        tabBar.tintColor = .systemOrange
        tabBar.unselectedItemTintColor = .systemGray
    }
    
    private func createRecipeListViewController(with source: RecipeSource, title: String, imageName: String) -> UIViewController {
        let viewController = RecipeTableViewController()
        viewController.recipeSource = source
        
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: imageName),
            selectedImage: UIImage(systemName: "\(imageName).fill")
        )
        
        return navigationController
    }
}
