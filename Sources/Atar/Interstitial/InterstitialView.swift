//
//  InterstitialView.swift
//
//
//  Created by Alex Austin on 4/5/24.
//

import UIKit
import WebKit

class InterstitialView: UIView, WKNavigationDelegate, WKScriptMessageHandler {
    private let contentView = UIView()
    private let webView: WKWebView
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let closeButton = UIButton()
    private var lastOfferRequest: OfferRequest?

    // Configure with parameters for image URL and text
    func configure(withRequest request: OfferRequest) {
        lastOfferRequest = request
        let url = OfferFetcher.getOfferWebUrl(with: request)
        let webRequest = URLRequest(url: url!)
        webView.load(webRequest)
    }

    override init(frame: CGRect) {
        let config = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.loadHTMLString("", baseURL: nil)
        
        super.init(frame: frame)

        // Now that 'self' is fully initialized, set up the content controller.
        let contentController = self.webView.configuration.userContentController
        contentController.add(self, name: "cb")

        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        // Content view configuration
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12.0
        contentView.clipsToBounds = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.contentInset = UIEdgeInsets.zero
        webView.scrollView.bounces = false
        webView.navigationDelegate = self
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0
        contentView.addSubview(webView)

        // Activity Indicator configuration
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("x", for: .normal)
        closeButton.titleLabel?.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .regular)
        closeButton.setTitleColor(.gray, for: .normal)
        closeButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        addSubview(closeButton)

        setupConstraints()
        
    }
    
    private func setupConstraints() {
        var interstitialAdHeight = ConfigurationManager.shared.interstitialAdHeight
        if interstitialAdHeight == 0.0 {
            interstitialAdHeight = 0.8
        }
        NSLayoutConstraint.activate([
            contentView.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.9),
            contentView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: interstitialAdHeight),
            
            webView.topAnchor.constraint(equalTo: contentView.topAnchor),
            webView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            webView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            closeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    func show() {
        guard let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else { return }

        self.alpha = 0.6
        self.frame = window.bounds
        window.addSubview(self)

        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
        
        if let offerRequest = lastOfferRequest {
            offerRequest.onPopupShown?(true, nil)
        }
    }

    @objc func cancel() {
        dismiss()
        OfferFetcher.logOfferInteraction(with: [:], forEvent: "popup-cancel")
        if let offerRequest = lastOfferRequest {
            offerRequest.onPopupCanceled?()
        }
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
    
    // WKNavigationDelegate method to stop the indicator when content is loaded
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Logger.shared.log("Web URL loaded")
        activityIndicator.stopAnimating()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        Logger.shared.log("Received message from web: \(message.name): \(message.body)")
        if message.name == "cb" {
            // Attempt to parse the JSON string into a dictionary
            if let jsonString = message.body as? String,
               let jsonData = jsonString.data(using: .utf8) {
                do {
                    let clickObj = try JSONSerialization.jsonObject(with: jsonData) as? [String: String]
                    if let clickObj = clickObj {
                        SessionEndMonitor.shared.justClicked = true
                        UIApplication.shared.open(URL(string: clickObj["clickUrl"]!)!, options: [:], completionHandler: nil)
                        OfferFetcher.logOfferInteraction(with: [:], forEvent: "popup-tap")
                    }
                } catch {
                    Logger.shared.log("Error parsing JSON from message body: \(error)")
                    cancel();
                }
            }
        }
        if let offerRequest = lastOfferRequest {
            offerRequest.onClicked?()
        }
        dismiss()
    }
}
