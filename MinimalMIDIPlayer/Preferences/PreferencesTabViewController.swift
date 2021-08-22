//
//  PreferencesTabViewController.swift
//  MinimalMIDIPlayer
//
//  Created by Peter Wunder on 19.11.20.
//  Copyright © 2020 Peter Wunder. All rights reserved.
//

import Foundation

class PreferencesTabViewController: NSTabViewController {
	
	private lazy var tabViewSizes: [String: NSSize] = [:]
	
	override func viewDidLoad() {
		if let viewController = self.tabViewItems.first?.viewController, let title = viewController.title {
			self.tabViewSizes[title] = viewController.view.frame.size
		}
		
		super.viewDidLoad()
	}
	
	override func viewDidAppear() {
		if let window = self.view.window, let newTitle = self.tabViewItems.first?.viewController?.title {
			window.title = newTitle
		}
	}
	
	override func transition(from fromViewController: NSViewController, to toViewController: NSViewController, options: NSViewController.TransitionOptions, completionHandler completion: (() -> Void)?) {
		if let window = self.view.window, let newTitle = toViewController.title {
			window.title = newTitle
		}
		
		NSAnimationContext.runAnimationGroup({ context in
			self.animateWindowFrame(viewController: toViewController)
			super.transition(from: fromViewController, to: toViewController, options: self.transitionOptions, completionHandler: completion)
		}, completionHandler: nil)
	}
	
	func animateWindowFrame(viewController: NSViewController) {
		guard let title = viewController.title, let window = self.view.window else {
			return
		}
		
		let contentSize: NSSize
		
		if self.tabViewSizes.keys.contains(title) {
			contentSize = self.tabViewSizes[title]!
		} else {
			contentSize = viewController.view.frame.size
			self.tabViewSizes[title] = contentSize
		}
		
		let newWindowSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize)).size
		
		var frame = window.frame
		frame.origin.y += frame.height
		frame.origin.y -= newWindowSize.height
		frame.size = newWindowSize
		window.animator().setFrame(frame, display: false)
	}
}
