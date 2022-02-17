//
//  ImagePosterCollectionViewCell.swift
//  MovieTime
//
//  Created by Alejandro Quezada on 16/02/22.
//

import UIKit

class ImagePosterCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var moviePosterImageView: UIImageView!
    @IBOutlet weak var movieTitleLabel: UILabel!
    var item: IMBDItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
}
