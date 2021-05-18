//
//  TestPageViewController.swift
//  SlidingHeaderPageViewController
//
//  Created by hlwanhoj on 05/18/2021.
//  Copyright (c) 2021 hlwanhoj. All rights reserved.
//

import UIKit
import TinyConstraints
import Then
import SlidingHeaderPageViewController

class TestPageViewController: UIViewController, PageViewControllerDelegate {
    private let pageLabel = UILabel()
    private let eventLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let pager = PageViewController(interPageSpacing: 8)
        let pagerBgView = UIView()

        addChild(pager)
        view.do({
            $0.addSubview(pagerBgView)
            $0.addSubview(pager.view)
            $0.addSubview(pageLabel)
            $0.addSubview(eventLabel)
        })
        
        pager.do({
            $0.delegate = self
            $0.view.setIsAllSubviewsClippedToBounds(false)
            $0.view.size(CGSize(width: 375, height: 667))
            $0.view.centerInSuperview(offset: .init(x: 0, y: -100))
        })
        
        pagerBgView.do({
            $0.backgroundColor = UIColor.black.withAlphaComponent(0.333)
            $0.left(to: pager.view)
            $0.right(to: pager.view)
            $0.verticalToSuperview()
        })
        
        pageLabel.do({
            $0.textAlignment = .center
            $0.numberOfLines = 2
            $0.font = .systemFont(ofSize: 24)
            $0.topToBottom(of: pager.view, offset: 30)
            $0.centerX(to: pager.view)
        })
        
        eventLabel.do({
            $0.textAlignment = .center
            $0.numberOfLines = 0
            $0.font = .systemFont(ofSize: 24)
            $0.topToBottom(of: pageLabel, offset: 30)
            $0.centerX(to: pager.view)
        })
 
        pager.didMove(toParent: self)

        let vcs: [UIViewController] = [
            UIViewController().then({
                $0.view.backgroundColor = .systemRed
            }),
            UIViewController().then({
                $0.view.backgroundColor = .systemBlue
            }),
            UIViewController().then({
                $0.view.backgroundColor = .systemGreen
            }),
            UIViewController().then({
                $0.view.backgroundColor = .systemYellow
            }),
            UIViewController().then({
                $0.view.backgroundColor = .systemOrange
            }),
        ]
        vcs.enumerated().forEach({ idx, vc in
            let lbl = UILabel()
            lbl.text = "\(idx)"
            lbl.textAlignment = .center
            lbl.font = UIFont.boldSystemFont(ofSize: 120)
            vc.view.addSubview(lbl)
            lbl.edgesToSuperview()
        })
        pager.setPages(vcs, initialPageIndex: 0)
        updatePageLabel(progressivePage: 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //
    
    private func updatePageLabel(progressivePage: CGFloat) {
        pageLabel.text = "Page:\n\(progressivePage)"
    }
    
    
    // MARK: PageViewControllerDelegate
    
    func pageViewController(_ viewController: PageViewController, willTransitToPage pageIndex: Int, pendingViewController: UIViewController) {
        eventLabel.text = "Will transit to \(pageIndex)"
    }
    
    func pageViewController(_ viewController: PageViewController, didUpdateProgressivePage progressivePage: CGFloat) {
        updatePageLabel(progressivePage: progressivePage)
    }
    
    func pageViewController(
        _ viewController: PageViewController,
        didFinishAnimating finished: Bool,
        fromPage fromIndex: Int?,
        toPage toIndex: Int,
        previousViewController: UIViewController?,
        transitionCompleted completed: Bool) {
        eventLabel.text = "Did finish transiting from \(fromIndex ?? -1) to \(toIndex)"
    }
}

private extension UIView {
    func setIsAllSubviewsClippedToBounds(_ isClipped: Bool) {
        clipsToBounds = isClipped
        
        if subviews.isEmpty { return }
        subviews.forEach({
            $0.setIsAllSubviewsClippedToBounds(isClipped)
        })
    }
}
