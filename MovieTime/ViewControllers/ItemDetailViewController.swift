//
//  ItemDetailViewController.swift
//  MovieTime
//
//  Created by Alejandro Quezada on 15/02/22.
//

import UIKit

class ItemDetailViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var genereLabel: UILabel!
    @IBOutlet weak var awardsLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var favoritesButton: UIButton!
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var detailsStackView: UIStackView!
    
    var item: IMDBItem!
    
    let imdb = IMDBConnect.sharedInstance
    
    var itemIsInLibrary = false
    
    @IBAction func toggleFavorite(_ sender: UIButton) {
        if imdb.favorites.contains(item) {
            imdb.removeFavorite(item: item)
            favoritesButton.setTitle("Add favorite", for: .normal)
        } else {
            imdb.addFavorite(item: item)
            favoritesButton.setTitle("Remove favorite", for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        titleLabel.text = item.title
        headerImageView.backgroundColor = .lightGray
        detailLabel.text = ""
        detailsStackView.isHidden = true
        
        if imdb.favorites.contains(where: {$0.imdbID == item.imdbID}) {
            favoritesButton.setTitle("Remove favorite", for: .normal)
        } else {
            favoritesButton.setTitle("Add favorite", for: .normal)
        }
        
        let libraryItem = imdb.getItemLibrary().first(where: {$0.item.imdbID == item.imdbID})
        
        if libraryItem != nil && libraryItem!.dateAdded + imdb.rentDuration > Date() { // If rent is still valid
            actionButton.setTitle("Watch Now", for: .normal)
            itemIsInLibrary = true
        } else if imdb.cart.contains(item) {
            actionButton.setTitle("Remove from cart", for: .normal)
            itemIsInLibrary = false
        } else {
            actionButton.setTitle("Add to cart", for: .normal)
            itemIsInLibrary = false
        }
        
        Task {
            do {
                var image = try? await imdb.getImages(for: item.imdbID).backdrops.randomElement()?.fetch()
                if image == nil {
                    image = try await item.fullResPoster.fetch()
                }
                UIView.transition(with: self.headerImageView,
                                  duration: 1,
                                  options: .transitionCurlDown,
                                  animations: { self.headerImageView.image = image
                },
                                  completion: nil)
            } catch {
                let alert = UIAlertController(title: "Error", message: "Unexpected error: \(error).", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in }))
                DispatchQueue.main.async{
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
        }
        Task {
            do {
                let details = try await imdb.getTitleDetail(for: item.imdbID)
                
                detailLabel.text = details.tagline
                descriptionLabel.text = details.plot
                genereLabel.text = details.genres
                awardsLabel.text = details.awards
                
                DispatchQueue.main.async{
                    UIView.transition(with: self.detailsStackView,
                                      duration: 0.7,
                                      options: .transitionCrossDissolve,
                                      animations: {self.detailsStackView.isHidden = false}, completion: nil)
                    
                    UIView.animate(withDuration: 0.5, delay: 0, options: .transitionCrossDissolve) {
                        self.detailLabel.text = details.tagline
                    } completion: { _ in }
                }
            } catch {
                let alert = UIAlertController(title: "Error", message: "Unexpected error: \(error).", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in }))
                DispatchQueue.main.async{
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
        }
    }
    
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        if !itemIsInLibrary && !imdb.cart.contains(item) { // Not rented nor in cart, then add to cart
            imdb.cart.insert(item) // then add it
            actionButton.setTitle("Remove from cart", for: .normal)
        } else if imdb.cart.contains(item) { // In cart
            imdb.cart.insert(item) // then remove it
            actionButton.setTitle("Add to cart", for: .normal)
        } else if itemIsInLibrary {
            if let url = URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ") {
                UIApplication.shared.open(url)
            }
        }
    }
}
