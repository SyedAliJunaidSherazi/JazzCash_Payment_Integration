import Foundation
import UIKit
import WebKit

class PaymentViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    var webView: WKWebView!
    var postData: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up WebView configuration
        let contentController = WKUserContentController()
        contentController.add(self, name: "FORMOUT")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: self.view.frame, configuration: config)
        webView.navigationDelegate = self // Set the navigation delegate here
        self.view.addSubview(webView)

        // Load the payment URL with POST data
        if let url = URL(string: "https://example.com/payment") { // Replace with your payment URL
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            // NOTE: Replace 'postData' with actual data you need to send
            request.httpBody = postData.data(using: .utf8)
            webView.load(request)
        }
    }

    // WKNavigationDelegate method to handle URL navigation policies
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url?.absoluteString, url == "https://example.com/payment/callback" { // Replace with your callback URL
            // Handle payment response
            decisionHandler(.cancel)
            // Optionally, process the response here (or pass it back to Flutter)
            NotificationCenter.default.post(name: NSNotification.Name("PaymentResponse"), object: nil, userInfo: ["response": url])
        } else {
            decisionHandler(.allow)
        }
    }

    // WKScriptMessageHandler method
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "FORMOUT", let response = message.body as? String {
            // Process the response and send it back to Flutter
            let resultDict: [String: Any] = ["response": response]
            NotificationCenter.default.post(name: NSNotification.Name("PaymentResponse"), object: nil, userInfo: resultDict)
        }
    }

    // WKNavigationDelegate methods
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView did finish loading")
        // Inject JavaScript to capture form data
        let jsCode = """
        function parseForm(form) {
            var values = '';
            for (var i = 0; i < form.elements.length; i++) {
                values += form.elements[i].name + '=' + form.elements[i].value + '&';
            }
            window.webkit.messageHandlers.FORMOUT.postMessage(values);
        }
        if (document.forms.length > 0) {
            parseForm(document.forms[0]);
        }
        """
        webView.evaluateJavaScript(jsCode) { (result, error) in
            if let error = error {
                print("JavaScript Error: \(error.localizedDescription)")
            } else {
                print("JavaScript executed successfully")
            }
        }
    }

    // Handle SSL Certificate Challenges
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // NOTE: For production use, make sure to handle SSL certificate verification properly.
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }
}