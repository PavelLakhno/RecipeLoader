//
//  PovarenokSource.swift
//  RecipeLoader
//
//  Created by user on 18.11.2025.
//

class PovarenokSource: RecipeSource {
    let name = "Povarenok.ru"
    let baseURL = "https://www.povarenok.ru"
    
    func buildListURL(page: Int) -> String {
        if page == 1 {
            return "\(baseURL)/recipes/"
        } else {
            return "\(baseURL)/recipes/~\(page)/"
        }
    }
    
    func parseRecipes(from html: String) -> [Recipe] {
        return RecipeParser.parseRecipes(from: html, baseURL: baseURL)
    }
    
    func parseDetailedRecipe(from html: String, url: String) -> Recipe? {
        return RecipeDetailParser.parseDetailedRecipe(from: html, url: url)
    }
}
