public class SpotFactory {

  static var DefaultSpot: Spotable.Type = GridSpot.self

  private static var spots: [String: Spotable.Type] = [
    "carousel": CarouselSpot.self,
    "list" : ListSpot.self,
    "grid": GridSpot.self,
    "feed": FeedSpot.self
  ]

  static func register<T: Spotable>(kind: String, spot: T.Type) {
    spots[kind] = spot
  }

  static func resolve(component: Component) -> Spotable {
    let Spot: Spotable.Type = spots[component.kind] ?? DefaultSpot
    return Spot.init(component: component)
  }
}
