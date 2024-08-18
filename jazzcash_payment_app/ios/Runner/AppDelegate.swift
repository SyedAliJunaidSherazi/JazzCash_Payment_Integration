import UIKit
import Flutter
import WebKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    private var result: FlutterResult?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let paymentChannel = FlutterMethodChannel(name: "com.example.jazzcash_payment_app/performPayment",
                                                  binaryMessenger: controller.binaryMessenger)

        paymentChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "performPayment" {
                self?.result = result
                if let args = call.arguments as? [String: String], let postData = args["postData"] {
                    self?.performPayment(postData: postData)
                }
            }
        }

        // Register to receive notifications when the payment response is received
        NotificationCenter.default.addObserver(self, selector: #selector(self.paymentResponseReceived(_:)), name: NSNotification.Name("PaymentResponse"), object: nil)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func performPayment(postData: String) {
        let paymentVC = PaymentViewController()
        paymentVC.postData = postData

        // Present the PaymentViewController to handle the payment
        let navigationController = UINavigationController(rootViewController: paymentVC)
        window?.rootViewController?.present(navigationController, animated: true, completion: nil)
    }

    // Method to handle the payment response from the PaymentViewController
    @objc private func paymentResponseReceived(_ notification: Notification) {
        if let response = notification.userInfo?["response"] as? String {
            result?(response)
        } else {
            result?(FlutterError(code: "ERROR", message: "No response from payment gateway", details: nil))
        }

        // Reset the result after processing the response
        result = nil
    }

    override func applicationWillTerminate(_ application: UIApplication) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("PaymentResponse"), object: nil)
    }
}