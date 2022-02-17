//
//  File.swift
//  MovieTime
//
//  Created by Alejandro Quezada on 16/02/22.
//

import UIKit

class LibraryViewController: UIViewController, BrowseViewDelegate {
    @IBOutlet weak var browseView: BrowseView!
    
    let imdb = IMDBConnect()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        browseView.delegate = self
        
        Task {
            browseView.IMDBItems = try! await imdb.getPopular(contentType: .TVShow)
            browseView.itemCollectionView.reloadData()
        }
    }
    
    func browseView(_ browseView: BrowseView, didSelectItemAt indexPath: IndexPath) {
        let senderCell = browseView.itemCollectionView.cellForItem(at: indexPath)
        performSegue(withIdentifier: "goToDetailFromLibrary", sender: senderCell)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetailFromLibrary" {
            if let destinationVC = segue.destination as? ItemDetailViewController,
               let cell = sender as? ImagePosterCollectionViewCell{
                destinationVC.item = cell.item
            }
        }
    }
    
}
