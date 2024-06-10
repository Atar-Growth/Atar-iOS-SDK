//
//  File.swift
//
//
//  Created by Alex Austin on 4/9/24.
//

import UIKit
import WebKit
import StoreKit

class MessageView: UIView, WKNavigationDelegate, WKScriptMessageHandler, SKOverlayDelegate {
    private let contentView = UIView()
    private var webView: WKWebView!
    private var clickWebView: WKWebView!
    private let tapView = UIView()
    private let cornerRadius: CGFloat = 10
    private var lastOfferRequest: OfferRequest?
    private var offerObject: [String: String]?
    private var processedClick = false
    private var isShown = false
    private var hideInProgress = false
    
    private var viewHeight: CGFloat {
        return UIScreen.main.bounds.height * 0.15
    }
    
    private var viewWidth: CGFloat {
        let calculatedWidth = viewHeight * 3.2
        let maxWidth = UIScreen.main.bounds.width * 0.95
        return min(calculatedWidth, maxWidth)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configureAndShow(withRequest request: OfferRequest) {
        let url = OfferFetcher.getMessageWebUrl(with: request)!
        setupWebView(url: url)
        configureAppearance()
        setupTapView()
        addTapGestureRecognizer()
        addSwipeGestureRecognizer()
        lastOfferRequest = request
        Logger.shared.log("Atar message view created with url: \(url)")
    }
    
    private func setupWebView(url: URL) {
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.navigationDelegate = self
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
            webView.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
            webView.rightAnchor.constraint(equalTo: rightAnchor, constant: -10),
        ])
        webView.layer.cornerRadius = cornerRadius // Apply corner radius to webView
        webView.clipsToBounds = true
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = true
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        
        let contentController = webView.configuration.userContentController
        contentController.add(self, name: "cb")
        
        webView.load(URLRequest(url: url))
    }
    
    private func setupTapView() {
        tapView.backgroundColor = .clear
        addSubview(tapView)
        
        // Set constraints to match the webView's frame
        tapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tapView.topAnchor.constraint(equalTo: webView.topAnchor),
            tapView.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            tapView.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            tapView.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
    }
    
    private func addTapGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapView.addGestureRecognizer(tapGesture)
    }
    private func addSwipeGestureRecognizer() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(viewTapped))
        swipeGesture.direction = .up // You can change the direction as needed
        tapView.addGestureRecognizer(swipeGesture)
    }
    
    @objc private func viewTapped() {
        Logger.shared.log("Atar message view tapped")
        loadOverlay(andRoute: true)
        processClickURLAsync()
        if lastOfferRequest?.onClicked != nil {
            lastOfferRequest?.onClicked!()
        }
        hide()
    }
    
    @objc private func viewSwiped() {
        Logger.shared.log("Atar message view tapped")
        loadOverlay(andRoute: false)
        processClickURLAsync()
        if lastOfferRequest?.onPopupCanceled != nil {
            lastOfferRequest?.onPopupCanceled!()
        }
        hide()
    }
    
    private func processClickURLAsync() {
        guard let clickUrlString = offerObject?["clickUrl"],
              let clickUrl = URL(string: clickUrlString) else {
            return
        }
        
        if !processedClick {
            let webViewConfiguration = WKWebViewConfiguration()
            webViewConfiguration.preferences.javaScriptEnabled = true
            
            clickWebView = WKWebView(frame: .zero, configuration: webViewConfiguration)
            clickWebView.isHidden = true
            clickWebView.navigationDelegate = self
            addSubview(clickWebView)
            
            let urlRequest = URLRequest(url: clickUrl)
            clickWebView.load(urlRequest)
        
            processedClick = true
            Logger.shared.log("Atar message view click url: \(clickUrl)")
        }
    }
    
    func extractAppStoreID(from urlString: String) -> String? {
        let pattern = "/id([0-9]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsString = urlString as NSString
        let results = regex.matches(in: urlString, options: [], range: NSRange(location: 0, length: nsString.length))

        if let match = results.first {
            let idRange = match.range(at: 1)
            return nsString.substring(with: idRange)
        }

        return nil
    }
    
    private func loadOverlay(andRoute: Bool) {
        if (processedClick) {
            return
        }
        if let appStoreUrl = offerObject?["destinationUrl"] {
            if #available(iOS 14.0, *) {
                if let id = extractAppStoreID(from: appStoreUrl) {
                    guard let keyWindow = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else { return }
                    guard let scene = keyWindow.windowScene else { return }
                    
                    let config = SKOverlay.AppConfiguration(appIdentifier: id, position: .bottomRaised)
                    let overlay = SKOverlay(configuration: config)
                    overlay.present(in: scene)
                } else if (andRoute) {
                    // Fallback to open the App Store page
                    if UIApplication.shared.canOpenURL(URL(string: appStoreUrl)!) {
                        UIApplication.shared.open(URL(string: appStoreUrl)!, options: [:], completionHandler: nil)
                    }
                }
            } else if (andRoute) {
                // Fallback to open the App Store page
                if UIApplication.shared.canOpenURL(URL(string: appStoreUrl)!) {
                    UIApplication.shared.open(URL(string: appStoreUrl)!, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    private func configureAppearance() {
        backgroundColor = .clear
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 6
        
        layer.shadowPath = UIBezierPath(roundedRect: CGRect(x: 10, y: 25, width: self.viewWidth-20, height: self.viewHeight-20), cornerRadius: cornerRadius).cgPath
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        Logger.shared.log("Atar message view decide policy for navigation action: \(navigationAction.request.url?.absoluteString ?? "nil")")
        if let url = navigationAction.request.url {
            // Check if the URL contains "apps.apple" or "itunes.apple"
            if url.host?.contains("apps.apple") == true || url.host?.contains("itunes.apple") == true {
                decisionHandler(.cancel)
                return
            }
            
            // Convert http to https
            if url.scheme == "http" {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.scheme = "https"
                if let secureURL = components?.url {
                    let secureRequest = URLRequest(url: secureURL)
                    webView.load(secureRequest)
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Logger.shared.log("Atar message view loaded")
        show()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Logger.shared.log("Web view did fail loading with error: \(error)")
        hide()
    }
    
    private func show() {
        if isShown {
            return
        }
        isShown = true
        
        guard let keyWindow = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else { return }
        
        keyWindow.addSubview(self)
        
        self.frame = CGRect(x: (UIScreen.main.bounds.width - viewWidth) / 2, y: -viewHeight, width: viewWidth, height: viewHeight)
        
        UIView.animate(withDuration: 0.5) {
            self.frame = CGRect(x: (UIScreen.main.bounds.width - self.viewWidth) / 2, y: 40, width: self.viewWidth, height: self.viewHeight)
        }
        
        if lastOfferRequest?.onPopupShown != nil {
            lastOfferRequest?.onPopupShown?(true, nil)
        }
        
        if (ConfigurationManager.shared.midSessionMessageVibrate) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }

        if !ConfigurationManager.shared.midSessionMessageVTA {
            Logger.shared.log("VTA disabled from app config")
            return
        }
        var vtaDelay = 3
        if ConfigurationManager.shared.midSessionMessageOverlayDelay > 0 {
            vtaDelay = ConfigurationManager.shared.midSessionMessageOverlayDelay/1000
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(vtaDelay)) {
            if self.offerObject != nil && self.offerObject!["vta"] != "false" {
                self.loadOverlay(andRoute: false)
                self.processClickURLAsync()
            }
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        Logger.shared.log("Received message from web: \(message.name): \(message.body)")
        if message.name == "cb" {
            if let jsonString = message.body as? String,
               let jsonData = jsonString.data(using: .utf8) {
                do {
                    let offerObj = try JSONSerialization.jsonObject(with: jsonData) as? [String: String]
                    if offerObj == nil {
                        Logger.shared.log("Error parsing JSON from message body: \(jsonData)")
                        hide()
                        return
                    }
                    offerObject = offerObj
                } catch {
                    Logger.shared.log("Error parsing JSON from message body: \(error)")
                    hide()
                }
            }
        }
    }
    
    private func hide() {
        if hideInProgress {
            return
        }
        hideInProgress = true
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Animate the layer's position
        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = self.layer.position
        animation.toValue = CGPoint(x: self.layer.position.x, y: self.layer.position.y - self.viewHeight - 40)
        animation.duration = 0.5

        self.layer.add(animation, forKey: "position")
        self.layer.position.y -= self.viewHeight + 40

        CATransaction.commit()

        // Remove the view from the superview after the animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.removeFromSuperview()
        }
    }
    
}
