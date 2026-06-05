import SwiftUI
import Combine
import AppKit

class PlainTextPasteTextView: NSTextView {
    override func paste(_ sender: Any?) {
        if let plainText = NSPasteboard.general.string(forType: .string) {
            insertText(plainText, replacementRange: selectedRange())
        }
    }
    
    // FIX: Ensure the text view accepts keyboard focus for arrow keys
    override var acceptsFirstResponder: Bool { true }
}

func createPauseChip() -> NSTextAttachment {
    let attachment = NSTextAttachment()
    let size = NSSize(width: 64, height: 24)
    let image = NSImage(size: size)
    image.lockFocus()
    
    NSColor.controlAccentColor.withAlphaComponent(0.15).setFill()
    let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 12, yRadius: 12)
    path.fill()
    
    NSColor.controlAccentColor.setStroke()
    path.lineWidth = 1.0
    path.stroke()
    
    let text = "⏸ Pause"
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.controlAccentColor,
        .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
        .paragraphStyle: paragraphStyle
    ]
    let rect = NSRect(x: 0, y: (size.height - 14)/2, width: size.width, height: 14)
    text.draw(in: rect, withAttributes: attrs)
    
    image.unlockFocus()
    attachment.image = image
    
    let font = NSFont.systemFont(ofSize: 15)
    attachment.bounds = CGRect(x: 0, y: font.descender, width: size.width, height: size.height)
    return attachment
}

func buildAttributedString(from text: String, theme: AppTheme) -> NSAttributedString {
    let baseColor = theme.isTrueDark ? NSColor.white : NSColor.textColor
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 15),
        .foregroundColor: baseColor
    ]
    let result = NSMutableAttributedString(string: text, attributes: attrs)
    
    let nsString = result.string as NSString
    var searchRange = NSMakeRange(0, nsString.length)
    while searchRange.location < nsString.length {
        let foundRange = nsString.range(of: "\u{FFFC}", options: [], range: searchRange)
        if foundRange.location == NSNotFound { break }
        
        let attachment = createPauseChip()
        let attrAttachment = NSAttributedString(attachment: attachment)
        result.replaceCharacters(in: foundRange, with: attrAttachment)
        
        searchRange = NSMakeRange(foundRange.location + 1, result.length - (foundRange.location + 1))
    }
    return result
}

struct MacTextEditor: NSViewRepresentable {
    @Binding var text: String
    var insertSignal: PassthroughSubject<String, Never>
    var theme: AppTheme
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        layoutManager.addTextContainer(textContainer)
        
        let textView = PlainTextPasteTextView(frame: .zero, textContainer: textContainer)
        
        // FIX: Explicit sizing constraints to force ScrollView activation
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: 0, height: 10_000_000)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: 10_000_000)
        textView.minSize = NSSize(width: 0, height: 0)
        
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isRichText = true
        
        let baseColor = theme.isTrueDark ? NSColor.white : NSColor.textColor
        textView.textColor = baseColor
        textView.insertionPointColor = baseColor
        textView.typingAttributes = [
            .font: NSFont.systemFont(ofSize: 15),
            .foregroundColor: baseColor
        ]
        
        textView.delegate = context.coordinator
        scrollView.documentView = textView
        
        textView.textStorage?.setAttributedString(buildAttributedString(from: text, theme: theme))
        
        context.coordinator.cancellable = insertSignal.sink { signal in
            let currentRange = textView.selectedRange()
            let nsText = textView.string as NSString
            
            if signal == "PAUSE_CHIP" {
                let attachment = createPauseChip()
                let attributedString = NSAttributedString(attachment: attachment)
                textView.textStorage?.insert(attributedString, at: currentRange.location)
                textView.didChangeText()
                context.coordinator.parent.text = textView.string
                
            } else if signal == "PHONEME_OVERRIDE" {
                let textLength = nsText.length
                var searchStart = currentRange.location
                var i = searchStart - 1
                
                while i >= 0 {
                    let char = nsText.character(at: i)
                    if char == 0xFFFC {
                        i -= 1
                    } else if let scalar = UnicodeScalar(char),
                              CharacterSet.whitespacesAndNewlines.contains(scalar) ||
                              CharacterSet.punctuationCharacters.contains(scalar) {
                        i -= 1
                    } else {
                        break
                    }
                }
                
                let wordEnd = i + 1
                var wordStart = wordEnd
                
                while i >= 0 {
                    let char = nsText.character(at: i)
                    if char == 0xFFFC { break }
                    if let scalar = UnicodeScalar(char) {
                        if CharacterSet.whitespacesAndNewlines.contains(scalar) || CharacterSet.punctuationCharacters.contains(scalar) {
                            break
                        }
                    }
                    wordStart = i
                    i -= 1
                }
                
                let wordLength = wordEnd - wordStart
                var replacementString = ""
                
                if wordLength > 0 {
                    let word = nsText.substring(with: NSMakeRange(wordStart, wordLength))
                    replacementString = "[\(word)](/ipa/)"
                    textView.setSelectedRange(NSMakeRange(wordStart, wordLength))
                } else {
                    replacementString = "[word](/ipa/)"
                    textView.setSelectedRange(NSMakeRange(searchStart, 0))
                }
                
                let baseInsertLoc = textView.selectedRange().location
                var needsLeadingSpace = false
                if baseInsertLoc > 0 {
                    let prevChar = nsText.character(at: baseInsertLoc - 1)
                    if let scalar = UnicodeScalar(prevChar), !CharacterSet.whitespacesAndNewlines.contains(scalar) {
                        needsLeadingSpace = true
                    }
                }
                
                let nextCharIndex = textView.selectedRange().location + textView.selectedRange().length
                var needsTrailingSpace = true
                if nextCharIndex < textLength {
                    let nextChar = nsText.character(at: nextCharIndex)
                    if let scalar = UnicodeScalar(nextChar),
                       CharacterSet.whitespacesAndNewlines.contains(scalar) ||
                       CharacterSet.punctuationCharacters.contains(scalar) ||
                       nextChar == 0xFFFC {
                        needsTrailingSpace = false
                    }
                }
                
                if needsLeadingSpace { replacementString = " " + replacementString }
                if needsTrailingSpace { replacementString = replacementString + " " }
                
                let baseColor = theme.isTrueDark ? NSColor.white : NSColor.textColor
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 15),
                    .foregroundColor: baseColor
                ]
                let attrString = NSAttributedString(string: replacementString, attributes: attrs)
                
                textView.insertText(attrString, replacementRange: textView.selectedRange())
                
                let endLoc = textView.selectedRange().location
                let insertedLength = (replacementString as NSString).length
                let ipaRangeInReplacement = (replacementString as NSString).range(of: "ipa")
                if ipaRangeInReplacement.location != NSNotFound {
                    let ipaStart = endLoc - insertedLength + ipaRangeInReplacement.location
                    textView.setSelectedRange(NSMakeRange(ipaStart, ipaRangeInReplacement.length))
                }
                
                context.coordinator.parent.text = textView.string
            } else {
                textView.insertText(signal, replacementRange: currentRange)
                context.coordinator.parent.text = textView.string
            }
        }
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            let currentSelection = textView.selectedRange()
            textView.textStorage?.setAttributedString(buildAttributedString(from: text, theme: theme))
            
            let newLength = textView.textStorage!.length
            let safeLoc = min(currentSelection.location, newLength)
            textView.setSelectedRange(NSMakeRange(safeLoc, 0))
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacTextEditor
        var cancellable: AnyCancellable?
        init(_ parent: MacTextEditor) { self.parent = parent }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
