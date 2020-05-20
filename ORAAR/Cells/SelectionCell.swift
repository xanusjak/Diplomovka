//
//  SelectionCell.swift
//  ORAAR
//
//  Created by Anušjak, Milan on 24/02/2020.
//  Copyright © 2020 Anušjak, Milan. All rights reserved.
//

import UIKit
import QuickLookThumbnailing

class SelectionCell: UITableViewCell {

    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    
    var objectName: String = "" {
        didSet {
            self.generateThumbnailRepresentations(name: objectName)
            self.nameLabel.text = objectName
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func generateThumbnailRepresentations(name: String) {
        
        // Set up the parameters of the request.
        guard let url = Bundle.main.url(forResource: name, withExtension: "usdz", subdirectory: "Assets.scnassets") else {
            // Handle the error case.
            assert(false, "The URL can't be nil")
            return
        }
        let size: CGSize = CGSize(width: 40, height: 40)
        let scale = UIScreen.main.scale
        
        // Create the thumbnail request.
        let request = QLThumbnailGenerator.Request(fileAt: url,
                                                   size: size,
                                                   scale: scale,
                                                   representationTypes: .thumbnail)
        
        // Retrieve the singleton instance of the thumbnail generator and generate the thumbnails.
        let generator = QLThumbnailGenerator.shared
        generator.generateRepresentations(for: request) { (thumbnail, type, error) in
            DispatchQueue.main.async {
                self.thumbnailImageView.image = thumbnail?.uiImage
            }
        }
    }

}
