//
//  TimeCodeGeneratorView.swift
//  Elsewhen
//
//  Created by Ben Cardy on 18/06/2022.
//

import SwiftUI

struct TimeCodeGeneratorView: View, OrientationObserving {
    
    // MARK: Environment
#if os(iOS)
    @Environment(\.dynamicTypeSize) var dynamicTypesSize
    @EnvironmentObject internal var orientationObserver: OrientationObserver
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
#endif
    
    @ObservedObject var dateHolder: DateHolder
    
    // MARK: State
    @State private var selectedTimeZone: TimeZone? = nil
    @State private var appendRelative: Bool = false
    @State private var showEasterEggSheet: Bool = false
    
    let gridBreakPoint: Int = 170
    
    var gridItems: [GridItem] {
        #if os(macOS)
        return Array.init(repeating: .init(.flexible(), alignment: .top), count: 2)
        #else
        if isPadAndNotCompact {
            return Array.init(repeating: .init(.flexible(), alignment: .top), count: 3)
        }
        if dynamicTypesSize >= .xxLarge {
            return [GridItem(.flexible(), alignment: .top)]
        }
        return [GridItem(.adaptive(minimum: CGFloat(gridBreakPoint)), alignment: .top)]
        #endif
    }
    
    var localDate: Date {
        convert(date: dateHolder.date, from: selectedTimeZone ?? TimeZone.current, to: TimeZone.current)
    }
    
    var formattedLocalDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: localDate)
    }
    
    @ViewBuilder
    var gridOfItems: some View {
        LazyVGrid(columns: gridItems, spacing: 0) {
            ForEach(dateFormats, id: \.self) { dateFormat in
                FormatChoiceButton(dateFormat: dateFormat, selectedDate: $dateHolder.date, appendRelative: $appendRelative, timeZone: $selectedTimeZone)
                    .padding(.bottom)
            }
            FormatChoiceButton(dateFormat: relativeDateFormat, selectedDate: $dateHolder.date, appendRelative: .constant(false), timeZone: $selectedTimeZone)
                .padding(.bottom)
        }
        .padding(.top)
        .fixedSize(horizontal: false, vertical: true)
        NotRepresentativeWarning()
            .padding([.horizontal, .bottom])
        #if os(iOS)
        EasterEggButton {
            showEasterEggSheet = true
        }
        .padding(.bottom)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                gridOfItems
                    .padding(.horizontal)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .clipped()
            #if os(macOS)
            .background(Color.secondarySystemBackground)
            #else
            .background(Color.systemBackground)
            #endif
            VStack {
                HStack {
                    #if os(macOS)
                    EasterEggButton {
                        showEasterEggSheet = true
                    }
                    Spacer()
                    #endif
                    Toggle("INCLUDE_RELATIVE_TIME", isOn: $appendRelative.animation())
                }
#if os(iOS)
                    .tint(.accentColor)
                #endif
                    .padding([.horizontal, .top])
                    .padding(.bottom, 10)
                Divider()
                    .padding(.horizontal)
                if let selectedTimeZone = selectedTimeZone, selectedTimeZone != TimeZone.current {
                    Text("\(formattedLocalDate) local time")
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 5)
                    Divider()
                        .padding(.horizontal)
                }
                DateTimeZoneSheet(selectedDate: $dateHolder.date, selectedTimeZone: $selectedTimeZone, selectedTimeZones: .constant([]), selectedTimeZoneGroup: .constant(nil), multipleTimeZones: false)
            }
            .background(
                ZStack {
                    Rectangle().fill(Color.systemBackground)
#if os(iOS)
                    RoundedCorner(cornerRadius: 15, corners: [.topLeft, .topRight])
                        .fill(Color.secondarySystemBackground)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 0)
#endif
                }
            )
#if os(macOS)
            .overlay(
                Rectangle().frame(width: nil, height: 1, alignment: .top).foregroundColor(Color.secondary.opacity(0.3)), alignment: .top
            )
#endif
        }
        .background(Color.secondarySystemBackground)
        .sheet(isPresented: $showEasterEggSheet) {
            EasterEggView()
        }
        
    }
}

struct TimeCodeGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        TimeCodeGeneratorView(dateHolder: DateHolder.shared)
    }
}
