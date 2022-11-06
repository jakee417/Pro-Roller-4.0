//
//  UI.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 10/28/22.
//

#if os(iOS) || os(tvOS)

import UIKit

///
/// UIViewController helpers to add and remove child view controllers.
///
@nonobjc extension UIViewController {
    
    /// Add child view controller and embed view
    /// - Parameters:
    ///   - viewController: controller to be added as a child controller
    func add(_ child: UIViewController) {
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
            child.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0),
            child.view.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0),
            child.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
        ])
        child.didMove(toParent: self)
    }
    
    /// Remove child view controller from the parent controller.
    func remove() {
        guard parent != nil else {
            return
        }

        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
    /// Remove all child view controller from the parent controller.
    func removeAll() {
        self.children.forEach { (child) in
            child.remove()
        }
    }
}

#endif
