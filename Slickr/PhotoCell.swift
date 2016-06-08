//
//  PhotoCell.swift
//  Slickr
//
//  Created by Bas Pellis on 07/06/16.
//  Copyright © 2016 WebComrades. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

class PhotoCell: UITableViewCell {

    var request: Alamofire.Request?
    var url: String? {
        didSet {
            request?.cancel()
            if url != nil {
                request = loadPhoto(url!, completion: { (image) in
                    self.photoImageView.image = image
                })
            }
            else {
                self.photoImageView.image = nil
            }
        }
    }
    @IBOutlet weak var photoImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        photoImageView.image = nil
    }
    
    func loadPhoto(url: String, completion: (image: Image) -> Void) -> Alamofire.Request {
        return Alamofire.request(.GET, url)
            .responseImage { response in
                if let image = response.result.value as Image! {
                    completion(image: image)
                }
        }
    }

}
