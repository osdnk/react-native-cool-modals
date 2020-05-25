
import PanModal

class PossiblyTouchesPassableUIView: UIView {
  var oldClass: AnyClass?

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    if (self.subviews[1].frame.contains(point)) {
      return super.hitTest(point, with: event)
    }
    return nil
  }

  func makeOldClass() {
    if self.oldClass != nil {
      let oldClassMem: AnyClass = self.oldClass!
      self.oldClass = nil
      object_setClass(self, oldClassMem)
    }
  }

  override func didMoveToWindow() {
    if self.window == nil {
      makeOldClass()
    }
    super.didMoveToWindow()
  }
}

class PanModalViewController: UIViewController, PanModalPresentable, UILayoutSupport {
  weak var config: NSObject?
  var length: CGFloat = 0
  var topAnchor: NSLayoutYAxisAnchor = NSLayoutYAxisAnchor.init()
  var bottomAnchor: NSLayoutYAxisAnchor = NSLayoutYAxisAnchor.init()
  var heightAnchor: NSLayoutDimension = NSLayoutDimension.init()
  var disappared = false
  var hiding = false

  weak var viewController: UIViewController?
  var panScrollableCache: UIScrollView?
  var showDragIndicatorVal: Bool = false
  var topOffsetVal: CGFloat = 0.0
  var cornerRadiusValue: CGFloat = 8.0

  convenience init(_ viewControllerToPresent: UIViewController) {
    self.init(nibName: nil, bundle: nil)

    viewControllerToPresent.setValue(self, forKey: "_parentVC")
    viewController = viewControllerToPresent
  }

  @objc func hide() {
    hiding = true
    // callWillDismiss()
    hackParent()
    panModalTransition(to: .hidden)
  }

  @objc func unhackParent() {
    let ppview = view.superview!.superview!
    if ppview is PossiblyTouchesPassableUIView {
      (ppview as! PossiblyTouchesPassableUIView).makeOldClass()
    }
  }

  override var bottomLayoutGuide: UILayoutSupport {
    get {
      if self.isViewLoaded {
        return super.bottomLayoutGuide
      }
      return self
    }
  }

  func hackParent() {
    let ppview = view.superview!.superview!
    let poldClass: AnyClass = type(of: ppview)
    object_setClass(ppview, PossiblyTouchesPassableUIView.self);
    (ppview as! PossiblyTouchesPassableUIView).oldClass = poldClass
  }

  var cornerRadius: CGFloat {
    get {
      return cornerRadiusValue
    }
  }

  var isHapticFeedbackEnabled: Bool = false

  func findChildScrollViewDFS(view: UIView)-> UIScrollView? {
    if panScrollableCache != nil {
      return panScrollableCache
    }
    var viewsToTraverse = [view]
    while !viewsToTraverse.isEmpty {
      let last = viewsToTraverse.last!
      viewsToTraverse.removeLast()
      if last is UIScrollView {
        panScrollableCache = last as? UIScrollView
        return last as? UIScrollView
      }
      last.subviews.forEach { subview in
        viewsToTraverse.append(subview)
      }
    }
    return nil
  }

  override var view: UIView! {
    get {
      return viewController!.view
    }
    set {

    }
  }

  func panModalWillDismiss() {
    callWillDismiss()
  }

  func callWillDismiss() {
    let selector = NSSelectorFromString("willDismiss")
    config?.perform(selector)
  }

  func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
    return !hiding
  }

  var allowsDragToDismiss: Bool {
    return self.config?.value(forKey: "allowsDragToDismiss") as! Bool
  }

  var allowsTapToDismiss: Bool {
    return self.config?.value(forKey: "allowsTapToDismiss") as! Bool
  }

  var anchorModalToLongForm: Bool {
    return self.config?.value(forKey: "anchorModalToLongForm") as! Bool
  }

  var panModalBackgroundColor: UIColor {
    let backgroundColor: UIColor = self.config?.value(forKey: "backgroundColor") as! UIColor
    return backgroundColor.withAlphaComponent(CGFloat(truncating: self.config?.value(forKey: "backgroundOpacity") as! NSNumber))
  }

  func shouldPrioritize(panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
    let headerHeight: CGFloat = CGFloat(truncating: self.config?.value(forKey: "headerHeight") as! NSNumber)
    let location = panModalGestureRecognizer.location(in: view)
    return location.y < headerHeight
  }

  var isShortFormEnabledInternal = 2
  var isShortFormEnabled: Bool {
    let startFromShortForm = self.config?.value(forKey: "startFromShortForm") as! Bool
    if isShortFormEnabledInternal > 0 && !startFromShortForm {
      isShortFormEnabledInternal -= 1
      return false
    }
    return self.config?.value(forKey: "isShortFormEnabled") as! Bool
  }

  var shortFormHeight: PanModalHeight {
    let height: CGFloat = CGFloat(truncating: self.config?.value(forKey: "shortFormHeight") as! NSNumber)
    return isShortFormEnabled ? .contentHeight(height) : longFormHeight
  }

  var springDamping: CGFloat {
    return CGFloat(truncating: self.config?.value(forKey: "springDamping") as! NSNumber)
  }

  var transitionDuration: Double {
    return Double(truncating: self.config?.value(forKey: "transitionDuration") as! NSNumber)
  }

  var showDragIndicator: Bool {
    return showDragIndicatorVal
  }

  var topOffset: CGFloat {
    return topOffsetVal
  }

  var panScrollable: UIScrollView? {
    return findChildScrollViewDFS(view: self.view!)
  }

  var longFormHeight: PanModalHeight {
    return .contentHeight(UIScreen.main.bounds.height)
  }

  override func viewDidAppear(_ animated: Bool) {
    let selector = NSSelectorFromString("notifyAppear")
    viewController?.view.perform(selector)
  }

  override func viewWillDisappear(_ animated: Bool) {
    disappared = true
    super.viewWillDisappear(animated)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    for i in 1...10 {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 * Double(i)) {
        if !self.disappared {
          self.panModalSetNeedsLayoutUpdate()
        }
      }
    }
  }
}


extension UIViewController {
  @objc public func obtainDelegate() -> UIViewControllerTransitioningDelegate? {
    let delegate = PanModalPresentationDelegate.default
    return delegate
  }

  @objc public func presentModally(_ viewControllerToPresent: UIViewController,
                                   animated flag: Bool,
                                   completion: (() -> Void)? = nil,
                                   topOffset: CGFloat,
                                   showDragIndicator: Bool,
                                   slackStack:Bool,
                                   cornerRadius:NSNumber? = nil,
                                   config: NSObject) -> Void

  {
    let controller = PanModalViewController(viewControllerToPresent)
    controller.transitioningDelegate = slackStack ? viewControllerToPresent.transitioningDelegate : nil
    controller.modalPresentationStyle = slackStack ? viewControllerToPresent.modalPresentationStyle : .pageSheet
    controller.topOffsetVal = topOffset
    controller.config = config
    controller.showDragIndicatorVal = showDragIndicator
    if (cornerRadius != nil) {
      controller.cornerRadiusValue = CGFloat(truncating: cornerRadius!)
    }
    self.present(controller, animated: flag, completion: completion)
  }
}
