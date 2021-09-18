//
//  CopyButton.swift
//  CopyButton
//
//  Created by David Stephens on 18/09/2021.
//

import SwiftUI
import UniformTypeIdentifiers

struct CopyButton: View {
    // MARK: Parameters
    let text: String
    let generateText: () -> String
    @Binding var showCopied: Bool
    
    // MARK: State
    #if os(iOS)
    @State private var notificationFeedbackGenerator: UINotificationFeedbackGenerator? = nil
    #endif
    
    var button: some View {
        Button(action: {
            #if os(iOS)
            notificationFeedbackGenerator = UINotificationFeedbackGenerator()
            notificationFeedbackGenerator?.prepare()
            #endif
            EWPasteboard.set(generateText(), forType: UTType.utf8PlainText)
            withAnimation {
                showCopied = true
                #if os(iOS)
                notificationFeedbackGenerator?.notificationOccurred(.success)
                #endif
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    showCopied = false
                }
                #if os(iOS)
                notificationFeedbackGenerator = nil
                #endif
            }
        }) {
            Text(showCopied ? "Copied ✓" : text)
                .font(.headline)
                .foregroundColor(.white)
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.accentColor)
        )
    }
    
    var body: some View {
        #if os(macOS)
        button
            .buttonStyle(PlainButtonStyle())
        #else
        button
        #endif
    }
}

struct CopyButton_Previews: PreviewProvider {
    static var previews: some View {
        CopyButton(text: "Copy", generateText: { "Example text" }, showCopied: .constant(false))
    }
}
