//
//  CartViewController.swift
//  MovieTime
//
//  Created by Alejandro Quezada on 17/02/22.
//

import UIKit

class CartViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var cartTableView: UITableView!
    
    let imdb = IMDBConnect.sharedInstance
    var cartItems = [IMDBItem]()
    var posterImagesForIMDBId: [String: UIImage] = [:]
    @IBOutlet weak var totalTextLabel: UILabel!
    @IBOutlet weak var rentAllButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cartTableView.delegate = self
        cartTableView.dataSource = self
        rentAllButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        cartItems = imdb.cart.sorted(by: {$0.title > $1.title})
        calculateTotal()
        rentAllButton.isEnabled = cartItems.count > 0
        cartTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Make sure that the total is updated when the cart changes
        rentAllButton.isEnabled = cartItems.count > 0
        calculateTotal()
        return cartItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartCell", for: indexPath) as! CartCell
        let item = cartItems[indexPath.item]
        cell.item = item
        cell.titleLable.text = item.title
        cell.priceLabel.text = "$\(imdb.itemUnitPrice)"
        
        // If we have the poster image, set it
        if let posterImage = posterImagesForIMDBId[item.imdbID] {
            cell.posterImageView.image = posterImage
            cell.backgroundColor = UIColor.clear
        } else { // Else, show the title as placeholder. We will fetch the poster at collectionView(_:willDisplay:forItemAt:)
            cell.posterImageView.backgroundColor = UIColor.lightGray
            cell.posterImageView.image = nil
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let item = cartItems[indexPath.item]
        let cartCell = cell as! CartCell

        // Check if the poster is actually being displayed,
        // otherwise a race condidion may cause the image to be saved but not displayed
        if cartCell.posterImageView.image != nil { return }
        Task {
            let posterImage = try! await item.thumbnailPoster.fetch()
            posterImagesForIMDBId[item.imdbID] = posterImage
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] action, view, completionHandler in
            let itemToDelete = self.cartItems[indexPath.row]
            self.cartItems.remove(at: indexPath.row)
            imdb.cart.remove(itemToDelete)
            tableView.deleteRows(at: [indexPath], with: .fade)
            completionHandler(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    @IBAction func rentAllButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Confirm payment", message: "$\(imdb.itemUnitPrice * Double(cartItems.count)) will be paid with your default payment method\nThe titles will be available for 3 days", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Pay", style: .default, handler: { _ in self.rentCart() }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func rentCart() {
        let alert = UIAlertController(title: "Success!", message: "The titles are now in your library", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in }))
        alert.addAction(UIAlertAction(title: "Go to library", style: .cancel) { _ in
            if let libraryVC = self.tabBarController?.viewControllers?[2] as? LibraryViewController {
                libraryVC.isDisplayingFavs = false
            }
            self.tabBarController?.selectedIndex = 2

        })
        self.present(alert, animated: true, completion: nil)
        
        for title in imdb.cart {
            imdb.addToLibrary(item: title)
        }
        
        imdb.cart.removeAll()
        cartItems.removeAll()
        calculateTotal()
        rentAllButton.isEnabled = cartItems.count > 0
        cartTableView.reloadData()
    }

    func calculateTotal() {
        totalTextLabel.text = "Total: $\(imdb.itemUnitPrice * Double(cartItems.count))"
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "cartToDetail" {
            if let destinationVC = segue.destination as? ItemDetailViewController,
               let cell = sender as? CartCell{
                destinationVC.item = cell.item
            }
        }
    }


}
