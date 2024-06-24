//
//  File.swift
//
//
//  Created by Alex Austin on 4/9/24.
//

import UIKit
import WebKit
import StoreKit

class MessageView: UIView, WKNavigationDelegate, WKScriptMessageHandler {
    private let contentView = UIView()
    private var webView: WKWebView!
    private var clickWebView: WKWebView!
    private let tapView = UIView()
    private let cornerRadius: CGFloat = 10
    private var lastOfferRequest: OfferRequest?
    private var offerObject: [String: String]?
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
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(viewSwiped))
        swipeGesture.direction = .up
        tapView.addGestureRecognizer(swipeGesture)
    }
    
    @objc private func viewTapped() {
        Logger.shared.log("Atar message view tapped")
        SessionEndMonitor.shared.justClicked = true
        do {
            if let currOfferObject = offerObject {
                if let clickUrl = URL(string: currOfferObject["clickUrl"]!) {
                    UIApplication.shared.open(clickUrl, options: [:], completionHandler: nil)
                }
            }
        } catch {
            Logger.shared.log("Error processing click")
        }
        OfferFetcher.logOfferInteraction(with: offerObject ?? [:], forEvent: "message-tap")
        hide()
        if lastOfferRequest?.onClicked != nil {
            lastOfferRequest?.onClicked!()
        }
    }
    
    @objc private func viewSwiped() {
        Logger.shared.log("Atar message view swiped")
        hide()
        OfferFetcher.logOfferInteraction(with: offerObject ?? [:], forEvent: "message-cancel")
        if lastOfferRequest?.onPopupCanceled != nil {
            lastOfferRequest?.onPopupCanceled!()
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
        if (lastOfferRequest?.onNotifScheduled != nil) {
            lastOfferRequest?.onNotifScheduled!(true, nil)
        }
        if lastOfferRequest?.onNotifSent != nil {
            lastOfferRequest?.onNotifSent!()
        }
        
        if (ConfigurationManager.shared.midSessionMessageVibrate) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
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
                    let evalUrlQuality = URL(string: offerObj!["clickUrl"]!)
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
