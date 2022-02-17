//
//  File.swift
//  MovieTime
//
//  Created by Alejandro Quezada on 16/02/22.
//

import UIKit

class LibraryViewController: UIViewController, BrowseViewDelegate, UIAdaptivePresentationControllerDelegate {
    @IBOutlet weak var browseView: BrowseView!
    
    let imdb = IMDBConnect.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        browseView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        browseView.IMDBItems = imdb.favorites.sorted(by: {$0.title > $1.title})
        browseView.itemCollectionView.reloadData()
    }
    
    
    func browseView(_ browseView: BrowseView, didSelectItemAt indexPath: IndexPath) {
        let senderCell = browseView.itemCollectionView.cellForItem(at: indexPath)
        performSegue(withIdentifier: "goToDetailFromLibrary", sender: senderCell)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToDetailFromLibrary" {
            if let destinationVC = segue.destination as? ItemDetailViewController,
               let cell = sender as? ImagePosterCollectionViewCell {
                destinationVC.presentationController?.delegate = self
                destinationVC.item = cell.item
            }
        }
    }
    
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController)
    {
        // Only called when the sheet is dismissed by DRAGGING.
        // You'll need something extra if you call .dismiss() on the child.
        // (I found that overriding dismiss in the child and calling
        // presentationController.delegate?.presentationControllerDidDismiss
        // works well).
        
        browseView.IMDBItems = imdb.favorites.sorted(by: {$0.title > $1.title})
        browseView.itemCollectionView.reloadData()
        
    }
    
}
