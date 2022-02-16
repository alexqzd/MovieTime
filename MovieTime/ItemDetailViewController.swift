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
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var detailsStackView: UIStackView!
    
    var item: IMBDItem!
    
    let imdb = IMDBConnect()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        titleLabel.text = item.title
        headerImageView.backgroundColor = .lightGray
        detailLabel.text = ""
        detailsStackView.isHidden = true
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
}
