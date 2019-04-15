//
// The MIT License (MIT)
//
// Copyright (c) 2015-present Badoo Trading Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

public final class HyperLabelGestureHandler {

    // MARK: - Type declarations

    private typealias Class = HyperLabelGestureHandler
    public typealias Handler = () -> Void
    public typealias TextView = UIView & TextContainerData

    // MARK: - Private properties

    private var linkRegistry = RangeMap<String.Index, Handler>()
    private let indexFinder = CharacterIndexFinder()

    // MARK: - Public API

    public var extendsLinkTouchArea: Bool = true

    public weak var textView: TextView?

    public func addLink(addLinkWithRange range: Range<String.Index>, withHandler handler: @escaping Handler) {
        self.linkRegistry.setValue(value: handler, forRange: range)
    }

    public func removeAllLinks() {
        self.linkRegistry.clear()
    }

    @objc
    public func handleTapGesture(sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }
        guard let view = self.textView else { return }
        let point = sender.location(in: view)
        self.indexFinder.update(textContainerData: view)
        let handlerProvider = self.extendsLinkTouchArea ? self.handler(nearPoint:) : self.handler(atPoint:)
        guard let handler = handlerProvider(point) else { return }
        handler()
    }

    public func rect(forRange range: Range<String.Index>) -> CGRect {
        guard let view = self.textView else { return .zero }
        self.indexFinder.update(textContainerData: view)
        return self.indexFinder.rect(forRange: range)
    }

    // MARK: - Private methods

    private func handler(nearPoint point: CGPoint) -> Handler? {
        if let handler = self.handler(atPoint: point) {
            return handler
        }

        let deltas = stride(from: 2.5, to: 15, by: 2.5).flatMap(Class.deltas)
        for delta in deltas {
            let pointWithOffset = CGPoint(x: point.x + delta.x, y: point.y + delta.y)
            guard let handler = self.handler(atPoint: pointWithOffset) else { continue }
            return handler
        }

        return nil
    }

    private func handler(atPoint point: CGPoint) -> Handler? {
        guard let index = self.indexFinder.indexOfCharacter(atPoint: point) else { return nil }
        let stringIndex = String.Index(encodedOffset: index)
        guard let handler = self.linkRegistry.value(at: stringIndex) else { return nil }
        return handler
    }

    private static func deltas(forRadius radius: CGFloat) -> [CGPoint] {
        let diagonal = radius / sqrt(2)
        return [
            CGPoint(x: -radius, y: 0),
            CGPoint(x: radius, y: 0),
            CGPoint(x: 0, y: -radius),
            CGPoint(x: 0, y: radius),
            CGPoint(x: -diagonal, y: -diagonal),
            CGPoint(x: diagonal, y: diagonal),
            CGPoint(x: diagonal, y: -diagonal),
            CGPoint(x: -diagonal, y: diagonal)
        ]
    }
}