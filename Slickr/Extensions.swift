//
//  Extensions.swift
//  Slickr
//
//  Created by Bas Pellis on 07/06/16.
//  Copyright © 2016 WebComrades. All rights reserved.
//

import Foundation

extension Dictionary {
    func combinedWith(other: Dictionary<Key,Value>) -> Dictionary<Key,Value> {
        var combined = other
        for (key, value) in self {
            combined[key] = value
        }
        return combined
    }
}