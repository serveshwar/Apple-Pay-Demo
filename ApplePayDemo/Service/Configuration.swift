//
//  Configuration.swift
//  ApplePayDemo
//
//  Created by Misra Serveshwar on 25/03/19.
//  Copyright © 2019 Misra Serveshwar. All rights reserved.
//

import Foundation

/// Class to provide configuration for Apple Pay
public class Configuration {

    /// App's main bundle
    private struct MainBundle {
        static var prefix = Bundle.main.object(forInfoDictionaryKey: "ApplePayDemoBundlePrefix") as? String ?? ""
    }

    /// Merchant identifier
    struct Merchant {
        static let identififer = MainBundle.prefix
    }
}
