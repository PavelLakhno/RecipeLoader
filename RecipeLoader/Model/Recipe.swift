//
//  Recipe.swift
//  RecipeLoader
//
//  Created by user on 12.11.2025.
//

import Foundation

struct Recipe {
    let id: String?
    let title: String
    let source: String
    let url: String
    let imageUrl: String?
    let description: String?
    let categories: [String]?
    let ingredients: [Ingredient]?
    let nutrition: NutritionInfo?
    let instructions: [InstructionStep]?
    let tags: [String]?
    let cookingTime: String?
    let servings: String?
    let cuisine: String?
    let addedDate: String?
    
    // Инициализатор для списка рецептов
    init(title: String, source: String, url: String, imageUrl: String? = nil, description: String? = nil,
         categories: [String]? = nil, tags: [String]? = nil, cookingTime: String? = nil, servings: String? = nil, addedDate: String? = nil) {
        self.id = nil
        self.title = title
        self.source = source
        self.url = url
        self.imageUrl = imageUrl
        self.description = description
        self.categories = categories
        self.tags = tags
        self.cookingTime = cookingTime
        self.servings = servings
        self.cuisine = nil
        self.ingredients = nil
        self.nutrition = nil
        self.instructions = nil
        self.addedDate = addedDate
    }
    
    // Инициализатор для детальных рецептов
    init(id: String, title: String, source: String, url: String, imageUrl: String? = nil, description: String,
         categories: [String], ingredients: [Ingredient], nutrition: NutritionInfo?, instructions: [InstructionStep],
         tags: [String], cookingTime: String?, servings: String?, cuisine: String?, addedDate: String?) {
        self.id = id
        self.title = title
        self.source = source
        self.url = url
        self.imageUrl = imageUrl
        self.description = description
        self.categories = categories
        self.ingredients = ingredients
        self.nutrition = nutrition
        self.instructions = instructions
        self.tags = tags
        self.cookingTime = cookingTime
        self.servings = servings
        self.cuisine = cuisine
        self.addedDate = addedDate
    }
}

extension Recipe {
    var isDetailed: Bool {
        return id != nil && ingredients != nil
    }
}

struct Ingredient {
    let name: String
    let amount: String
    let url: String?
}

struct NutritionInfo {
    let calories: String
    let protein: String
    let fat: String
    let carbohydrates: String
    let caloriesPer100g: String
    let proteinPer100g: String
    let fatPer100g: String
    let carbohydratesPer100g: String
}

struct InstructionStep {
    let stepNumber: Int
    let text: String
    let imageUrl: String?
}
