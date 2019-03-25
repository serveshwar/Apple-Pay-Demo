//
//  ApplePayPaymentHandler.swift
//  ApplePayDemo
//
//  Created by Misra Serveshwar on 25/03/19.
//  Copyright © 2019 Misra Serveshwar. All rights reserved.
//

import UIKit
import PassKit

/// Block called when payment handler finishes payment process or when user presses cancel button.
typealias PaymentCompletionHandler = (Bool) -> Void

/// Class to handle payment via Apple Pay
class PaymentHandler: NSObject {
    
    /// Hold supported payment networks
    static let supportedNetworks: [PKPaymentNetwork] = [
        .amex,
        .discover,
        .masterCard,
        .visa
    ]
    
    /// Total amount for payment
    var totalAmount: NSDecimalNumber!
    
    /// Apple pay sheet
    var paymentController: PKPaymentAuthorizationController?
    
    /// Payment summary items been displayed on apple pay sheet
    var paymentSummaryItems = [PKPaymentSummaryItem]()
    
    /// Status of payment
    var paymentStatus = PKPaymentAuthorizationStatus.failure
    
    /// Block called when payment handler finishes payment process or when user presses cancel button.
    var completionHandler: PaymentCompletionHandler?
    
    /// Method which checks and returns if Apple pay is supported on user device.
    ///
    /// - Returns: Tuple having information if apple pay can be used
    class func applePayStatus() -> (canMakePayments: Bool, canSetupCards: Bool) {
        return (PKPaymentAuthorizationController.canMakePayments(),
                PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks));
    }
    
    /// Method which sets up Apple pay payment request in desired format and presents Apple Pay sheet.
    ///
    /// - Parameter completion: Block called when payment process ends.
    func startPayment(completion: @escaping PaymentCompletionHandler) {
        
        /// Create payment summary items
        let price = PKPaymentSummaryItem(label: "Cart Price", amount: NSDecimalNumber(string: "200.00"), type: .final)
        let tax = PKPaymentSummaryItem(label: "Tax", amount: NSDecimalNumber(string: "20.88"), type: .final)
        let total = PKPaymentSummaryItem(label: "Shop Easy", amount: NSDecimalNumber(string: "220.88"), type: .final)
        
        paymentSummaryItems = [price, tax, total];
        completionHandler = completion
        totalAmount = total.amount
        
        // Create payment request
        let paymentRequest = PKPaymentRequest()
        paymentRequest.paymentSummaryItems = paymentSummaryItems
        paymentRequest.merchantIdentifier = Configuration.Merchant.identififer
        paymentRequest.merchantCapabilities = .capability3DS
        paymentRequest.countryCode = "IN"
        paymentRequest.currencyCode = "INR"
        paymentRequest.requiredShippingContactFields = [.phoneNumber, .emailAddress]
        paymentRequest.supportedNetworks = PaymentHandler.supportedNetworks
        
        // Display payment request using PKPaymentAuthorizationController
        paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController?.delegate = self
        paymentController?.present(completion: { (presented: Bool) in
            if presented {
                NSLog("Presented payment controller")
            } else {
                NSLog("Failed to present payment controller")
                self.completionHandler!(false)
            }
        })
    }
}

// MARK: -  PKPaymentAuthorizationControllerDelegate conformance.
extension PaymentHandler: PKPaymentAuthorizationControllerDelegate {
    
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didAuthorizePayment payment: PKPayment,
                                        completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        
        // Perform validation as applicable
        if payment.shippingContact?.emailAddress == nil || payment.shippingContact?.phoneNumber == nil {
            paymentStatus = .failure
        } else {
            // Here we will send the payment token to our middleware server which will further send the data to payment
            // gateway. Once processed, return an appropriate status in the completion handler (success, failure, etc)
            paymentStatus = .success
        }
        
        completion(paymentStatus)
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            DispatchQueue.main.async {
                if self.paymentStatus == .success {
                    self.completionHandler!(true)
                } else {
                    self.completionHandler!(false)
                }
            }
        }
    }
    
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
                                        completion: @escaping ([PKPaymentSummaryItem]) -> Void) {
        // The didSelectPaymentMethod delegate method allows you to make changes when user updates their payment card
        // Here we're applying an INR 2 discount when an unknown card is selected
        if paymentMethod.type == .unknown {
            var discountedSummaryItems = paymentSummaryItems
            let discount = PKPaymentSummaryItem(label: "Card Discount", amount: NSDecimalNumber(string: "-6.00"))
            discountedSummaryItems.insert(discount, at: paymentSummaryItems.count - 1)
            if let total = paymentSummaryItems.last {
                // Prepare discounted total by adding (discount is negative number) discount to total
                let discountedTotal = totalAmount.adding(discount.amount)
                total.amount = discountedTotal
            }
            completion(discountedSummaryItems)
        } else {
            completion(paymentSummaryItems)
        }
    }
}
