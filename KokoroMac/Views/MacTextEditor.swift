import SwiftUI
import Combine
import AppKit

class PauseAttachment: NSTextAttachment {
    var duration: Double
    init(duration: Double, accentColor: NSColor) {
        self.duration = duration
        super.init(data: nil, ofType: nil)
        
        let size = NSSize(width: 72, height: 20)
        let image = NSImage(size: size)
        image.lockFocus()
        
        accentColor.withAlphaComponent(0.15).setFill()
        let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 4, yRadius: 4)
        path.fill()
        
        accentColor.withAlphaComponent(0.4).setStroke()
        path.lineWidth = 0.5
        path.stroke()
        
        let text = "⏸ \(duration)s"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: accentColor,
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .paragraphStyle: paragraphStyle
        ]
        let rect = NSRect(x: 0, y: (size.height - 12)/2, width: size.width, height: 12)
        text.draw(in: rect, withAttributes: attrs)
        
        image.unlockFocus()
        self.image = image
        
        let font = NSFont.systemFont(ofSize: 15)
        self.bounds = CGRect(x: 0, y: font.descender + 2, width: size.width, height: size.height)
    }
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

class PlainTextPasteTextView: NSTextView {
    override func paste(_ sender: Any?) {
        if let plainText = NSPasteboard.general.string(forType: .string) {
            insertText(plainText, replacementRange: selectedRange())
        }
    }
    override var acceptsFirstResponder: Bool { true }
}

func buildAttributedString(from text: String, theme: AppTheme, accentColor: NSColor) -> NSAttributedString {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 15),
        .foregroundColor: NSColor.textColor
    ]
    let result = NSMutableAttributedString(string: text, attributes: attrs)
    
    let nsString = result.string as NSString
    var searchRange = NSMakeRange(0, nsString.length)
    while searchRange.location < nsString.length {
        let foundRange = nsString.range(of: "\u{FFFC}", options: [], range: searchRange)
        if foundRange.location == NSNotFound { break }
        
        let attachment = PauseAttachment(duration: 1.0, accentColor: accentColor)
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
    var appSettings: AppSettings
    
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
        
        textView.textColor = .textColor
        textView.insertionPointColor = .textColor
        textView.typingAttributes = [
            .font: NSFont.systemFont(ofSize: 15),
            .foregroundColor: NSColor.textColor
        ]
        
        textView.delegate = context.coordinator
        scrollView.documentView = textView
        
        let accentNSColor = NSColor(theme.accentColor)
        textView.textStorage?.setAttributedString(buildAttributedString(from: text, theme: theme, accentColor: accentNSColor))
        
        // FIX: Defer state update to avoid "Publishing changes from within view updates" warning
        DispatchQueue.main.async {
            context.coordinator.updateTTSReadyText(textView: textView)
        }
        
        context.coordinator.cancellable = insertSignal.sink { signal in
            let currentRange = textView.selectedRange()
            let nsText = textView.string as NSString
            let accentNSColor = NSColor(theme.accentColor)
            
            if signal.hasPrefix("PAUSE_CHIP_") {
                let durationStr = signal.replacingOccurrences(of: "PAUSE_CHIP_", with: "")
                let duration = Double(durationStr) ?? 1.0
                let attachment = PauseAttachment(duration: duration, accentColor: accentNSColor)
                let attributedString = NSAttributedString(attachment: attachment)
                textView.textStorage?.insert(attributedString, at: currentRange.location)
                textView.didChangeText()
            } else if signal == "PHONEME_OVERRIDE" {
                let textLength = nsText.length
                var searchStart = currentRange.location
                var i = searchStart - 1
                
                while i >= 0 {
                    let char = nsText.character(at: i)
                    if char == 0xFFFC { i -= 1 }
                    else if let scalar = UnicodeScalar(char),
                            CharacterSet.whitespacesAndNewlines.contains(scalar) || CharacterSet.punctuationCharacters.contains(scalar) { i -= 1 }
                    else { break }
                }
                
                let wordEnd = i + 1
                var wordStart = wordEnd
                while i >= 0 {
                    let char = nsText.character(at: i)
                    if char == 0xFFFC { break }
                    if let scalar = UnicodeScalar(char) {
                        if CharacterSet.whitespacesAndNewlines.contains(scalar) || CharacterSet.punctuationCharacters.contains(scalar) { break }
                    }
                    wordStart = i
                    i -= 1
                }
                
                let wordLength = wordEnd - wordStart
                var replacementString = " "
                if wordLength > 0 {
                    replacementString = "[\(nsText.substring(with: NSMakeRange(wordStart, wordLength)))](/ipa/)"
                    textView.setSelectedRange(NSMakeRange(wordStart, wordLength))
                } else {
                    replacementString = "[word](/ipa/)"
                    textView.setSelectedRange(NSMakeRange(searchStart, 0))
                }
                
                let baseInsertLoc = textView.selectedRange().location
                if baseInsertLoc > 0 {
                    let prevChar = nsText.character(at: baseInsertLoc - 1)
                    if let scalar = UnicodeScalar(prevChar), !CharacterSet.whitespacesAndNewlines.contains(scalar) {
                        replacementString = " " + replacementString
                    }
                }
                
                let nextCharIndex = textView.selectedRange().location + textView.selectedRange().length
                if nextCharIndex < textLength {
                    let nextChar = nsText.character(at: nextCharIndex)
                    if let scalar = UnicodeScalar(nextChar),
                       !CharacterSet.whitespacesAndNewlines.contains(scalar) && !CharacterSet.punctuationCharacters.contains(scalar) && nextChar != 0xFFFC {
                        replacementString = replacementString + " "
                    }
                }
                
                let attrString = NSAttributedString(string: replacementString, attributes: textView.typingAttributes)
                textView.insertText(attrString, replacementRange: textView.selectedRange())
                
                let endLoc = textView.selectedRange().location
                let insertedLength = (replacementString as NSString).length
                let ipaRangeInReplacement = (replacementString as NSString).range(of: "ipa")
                if ipaRangeInReplacement.location != NSNotFound {
                    let ipaStart = endLoc - insertedLength + ipaRangeInReplacement.location
                    textView.setSelectedRange(NSMakeRange(ipaStart, ipaRangeInReplacement.length))
                }
            } else {
                textView.insertText(signal, replacementRange: currentRange)
            }
        }
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
         
        if textView.string != text || context.coordinator.lastTheme != theme {
            context.coordinator.lastTheme = theme
            let currentSelection = textView.selectedRange()
            let accentNSColor = NSColor(theme.accentColor)
            textView.textStorage?.setAttributedString(buildAttributedString(from: text, theme: theme, accentColor: accentNSColor))
            let safeLoc = min(currentSelection.location, textView.textStorage!.length)
            textView.setSelectedRange(NSMakeRange(safeLoc, 0))
            
            // FIX: Defer state update to avoid "Publishing changes from within view updates" warning
            DispatchQueue.main.async {
                context.coordinator.updateTTSReadyText(textView: textView)
            }
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacTextEditor
        var cancellable: AnyCancellable?
        var lastTheme: AppTheme?
        
        init(_ parent: MacTextEditor) { self.parent = parent }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            updateTTSReadyText(textView: textView)
        }
        
        func updateTTSReadyText(textView: NSTextView) {
            var ttsText = ""
            textView.textStorage?.enumerateAttributes(in: NSRange(location: 0, length: textView.textStorage!.length), options: []) { attrs, range, stop in
                if let attachment = attrs[.attachment] as? PauseAttachment {
                    ttsText += "<PAUSE:\(attachment.duration)>"
                } else {
                    ttsText += (textView.string as NSString).substring(with: range)
                }
            }
            parent.appSettings.ttsReadyText = ttsText
        }
    }
}
