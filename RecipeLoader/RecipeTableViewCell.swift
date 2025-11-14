//
//  RecipeTableViewCell.swift
//  RecipeLoader
//
//  Created by user on 12.11.2025.
//
//
//import UIKit
//
//class RecipeTableViewCell: UITableViewCell {
//    
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.boldSystemFont(ofSize: 16)
//        label.numberOfLines = 2
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let sourceLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 12)
//        label.textColor = .systemGray
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let descriptionLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 14)
//        label.textColor = .systemGray2
//        label.numberOfLines = 2
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        setupUI()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    private func setupUI() {
//        contentView.addSubview(titleLabel)
//        contentView.addSubview(sourceLabel)
//        contentView.addSubview(descriptionLabel)
//        
//        NSLayoutConstraint.activate([
//            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
//            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            
//            sourceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
//            sourceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            sourceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            
//            descriptionLabel.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 4),
//            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
//        ])
//    }
//    
//    func configure(with recipe: Recipe) {
//        titleLabel.text = recipe.title
//        sourceLabel.text = "Источник: \(recipe.source)"
//        descriptionLabel.text = recipe.description
//    }
//}

import UIKit

class RecipeTableViewCell: UITableViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.numberOfLines = 2
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sourceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .systemGray2
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let recipeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.backgroundColor = .systemGray6
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(recipeImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(sourceLabel)
        contentView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            recipeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            recipeImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            recipeImageView.widthAnchor.constraint(equalToConstant: 60),
            recipeImageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: recipeImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            sourceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            sourceLabel.leadingAnchor.constraint(equalTo: recipeImageView.trailingAnchor, constant: 12),
            sourceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            
            descriptionLabel.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: recipeImageView.trailingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
  
    func configure(with recipe: Recipe) {
        titleLabel.text = recipe.title
        sourceLabel.text = "📝 \(recipe.source)"
        
        // Основное описание
        var descriptionText = recipe.description ?? ""
        
        // Дополнительная информация для ячейки
        var additionalInfo: [String] = []
        
        if let cookingTime = recipe.cookingTime {
            additionalInfo.append("⏱ \(cookingTime)")
        }
        
        if let servings = recipe.servings {
            additionalInfo.append("🍽 \(servings)")
        }
        
        if let categories = recipe.categories, !categories.isEmpty {
            // Берем только первые 2 категории для компактности
            let mainCategories = Array(categories.prefix(2))
            additionalInfo.append("📁 \(mainCategories.joined(separator: ", "))")
        }
        
        // Формируем итоговый текст
        if !additionalInfo.isEmpty {
            if !descriptionText.isEmpty {
                descriptionText += "\n"
            }
            descriptionText += additionalInfo.joined(separator: " • ")
        }
        
        descriptionLabel.text = descriptionText.isEmpty ? "Рецепт с \(recipe.source)" : descriptionText
        
        // Загрузка изображения
        recipeImageView.image = UIImage(systemName: "photo")?
            .withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
        
        if let imageUrl = recipe.imageUrl {
            loadImage(from: imageUrl)
        }
    }
     
    private func loadImage(from urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else { return }
        
        DispatchQueue.global(qos: .utility).async {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.recipeImageView.image = image
                }
            }
        }
    }
}
