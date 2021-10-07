//
//  MykeMode.swift
//  MykeMode
//
//  Created by Ben Cardy on 11/09/2021.
//

import SwiftUI
import UniformTypeIdentifiers

struct MykeMode: View {
    
    @State private var selectedDate = Date()
    @State private var selectedTimeZone: TimeZone = TimeZone.current
    
    @State private var selectedFormatStyle: DateFormat = dateFormats[0]
    
    @State private var selectedTimeZones: [TimeZone] = []
    @State private var timeZonesUsingEUFlag: Set<TimeZone> = []
    
    @State private var showCopied: Bool = false
    
    #if os(iOS)
    let mediumImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    #endif
    
    @State private var showTimeZoneSheet: Bool = false
    @State private var showTimeZonePopover: Bool = false
    @State private var selectionViewMaxHeight: CGFloat?
    
    func selectedTimeInZone(_ zone: TimeZone) -> String {
        let df = DateFormatter()
        df.dateStyle = .none
        df.timeStyle = .short
        df.timeZone = zone
        return df.string(from: convert(date: selectedDate, from: selectedTimeZone, to: TimeZone.current))
    }
    
    func generateTimesAndFlagsText() -> String {
        var text = "\n"
        for tz in selectedTimeZones {
            let abbr = tz.fudgedAbbreviation(for: selectedDate) ?? ""
            text += "\(flagForTimeZone(tz)) - \(selectedTimeInZone(tz)) \(abbr)\n"
        }
        return text
    }
    
    func flagForTimeZone(_ tz: TimeZone) -> String {
        if timeZonesUsingEUFlag.contains(tz) {
            return "🇪🇺"
        }
        return tz.flag
    }
    
    #if os(iOS)
    static let navigationViewStyle = StackNavigationViewStyle()
    #else
    static let navigationViewStyle = DefaultNavigationViewStyle()
    #endif
    
    var body: some View {
        
        ZStack(alignment: .top) {
            
            VStack {
                
                DateTimeZonePicker(selectedDate: $selectedDate, selectedTimeZone: $selectedTimeZone, showDate: false, maxWidth: nil)
                    .labelsHidden()
                    .padding(.top, 5)
                    .padding(.horizontal, 8)
                
                HStack {
                    
                    Button(action: {
                        #if os(macOS)
//                        WindowManager.shared.openSelectTimeZones(selectedTimeZone: .constant(TimeZone.current), selectedDate: $selectedDate, selectedTimeZones: $selectedTimeZones)
                        self.showTimeZonePopover = true
                        #else
                        self.showTimeZoneSheet = true
                        #endif
                    }) {
                        Text("Choose time zones…")
                    }
                    .popover(isPresented: $showTimeZonePopover) {
                        TimezoneChoiceView(selectedTimeZone: .constant(TimeZone.current), selectedTimeZones: $selectedTimeZones, selectedDate: $selectedDate, selectMultiple: true)
                            .frame(minWidth: 300)
                    }
                    .padding(.vertical)
                    
                    Spacer()
                    
                    CopyButton(text: "Copy", generateText: generateTimesAndFlagsText, showCopied: $showCopied)
                    
                }
                .padding(.horizontal, 8)
                
            }
            .padding(.horizontal, 8)
            .frame(minWidth: 0, maxWidth: 390)
            .background(GeometryReader { geometry in
                Color.clear.preference(
                    key: ViewHeightPreferenceKey.self,
                    value: geometry.size.height
                )
            })
            .onPreferenceChange(ViewHeightPreferenceKey.self) {
                selectionViewMaxHeight = $0
            }
            
            List {
                ForEach(selectedTimeZones, id: \.self) { tz in
                    SelectedTimeZoneCell(tz: tz, flag: flagForTimeZone(tz), timeInZone: selectedTimeInZone(tz), selectedDate: selectedDate)
                        .onTapGesture {
                            if tz.isMemberOfEuropeanUnion {
                                #if os(iOS)
                                mediumImpactFeedbackGenerator.impactOccurred()
                                #endif
                                if timeZonesUsingEUFlag.contains(tz) {
                                    timeZonesUsingEUFlag.remove(tz)
                                } else {
                                    timeZonesUsingEUFlag.insert(tz)
                                }
                            }
                        }
                        .contextMenu {
                            DeleteButton {
                                selectedTimeZones.removeAll { $0 == tz }
                            }
                        }
                }
                .onMove(perform: move)
                .onDelete(perform: delete)
            }
            .listStyle(PlainListStyle())
            .padding(.top, (selectionViewMaxHeight ?? 0))
        }
        .sheet(isPresented: $showTimeZoneSheet) {
            NavigationView {
                #if os(iOS)
                TimezoneChoiceView(selectedTimeZone: .constant(TimeZone.current), selectedTimeZones: $selectedTimeZones, selectedDate: $selectedDate, selectMultiple: true)
                    .navigationBarItems(trailing:
                                            Button(action: {
                        self.showTimeZoneSheet = false
                    }) {
                        Text("Done")
                    }
                    )
                #else
                TimezoneChoiceView(selectedTimeZone: .constant(TimeZone.current), selectedTimeZones: $selectedTimeZones, selectedDate: $selectedDate, selectMultiple: true)
                #endif
            }
        }
        .navigationViewStyle(Self.navigationViewStyle)
        .onAppear {
            selectedTimeZones = UserDefaults.standard.mykeModeTimeZones
            timeZonesUsingEUFlag = UserDefaults.standard.mykeModeTimeZonesUsingEUFlag
        }
        .onChange(of: selectedTimeZones) { newValue in
            UserDefaults.standard.mykeModeTimeZones = newValue
        }
        .onChange(of: timeZonesUsingEUFlag) { newValue in
            UserDefaults.standard.mykeModeTimeZonesUsingEUFlag = newValue
        }
        
    }
    
    func move(from source: IndexSet, to destination: Int) {
        selectedTimeZones.move(fromOffsets: source, toOffset: destination)
    }
    
    func delete(at offsets: IndexSet) {
        selectedTimeZones.remove(atOffsets: offsets)
    }
    
}

private extension MykeMode {
    struct ViewHeightPreferenceKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat,
                           nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}

struct MykeMode_Previews: PreviewProvider {
    static var previews: some View {
        MykeMode()
    }
}
