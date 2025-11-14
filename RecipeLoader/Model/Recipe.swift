//
//  Recipe.swift
//  RecipeLoader
//
//  Created by user on 12.11.2025.
//

import Foundation

//struct Recipe {
//    // Старые поля (оставляем для совместимости)
//    let title: String
//    let source: String
//    let url: String
//    let imageUrl: String?
//    let description: String?
//    
//    // Новые поля (делаем опциональными)
//    let id: String?
//    let categories: [String]?
//    let ingredients: [Ingredient]?
//    let nutrition: NutritionInfo?
//    let instructions: [InstructionStep]?
//    let tags: [String]?
//    let cookingTime: String?
//    let servings: String?
//    
//    // Инициализатор для старых рецептов (из списка)
//    init(title: String, source: String, url: String, imageUrl: String? = nil, description: String? = nil) {
//        self.title = title
//        self.source = source
//        self.url = url
//        self.imageUrl = imageUrl
//        self.description = description
//        
//        // Новые поля - nil по умолчанию
//        self.id = nil
//        self.categories = nil
//        self.ingredients = nil
//        self.nutrition = nil
//        self.instructions = nil
//        self.tags = nil
//        self.cookingTime = nil
//        self.servings = nil
//    }
//    
//    // Инициализатор для детальных рецептов
//    init(
//        id: String,
//        title: String,
//        source: String,
//        url: String,
//        imageUrl: String? = nil,
//        description: String,
//        categories: [String],
//        ingredients: [Ingredient],
//        nutrition: NutritionInfo?,
//        instructions: [InstructionStep],
//        tags: [String],
//        cookingTime: String?,
//        servings: String?
//    ) {
//        self.id = id
//        self.title = title
//        self.source = source
//        self.url = url
//        self.imageUrl = imageUrl
//        self.description = description
//        self.categories = categories
//        self.ingredients = ingredients
//        self.nutrition = nutrition
//        self.instructions = instructions
//        self.tags = tags
//        self.cookingTime = cookingTime
//        self.servings = servings
//    }
//}

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
    
    // Инициализатор для списка рецептов
    init(title: String, source: String, url: String, imageUrl: String? = nil, description: String? = nil,
         categories: [String]? = nil, tags: [String]? = nil, cookingTime: String? = nil, servings: String? = nil) {
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
    }
    
    // Инициализатор для детальных рецептов
    init(id: String, title: String, source: String, url: String, imageUrl: String? = nil, description: String,
         categories: [String], ingredients: [Ingredient], nutrition: NutritionInfo?, instructions: [InstructionStep],
         tags: [String], cookingTime: String?, servings: String?, cuisine: String?) {
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
