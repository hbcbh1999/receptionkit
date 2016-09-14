//
//  VisitorViewController.swift
//  ReceptionKit
//
//  Created by Andy Cho on 2015-04-24.
//  Copyright (c) 2015 Andy Cho. All rights reserved.
//

import UIKit

class VisitorViewController: ReturnToHomeViewController {

    // Name of the visitor set by VisitorAskNameViewController
    var visitorName: String?

    @IBOutlet weak var knowButton: UIButton!
    @IBOutlet weak var notKnowButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        knowButton.setAttributedTitle(ButtonFormatter.getAttributedString(icon: .iKnow, text: .iKnow), for: UIControlState())
        knowButton.accessibilityLabel = Text.iKnow.accessibility()

        notKnowButton.setAttributedTitle(ButtonFormatter.getAttributedString(icon: .iDontKnow, text: .iDontKnow), for: UIControlState())
        notKnowButton.accessibilityLabel = Text.iDontKnow.accessibility()

        resetButtonVerticalAlignment(view.bounds.size)
    }

    // Centre align the button text - left-aligned by default
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        knowButton.titleLabel?.textAlignment = NSTextAlignment.center
    }


    // Reset the alignment of the text on rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        resetButtonVerticalAlignment(size)
    }

    func resetButtonVerticalAlignment(_ size: CGSize) {
        if size.width < size.height {
            // Vertical - alignment doesn't matter
            knowButton.contentVerticalAlignment = .center
            notKnowButton.contentVerticalAlignment = .center
        } else {
            // Horizontal - align to top
            knowButton.contentVerticalAlignment = .top
            notKnowButton.contentVerticalAlignment = .top
        }
    }

    // MARK: - Navigation

    // Should post message if the visitor does not know who they are looking for
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let waitingViewController = segue.destination as? WaitingViewController {
            // Configure the view model
            let waitingViewModel = WaitingViewModel(shouldAskToWait: true)
            waitingViewController.configure(waitingViewModel)

            // We don't know the name of the person who just checked in
            guard let visitorName = visitorName, !visitorName.isEmpty else {
                messageSender.sendMessage(.unknownVisitorUnknownVisitee())
                return
            }

            // We know the visitor's name but they don't know the person they're looking for
            messageSender.sendMessage(.knownVisitorUnknownVisitee(visitorName: visitorName))
        } else if let visitorSearchViewController = segue.destination as? VisitorSearchViewController {
            visitorSearchViewController.configure(VisitorSearchViewModel(visitorName: visitorName))
        }
    }

}
