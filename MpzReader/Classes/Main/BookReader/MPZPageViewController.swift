//
//  MPZPageViewController.swift
//  MpzReader
//
//  Created by Hasitha Mapalagama on 9/2/20.
//

import Foundation
import UIKit
import ReadiumShared
import ScreenShield
class MPZPageViewController : UIPageViewController {
    
    static func create(withHightlights highlights : [Highlight], highlightDelegate : HighlightListDelegate, publication : Publication, contentDelegate : MpzContentsDelegate) -> MPZPageViewController {
        let stry = UIStoryboard.init(name: "Main", bundle: Bundle.init(for: MPZPageViewController.self))
        let vc = stry.instantiateViewController(withIdentifier: "page_view") as! MPZPageViewController
        vc.highlights = highlights
        vc.highlightDelegate = highlightDelegate
        vc.contentDelegate = contentDelegate
        vc.publication = publication
        return vc
    }
    
    var highlights = [Highlight]()
    var highlightDelegate : HighlightListDelegate!
    var contentDelegate : MpzContentsDelegate!
    var publication : Publication!
    
    var segmentedControl: UISegmentedControl!
    var viewList = [UIViewController]()
    var viewControllerOne: UIViewController!
    var viewControllerTwo: UIViewController!
    var index: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyScreenshotProtection()
        segmentedControl = UISegmentedControl(items: ["Contents", "Highlights"])
        segmentedControl.addTarget(self, action: #selector(MPZPageViewController.didSwitchMenu(_:)), for: UIControl.Event.valueChanged)
        segmentedControl.selectedSegmentIndex = index
        segmentedControl.setWidth(100, forSegmentAt: 0)
        segmentedControl.setWidth(100, forSegmentAt: 1)
        self.navigationItem.titleView = segmentedControl
        
        viewControllerOne = MpzContentsVC.create(withPub: self.publication, delegate: contentDelegate)
        viewControllerTwo = HighlightListVC.create(withHightlights: highlights, delegate: highlightDelegate)
        viewList = [viewControllerOne, viewControllerTwo]
        viewControllerOne.didMove(toParent: self)
        viewControllerTwo.didMove(toParent: self)
        self.delegate = self
        self.dataSource = self
        setViewControllers([viewList[index]], direction: .forward, animated: true, completion: nil)
    }
    
    @objc func didSwitchMenu(_ sender: UISegmentedControl) {
        self.index = sender.selectedSegmentIndex
        let direction: UIPageViewController.NavigationDirection = (index == 0 ? .reverse : .forward)
        setViewControllers([viewList[index]], direction: direction, animated: true, completion: nil)
        
    }
}

extension MPZPageViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if finished && completed {
            let viewController = pageViewController.viewControllers?.last
            segmentedControl.selectedSegmentIndex = viewList.index(of: viewController!)!
        }
    }
}

// MARK: UIPageViewControllerDataSource

extension MPZPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let index = viewList.index(of: viewController)!
        if index == viewList.count - 1 {
            return nil
        }
        
        self.index = self.index + 1
        return viewList[self.index]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let index = viewList.index(of: viewController)!
        if index == 0 {
            return nil
        }
        
        self.index = self.index - 1
        return viewList[self.index]
    }
}
