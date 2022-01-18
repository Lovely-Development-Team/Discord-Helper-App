//
//  DefaultTabPicker.swift
//  Elsewhen
//
//  Created by Ben Cardy on 18/01/2022.
//

import SwiftUI





struct DefaultTabPicker: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Binding var defaultTabIndex: Int
    
    private func setDefaultTab(_ defaultTab: Int) {
        defaultTabIndex = defaultTab
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            /// Without this delay, the binding doesn't properly update and the state doesn't change
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    var content: some View {
        Form {
            Button(action: {
                setDefaultTab(0)
            }) {
                HStack {
                    Text("Time Codes")
                    Spacer()
                    if defaultTabIndex == 0 {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            Button(action: {
                setDefaultTab(1)
            }) {
                HStack {
                    Text("Time List")
                    Spacer()
                    if defaultTabIndex == 1 {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .foregroundColor(.primary)
        .navigationTitle("Default Tab")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    var body: some View {
        if DeviceType.isPadAndNotCompact {
            NavigationView {
                content
            }
            .navigationViewStyle(StackNavigationViewStyle())
        } else {
            content
        }
    }
    
}

struct DefaultTabPicker_Previews: PreviewProvider {
    static var previews: some View {
        DefaultTabPicker(defaultTabIndex: .constant(1))
    }
}
