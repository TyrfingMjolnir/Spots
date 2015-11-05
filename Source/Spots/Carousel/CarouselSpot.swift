import UIKit
import GoldenRetriever
import Sugar
import Tailor

public class CarouselSpot: NSObject, Spotable {

  public static var cells = [String: UICollectionViewCell.Type]()

  public var component: Component
  public weak var sizeDelegate: SpotSizeDelegate?

  public lazy var flowLayout: UICollectionViewFlowLayout = { [unowned self] in
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 0
    layout.minimumLineSpacing = 0
    layout.scrollDirection = .Horizontal
    layout.sectionInset = UIEdgeInsetsMake(25, 25, 25, 25)

    return layout
    }()

  public lazy var collectionView: UICollectionView = { [unowned self] in
    let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: self.flowLayout)
    collectionView.backgroundColor = UIColor.whiteColor()
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.frame.size.width = UIScreen.mainScreen().bounds.width
    collectionView.showsHorizontalScrollIndicator = false

    return collectionView
    }()

  public required init(component: Component) {
    self.component = component
    super.init()

    let items = component.items
    for (index, item) in items.enumerate() {
      let componentCellClass = GridSpot.cells[item.kind] ?? CarouselSpotCell.self
      self.collectionView.registerClass(componentCellClass, forCellWithReuseIdentifier: "CarouselCell\(item.kind.capitalizedString)")

      guard let gridCell = componentCellClass.init() as? Itemble else { return }
      self.component.items[index].size.width = collectionView.frame.width / CGFloat(component.span)
      self.component.items[index].size.height = gridCell.size.height
    }
  }

  public func render() -> UIView {
    collectionView.frame.size.height = component.items.first?.size.height ?? 0
    collectionView.backgroundColor = UIColor(hex:
      component.meta.property("background-color") ?? "FFFFFF")

    return collectionView
  }

  public func layout(size: CGSize) {
    collectionView.collectionViewLayout.invalidateLayout()
    collectionView.frame.size.width = size.width
  }
}

extension CarouselSpot: UIScrollViewDelegate {

  public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    let pageWidth: CGFloat = collectionView.frame.width - 40
    let currentOffset = scrollView.contentOffset.x
    let targetOffset = targetContentOffset.memory.x
    
    var newTargetOffset: CGFloat = targetOffset > currentOffset
      ? ceil(currentOffset / pageWidth) * pageWidth
      : floor(currentOffset / pageWidth) * pageWidth

    if newTargetOffset > scrollView.contentSize.width {
      newTargetOffset = scrollView.contentSize.width
    } else if newTargetOffset < 0 {
      newTargetOffset = 0
    }

    targetContentOffset.memory.x = currentOffset;
    scrollView.setContentOffset(CGPoint(x: newTargetOffset, y:0), animated: true)
  }
}

extension CarouselSpot: UICollectionViewDelegateFlowLayout {

  public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    component.items[indexPath.item].size.width = collectionView.frame.width
    let item = component.items[indexPath.item]
    return CGSize(width: item.size.width - 40, height: item.size.height)
  }
}

extension CarouselSpot: UICollectionViewDataSource {

  public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return component.items.count
  }

  public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    var item = component.items[indexPath.item]
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CarouselCell\(item.kind.capitalizedString)", forIndexPath: indexPath)

    if let grid = cell as? Itemble {
      grid.configure(&item)
      component.items[indexPath.item] = item
      collectionView.collectionViewLayout.invalidateLayout()
      sizeDelegate?.sizeDidUpdate()
    }

    return cell
  }
}
