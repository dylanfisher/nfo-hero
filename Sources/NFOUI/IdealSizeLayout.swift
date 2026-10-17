import SwiftUI

/// Passes its one subview through, except that its ideal size is the subview's height at the
/// subview's ideal width. A view's plain ideal size lays out wrapping text on one line, so a
/// card's plot would count as one line tall although it wraps at the card's width. The window
/// and the Quick Look preview open at this size.
struct IdealSizeLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let subview = subviews.first else { return .zero }
        guard proposal.width == nil, proposal.height == nil else {
            return subview.sizeThatFits(proposal)
        }
        let width = subview.sizeThatFits(.unspecified).width
        return subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
    }
}
