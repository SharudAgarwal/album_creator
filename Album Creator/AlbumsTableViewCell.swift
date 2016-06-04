//
//  AlbumsTableViewCell.swift
//  Album Creator
//
//  Created by Sharud Agarwal on 5/31/16.
//  Copyright © 2016 agarwals. All rights reserved.
//

import UIKit

class AlbumsTableViewCell: UITableViewCell {

    @IBOutlet weak var AlbumImageView: UIImageView!
    @IBOutlet weak var AlbumNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
