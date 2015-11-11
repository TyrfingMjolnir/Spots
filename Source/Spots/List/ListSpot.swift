import UIKit

typealias TitleSpot = ListSpot

public class ListSpot: NSObject, Spotable {

  public static var cells = [String : UITableViewCell.Type]()
  private var cachedCells = [String : Itemble]()
  public static var headers = [String : UIView.Type]()

  public let itemHeight: CGFloat = 44
  public let headerHeight: CGFloat = 44

  public var component: Component
  public weak var sizeDelegate: SpotSizeDelegate?
  public weak var spotDelegate: SpotsDelegate?

  public lazy var tableView: UITableView = { [unowned self] in
    let tableView = UITableView()
    tableView.delegate = self
    tableView.dataSource = self
    tableView.frame.size.width = UIScreen.mainScreen().bounds.width
    tableView.scrollEnabled = false
    tableView.autoresizingMask = [.FlexibleWidth, .FlexibleRightMargin, .FlexibleLeftMargin]
    tableView.autoresizesSubviews = true
    tableView.rowHeight = UITableViewAutomaticDimension

    return tableView
  }()

  public required init(component: Component) {
    self.component = component
    super.init()

    let items = component.items
    for (index, item) in items.enumerate() {
      let componentCellClass = ListSpot.cells[item.kind] ?? ListSpotCell.self
      if let cachedCell = cachedCells[item.kind] {
        cachedCell.configure(&self.component.items[index])
      } else if let listCell = componentCellClass.init() as? Itemble {
        self.tableView.registerClass(componentCellClass,
          forCellReuseIdentifier: "ListCell\(item.kind)")
        listCell.configure(&self.component.items[index])
        cachedCells[item.kind] = listCell
      }
    }
    cachedCells.removeAll()
  }

  public convenience init(title: String, kind: String = "list") {
    let component = Component(title: title, kind: kind)
    self.init(component: component)
  }

  public func setup() {
    if component.size == nil {
      var newHeight = component.items.reduce(0, combine: { $0 + $1.size.height })
      if !component.title.isEmpty { newHeight += headerHeight }

      tableView.frame.size.width = UIScreen.mainScreen().bounds.width
      tableView.frame.size.height = newHeight
      component.size = CGSize(width: tableView.frame.width, height: tableView.frame.height)
    }
  }

  public func render() -> UIView {
    return tableView
  }

  public func layout(size: CGSize) {
    tableView.frame.size.width = size.width
    tableView.layoutIfNeeded()
  }
}

extension ListSpot: UITableViewDelegate {

  public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
    spotDelegate?.spotDidSelectItem(self, item: component.items[indexPath.row])
  }

  public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    var newHeight = component.items.reduce(0, combine: { $0 + $1.size.height })
    if !component.title.isEmpty { newHeight += headerHeight }
    tableView.frame.size.height = newHeight
    component.size = CGSize(width: tableView.frame.width, height: tableView.frame.height)
    sizeDelegate?.sizeDidUpdate()

    return component.items[indexPath.item].size.height
  }
}

extension ListSpot: UITableViewDataSource {

  public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return !component.title.isEmpty ? headerHeight : 0
  }

  public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return component.title
  }

  public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return component.items.count
  }

  public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if let header = ListSpot.headers[component.kind] {
      let header = header.init(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: headerHeight))
      if let configurable = header as? Componentable {
        configurable.configure(component)
      }
      return header
    }

    return nil
  }

  public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell: UITableViewCell

    if let tableViewCell = cachedCells[component.items[indexPath.item].kind] as? UITableViewCell {
      cell = tableViewCell
    } else {
      cell = tableView.dequeueReusableCellWithIdentifier("ListCell\(component.items[indexPath.item].kind)", forIndexPath: indexPath)
    }

    cell.optimize()

    if let itemable = cell as? Itemble {
      itemable.configure(&component.items[indexPath.item])
    }

    return cell
  }
}
