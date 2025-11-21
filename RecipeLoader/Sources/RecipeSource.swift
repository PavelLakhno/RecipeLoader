//
//  RecipeSource.swift
//  RecipeLoader
//
//  Created by user on 18.11.2025.
//

import Foundation

protocol RecipeSource {
    var name: String { get }
    var baseURL: String { get }
    func buildListURL(page: Int) -> String
    func parseRecipes(from html: String) -> [Recipe]
    func parseDetailedRecipe(from html: String, url: String) -> Recipe?
}
