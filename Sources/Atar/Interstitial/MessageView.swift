//
//  File.swift
//  
//
//  Created by Alex Austin on 4/9/24.
//

import UIKit
import WebKit

class MessageView: UIView, WKNavigationDelegate {
    private let contentView = UIView()
    private var webView: WKWebView!
    private let tapView = UIView()
    private var tapAction: (() -> Void)?
    private let viewHeight: CGFloat = 110  // Adjust based on standard notification size
    private let viewWidth: CGFloat = UIScreen.main.bounds.width - 20 // Assuming 10 points padding on each side
    private let cornerRadius: CGFloat = 10
    
    init(url: URL, tapAction: (() -> Void)?) {
        super.init(frame: CGRect(x: 10, y: -viewHeight, width: viewWidth, height: viewHeight))
        self.webView = WKWebView()
        self.webView.navigationDelegate = self
        self.tapAction = tapAction
        setupWebView(url: url)
        configureAppearance()
        setupTapView()
        addTapGestureRecognizer()
        Logger.shared.log("Atar message view created with url: \(url)")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupWebView(url: URL) {
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
    
    @objc private func viewTapped() {
        Logger.shared.log("Atar message view tapped")
        tapAction?()
        hide()
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
        // Handle loading errors here
        Logger.shared.log("Web view did fail loading with error: \(error)")
    }
    
    private func show() {
        guard let keyWindow = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else { return }
        
        keyWindow.addSubview(self)
        
        self.frame = CGRect(x: 10, y: -viewHeight, width: viewWidth, height: viewHeight)
        
        UIView.animate(withDuration: 0.5) {
            self.frame = CGRect(x: 10, y: 40, width: self.viewWidth, height: self.viewHeight) // 40 for status bar & some space
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.hide()
        }
    }
    
    private func hide() {
        UIView.animate(withDuration: 0.5, animations: {
            self.frame = CGRect(x: 10, y: -self.viewHeight, width: self.viewWidth, height: self.viewHeight)
        }) { _ in
            self.removeFromSuperview()
        }
    }
}
