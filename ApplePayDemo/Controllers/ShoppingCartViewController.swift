//
//  ViewController.swift
//  ApplePayDemo
//
//  Created by Misra Serveshwar on 25/03/19.
//  Copyright © 2019 Misra Serveshwar. All rights reserved.
//

import UIKit
import PassKit
import MapKit

/// Class to display shopping cart and Apple Pay button
class ShoppingCartViewController: UIViewController {
    
    /// View carrying Apple pay button
    @IBOutlet weak var applePayView: UIView!
    
    /// Payment handler instance
    var paymentHandler: PaymentHandler!
    
    override func viewDidLoad() {
        // Check if Apple pay is supported on user's device
        let result = PaymentHandler.applePayStatus();
        var button: UIButton?
        
        if result.canMakePayments {
            // If Apple pay supported then display Buy with Apple Pay button
            button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
            button?.addTarget(self, action: #selector(ShoppingCartViewController.payPressed), for: .touchUpInside)
        } else if result.canSetupCards {
            // If Apple pay is supported but user's wallet app is not configured then display setup button
            button = PKPaymentButton(paymentButtonType: .setUp, paymentButtonStyle: .black)
            button?.addTarget(self, action: #selector(ShoppingCartViewController.setupPressed), for: .touchUpInside)
        }
        
        // Add Apple pay button
        if button != nil {
            button!.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
            applePayView.addSubview(button!)
        }
        
    }
    
    /// Method called when Buy with Apple pay button is pressed.
    ///
    /// - Parameter sender: Object invoking this method
    @objc func payPressed(sender: AnyObject) {
        paymentHandler = PaymentHandler()
        paymentHandler.startPayment() { (success) in
            if success {
                self.performSegue(withIdentifier: "OrderPlacedSegue", sender: self)
            }
        }
    }
    
    /// Method called when Setup Apple Pay button is pressed.
    ///
    /// - Parameter sender: Object invoking this method
    @objc func setupPressed(sender: AnyObject) {
        let passLibrary = PKPassLibrary()
        passLibrary.openPaymentSetup()
    }
}

