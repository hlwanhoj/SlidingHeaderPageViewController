//
//  PageViewController.swift
//  SlidingHeaderPageViewController
//
//  Created by hlwanhoj on 18/5/2021.
//

import UIKit

public protocol PageViewControllerDelegate: class {
    func pageViewController(_ viewController: PageViewController, willTransitToPage pageIndex: Int, pendingViewController: UIViewController)
    func pageViewController(_ viewController: PageViewController, didUpdateProgressivePage progressivePage: CGFloat)
    func pageViewController(
        _ viewController: PageViewController,
        didFinishAnimating finished: Bool,
        fromPage fromIndex: Int?,
        toPage toIndex: Int,
        previousViewController: UIViewController?,
        transitionCompleted completed: Bool)
}

public extension PageViewControllerDelegate {
    func pageViewController(_ viewController: PageViewController, willTransitToPage pageIndex: Int, pendingViewController: UIViewController) {}
    func pageViewController(_ viewController: PageViewController, didUpdateProgressivePage: CGFloat) {}
    func pageViewController(
        _ viewController: PageViewController,
        didFinishAnimating finished: Bool,
        fromPage fromIndex: Int?,
        toPage toIndex: Int,
        previousViewController: UIViewController?,
        transitionCompleted completed: Bool
    ) {}
}

// MARK: -

/// A pager
public class PageViewController: UIViewController {
    /// Spacing between pages
    public let interPageSpacing: CGFloat
    private let pageViewController: UIPageViewController

    /// Whether or not to loop the pages when scroll exceeds the page limit
    public var isLooped: Bool = false
    public private(set) var viewControllers: [UIViewController] = []
    public private(set) var currentPage: Int?
    public private(set) var currentPageProgress: CGFloat = 0

    public weak var delegate: PageViewControllerDelegate?
    
    public init(interPageSpacing: CGFloat) {
        self.interPageSpacing = interPageSpacing
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [
                UIPageViewController.OptionsKey.interPageSpacing: interPageSpacing
            ]
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        interPageSpacing = 0
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: [
                UIPageViewController.OptionsKey.interPageSpacing: interPageSpacing
            ]
        )
        super.init(coder: coder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pageViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        didMove(toParent: self)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        scrollView?.delegate = self
    }
    
    // MARK:
    
    /// The page index with includes the transition progress
    public var currentProgressivePage: CGFloat? {
        if let page = currentPage {
            return CGFloat(page) + currentPageProgress
        }
        return nil
    }
    
    public var scrollView: UIScrollView? {
        pageViewController.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView
    }
    
    /// View controller that is being focused currently
    public var currentViewController: UIViewController? {
        guard let page = currentPage else { return nil }
        return viewControllers[safe: page]
    }
    
    // MARK:
    
    /// Scroll to particular page
    public func scrollTo(pageIndex index: Int, animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        guard let vc = viewControllers[safe: index] else { return }
        
        let direction: UIPageViewController.NavigationDirection
        if let _currentIndex = currentPage {
            direction = (_currentIndex < index ? .forward : .reverse)
        } else {
            direction = .forward
        }
        
        let prevVCs = pageViewController.viewControllers ?? []
        pageViewController.setViewControllers([vc], direction: direction, animated: animated, completion: { isFinished in
            self.pageViewController(self.pageViewController, didFinishAnimating: isFinished, previousViewControllers: prevVCs, transitionCompleted: true)
            completion?(isFinished)
        })
    }
    
    /// Set the pages and the initial page to be shown
    public func setPages(_ vcs: [UIViewController], initialPageIndex: Int, animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.viewControllers = vcs
            DispatchQueue.main.async {
                self.scrollTo(pageIndex: initialPageIndex, animated: animated, completion: completion)
            }
        }
    }
}

// MARK: - UIPageViewControllerDataSource

extension PageViewController: UIPageViewControllerDataSource {
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let idx = viewControllers.firstIndex(of: viewController) else { return nil }
        
        var targetIdx = idx - 1
        if isLooped {
            targetIdx = (targetIdx + viewControllers.count) % viewControllers.count
        }
        
        if targetIdx == idx {
            return nil
        } else {
            return viewControllers[safe: targetIdx]
        }
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let idx = viewControllers.firstIndex(of: viewController) else { return nil }

        var targetIdx = idx + 1
        if isLooped {
            targetIdx = targetIdx % viewControllers.count
        }
        
        if targetIdx == idx {
            return nil
        } else {
            return viewControllers[safe: targetIdx]
        }
    }
}

// MARK: - UIPageViewControllerDelegate

extension PageViewController: UIPageViewControllerDelegate {
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let targetVC = pendingViewControllers.first, let idx = viewControllers.firstIndex(of: targetVC) else { return }
        delegate?.pageViewController(self, willTransitToPage: idx, pendingViewController: targetVC)
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let prevVC = previousViewControllers.first
        let fromIndex: Int? = prevVC.flatMap({ vc -> Int? in viewControllers.firstIndex(of: vc) })
        
        guard let toVC = pageViewController.viewControllers?.first, let toIndex = viewControllers.firstIndex(of: toVC) else { return }
        
        if completed {
            currentPage = toIndex
        }
        delegate?.pageViewController(self, didFinishAnimating: finished, fromPage: fromIndex, toPage: toIndex, previousViewController: prevVC, transitionCompleted: completed)
    }
}

// MARK: - UIScrollViewDelegate

extension PageViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let point = scrollView.contentOffset
        currentPageProgress = (point.x - scrollView.frame.width) / (view.frame.width + interPageSpacing)
        
        if let progressivePage = currentProgressivePage {
            delegate?.pageViewController(self, didUpdateProgressivePage: progressivePage)
        }
    }
}
