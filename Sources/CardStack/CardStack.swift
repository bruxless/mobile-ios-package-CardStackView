import SwiftUI

public struct CardStack<Direction: CardSwipeDirection, Element: Identifiable, Content: View>: View {
    
    @Environment(\.cardStackConfiguration) private var configuration: CardStackConfiguration
    
    @ObservedObject var model: CardStackModel<Element, Direction>
    
    @State private var ongoingDirection: Direction? {
        didSet {
            if oldValue != ongoingDirection {
                onChange?(ongoingDirection)
            }
        }
    }
    
    private let onChange: ((Direction?) -> Void)?
    private let onSwipe: (Element, Direction) -> Void
    private let content: (Element, Direction?) -> Content
    
    public init(
        model: CardStackModel<Element, Direction>,
        onChange: ((Direction?) -> Void)? = nil,
        onSwipe: @escaping (Element, Direction) -> Void,
        @ViewBuilder content: @escaping (Element, Direction?) -> Content
    ) {
        self.model = model
        self.onChange = onChange
        self.onSwipe = onSwipe
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            
            GeometryReader { geometry in
                ForEach(model.data.reversed()) { dataPiece -> AnyView in
                    
                    let indexInStack = model.indexInStack(dataPiece) ?? 0
                    
                    if
                        let index = model.data.firstIndex(where: { $0.id == dataPiece.id }),
                        indexInStack < configuration.maxVisibleCards
                    {
                        return AnyView(
                            CardView(
                                isOnTop: index == model.currentIndex,
                                offset: offset(for: dataPiece.direction, in: geometry),
                                onChange: { direction in
                                    ongoingDirection = direction
                                },
                                onSwipe: { direction, translation in
                                    model.swipe(direction: direction, completion: { direction in
                                        onSwipe(dataPiece.element, direction)
                                    })
                                },
                                content: { ongoingDirection in
                                    content(dataPiece.element, dataPiece.direction ?? ongoingDirection)
                                        .offset(
                                            x: 0,
                                            y: CGFloat(indexInStack) * configuration.cardOffset
                                        )
                                        .scaleEffect(
                                            scaleEffect(indexInStack),
                                            anchor: .bottom
                                        )
                                        .zIndex(Double(index))
                                }
                            )
                        )
                    } else {
                        return AnyView(EmptyView())
                    }
                }
            }
            
        }
    }
    
    private func scaleEffect(_ cardIndex: Int) -> CGFloat {
        if cardIndex < 0 { return 1 }
        return 1 - configuration.cardScale * CGFloat(cardIndex)
    }
    
    private func offset(for direction: Direction?, in geometry: GeometryProxy) -> CGSize {
        guard let direction = direction else { return .zero }
        
        guard let fourDirection = direction as? FourDirections else { return .zero }
        let angle = fourDirection.angle
        
        let width = geometry.size.width
        let height = geometry.size.height
        
        return CGSize(
            width: cos(angle.radians) * width * 2.0,
            height: sin(angle.radians) * -height * 2.0
        )
    }
    
}
