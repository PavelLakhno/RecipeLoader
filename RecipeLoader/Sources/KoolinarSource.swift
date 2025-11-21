//
//  KoolinarSource.swift
//  RecipeLoader
//
//  Created by user on 18.11.2025.

class KoolinarSource: RecipeSource {
    let name = "Koolinar.ru"
    let baseURL = "https://www.koolinar.ru"
    
    func buildListURL(page: Int) -> String {
        if page == 1 {
            return "\(baseURL)/catalog/recent"
        } else {
            return "\(baseURL)/catalog/recent?page=\(page)"
        }
    }
    
    func parseRecipes(from html: String) -> [Recipe] {
        return KoolinarListParser.parseRecipes(from: html, baseURL: baseURL)
    }
    
    func parseDetailedRecipe(from html: String, url: String) -> Recipe? {
        return KoolinarDetailParser.parseDetailedRecipe(from: html, url: url)
    }
}
