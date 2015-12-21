import Spots
import Fakery
import Sugar

class SavedController: SpotController {

  static let faker = Faker()

  convenience init(title: String) {
    let component = Component()
    let feedSpot = ListSpot(component: component)
    self.init(spot: feedSpot)

    self.title = title

    dispatch(queue: .Interactive) { [weak self] in
      let items = ForYouController.generateItems(0, to: 2)
      self?.update(closure: { (spot) -> Spotable in
        spot.component.items = items
        return spot
      })
    }
  }
}
