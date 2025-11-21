//
//  GastronomSource.swift
//  RecipeLoader
//
//  Created by user on 19.11.2025.
//

class GastronomSource: RecipeSource {
    let name = "Gastronom.ru"
    let baseURL = "https://www.gastronom.ru"
    
    func buildListURL(page: Int) -> String {
        if page == 1 {
            return "\(baseURL)/search?pagetype=recipepage"
        } else {
            return "\(baseURL)/search?pagetype=recipepage&page=\(page)"
        }
    }
    
    func parseRecipes(from html: String) -> [Recipe] {
        return GastronomListParser.parseRecipes(from: html, baseURL: baseURL)
    }
    
    func parseDetailedRecipe(from html: String, url: String) -> Recipe? {
        return GastronomDetailParser.parseDetailedRecipe(from: html, url: url)
    }
    
}
