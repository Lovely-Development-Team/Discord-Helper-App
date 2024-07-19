//
//  DateTimeZoneSheet.swift
//  Elsewhen
//
//  Created by Ben Cardy on 18/06/2022.
//

import SwiftUI
import CoreML
import NaturalLanguage

struct DateTimeZoneSheet: View {
    
    enum ErrorMessage {
        case noDateDetected
        case none
        
        var message: String {
            switch self {
            case .noDateDetected:
                return "No date or time was detected in the input."
            default:
                return "An error occurred"
            }
        }
    }
    
    // MARK: Init arguments
    
    @Binding var selectedDate: Date
    @Binding var selectedTimeZone: TimeZone?
    @Binding var selectedTimeZones: [TimeZone]
    @Binding var selectedTimeZoneGroup: TimeZoneGroup?
    let multipleTimeZones: Bool
    
    // MARK: State
    
    @State private var showTimeZoneChoiceSheet: Bool = false
    
    
    // MARK: Natural Language
    @State private var naturalTextInput: String = ""
    @State private var dataDetector: NSDataDetector!
    @State private var relativeTimeClassifier: DateTimePartTaggerModel!
    @State private var showingTextInput = false
    
    func parseRelativeTimeInput(input: String) {
        do {
            // Honestly I don't understand the NLModel and NLTagger blocks.
            // This is what Apple's documentation said to do
            let customModel = try NLModel(mlModel: relativeTimeClassifier.model)
            let customTagScheme = NLTagScheme("RelativeDate")
                
            let tagger = NLTagger(tagSchemes: [.nameType, customTagScheme])
            tagger.string = input
            tagger.setModels([customModel], forTagScheme: customTagScheme)
            
            var intervals: [String] = []
            var units: [String] = []
            // true = forward, false = backward
            var direction = true
        
            // Iterate through detected tags
            // * UNIT (i.e. 3 *minutes*)
            // * INTERVAL (i.e. *3* minutes)
            // * DIRECTION (i.e. "from now", "ago")
            tagger.enumerateTags(in: input.startIndex..<input.endIndex, unit: .word,
                                 scheme: customTagScheme, options: .omitWhitespace) { tag, tokenRange  in
                // Make sure the tag exists
                guard let tag = tag else {
                    return false
                }
                
                // Grab the text associated with the tag
                let text = input[tokenRange]
                
                // Check which kind of tag it is
                switch tag.rawValue {
                case "INTERVAL":
                    intervals.append(String(text))
                case "UNIT":
                    units.append(String(text))
                case "DIRECTION":
                    switch text.lowercased() {
                    case "ago":
                        direction = false
                    default:
                        direction = true
                    }
                default:
                    break
                }
                
                // Gotta return something in this block
                return true
            }
            
            // Show error if no date or time detected
            if intervals.isEmpty || units.isEmpty {
                self.showError(.noDateDetected)
                return
            }
            
            // We're going to add the detected dates/times to the current time
            var newDate = Date.now
            
            for (i,interval) in intervals.enumerated() {
                guard let parsed = Int(interval) else {
                    continue
                }
                
                // Make sure the interval has an associated unit
                if units.count > i {
                    let unit = units[i]
                    
                    // Convert the unit string into a calendar component
                    guard let component = Calendar.Component.fromString(unit) else {
                        continue
                    }
                    
                    // Add the converted component * interval to the accumulated time
                    newDate = Calendar.current.date(byAdding: component,
                                                    value: parsed * (direction ? 1 : -1),
                                                    to: newDate) ?? newDate
                } else {
                    break
                }
            }
            
            selectedDate = newDate
            
        } catch {
            print(error)
            self.showError(.none)
        }
    }
    
    func processNaturalTextInput(newValue: String) {
        let matches = dataDetector.matches(in: newValue, range: NSMakeRange(0, newValue.count))
        // First check for dates
        if let match = matches.first, let date = match.date {
            selectedDate = date
        } else {
            // If no dates detected, check for relative time
            parseRelativeTimeInput(input: newValue)
        }
    }
    
    // MARK: Error
    @State var showingErrorAlert = false
    @State var errorMessage: ErrorMessage = .none
    
    func showError(_ message: ErrorMessage) {
        self.errorMessage = message
        self.showingErrorAlert = true
    }
    
#if os(macOS)
    @State private var isPresentingDatePopover: Bool = false
    @State private var showTimeZoneChoicePopover: Bool = false
    @Environment(\.isInPopover) private var isInPopover
#endif
    
    var timeZoneLabel: String {
        multipleTimeZones ? "Time Zones" : "Time Zone"
    }
    
    var timeZoneButtonValue: String {
        multipleTimeZones ? "Choose Time Zones" : selectedTimeZone?.friendlyName ?? TimeZone.current.friendlyName
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Time").fontWeight(.semibold)
                Spacer()
                
#if os(macOS)
                Button {
                    isPresentingDatePopover = true
                } label: {
                    Text("\(selectedDate, style: .date)").foregroundColor(.primary)
                }
                .popover(isPresented: $isPresentingDatePopover, arrowEdge: .top) {
                    Group {
                        MacDatePicker(selectedDate: $selectedDate)
                            .padding(8)
                    }.background(Color(NSColor.controlColor))
                }
                
                DatePicker("", selection: $selectedDate, displayedComponents: [.hourAndMinute])
                    .frame(maxWidth: 100)
                    .padding(.trailing)
                
#else
                DatePicker("Time", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
#endif
                Button(action: {
                    naturalTextInput = ""
                    showingTextInput = true
                }) {
                    Image(systemName: "keyboard")
                }
                Button(action: {
                    withAnimation {
                        selectedDate = Date()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
#if os(iOS)
                .hoverEffect()
#endif
            }
            HStack {
                Text(timeZoneLabel).fontWeight(.semibold)
                Spacer()
                Button(action: {
#if os(macOS)
                    showTimeZoneChoicePopover = true
#else
                    showTimeZoneChoiceSheet = true
#endif
                }) {
                    Text(timeZoneButtonValue)
                }
                .foregroundColor(.primary)
                .padding(.vertical, 8)
#if os(iOS)
                .padding(.horizontal, 10)
                .hoverEffect()
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(UIColor.systemGray5))
                )
#endif
                #if os(macOS)
                .popover(isPresented: $showTimeZoneChoicePopover, arrowEdge: .leading) {
                    TimezoneChoiceView(selectedTimeZone: $selectedTimeZone, selectedTimeZones: $selectedTimeZones, selectedDate: $selectedDate, selectMultiple: multipleTimeZones) {
                        showTimeZoneChoicePopover = false
                    }
                    .frame(minWidth: 300, minHeight: 300)
                }
                #endif
            }
            
            #if os(macOS)
            if isInPopover {
                Divider()
                Button(action: {
                    WindowManager.shared.openMain()
                }) {
                    Text("Open Elsewhen")
                }
                .padding(.top, 8)
            }
            #endif
            
        }
        .padding([.horizontal, .bottom])
        .padding(.top, 10)
        .onAppear {
            do {
                // initialize data detector and ML model
                dataDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
                relativeTimeClassifier = try DateTimePartTaggerModel(configuration: MLModelConfiguration())
            } catch {
                print(error)
                self.showError(.none)
            }
        }
        .alert("Error", isPresented: $showingErrorAlert, actions: {
            Button(action: {
                errorMessage = .none
            }, label: {
                Text("OK")
            })
        }, message: {
            Text(errorMessage.message)
        })
        .alert("Enter Time", isPresented: $showingTextInput, actions: {
            Button(action: {
                withAnimation {
                    processNaturalTextInput(newValue: naturalTextInput)
                }
            }, label: {
                Text("OK")
            })
            Button(role: .cancel, action: {}, label: {
                Text("Cancel")
            })
            TextField("Type A Time", text: $naturalTextInput)
        })
#if os(iOS)
        .sheet(isPresented: $showTimeZoneChoiceSheet) {
            NavigationView {
                TimezoneChoiceView(selectedTimeZone: $selectedTimeZone, selectedTimeZones: $selectedTimeZones, selectedDate: $selectedDate, selectMultiple: multipleTimeZones) {
                    showTimeZoneChoiceSheet = false
                }
                .navigationBarItems(trailing: Button(action: {
                    if multipleTimeZones, let selectedTimeZoneGroup = selectedTimeZoneGroup, selectedTimeZones != selectedTimeZoneGroup.timeZones {
                        self.selectedTimeZoneGroup = nil
                    }
                    showTimeZoneChoiceSheet = false
                }) {
                    Text("Done")
                }
                )
            }
        }
#endif
    }
    
}

struct DateTimeZoneSheet_Previews: PreviewProvider {
    static var previews: some View {
        DateTimeZoneSheet(selectedDate: .constant(Date()), selectedTimeZone: .constant(nil), selectedTimeZones: .constant([]), selectedTimeZoneGroup: .constant(nil), multipleTimeZones: false)
    }
}

extension Calendar.Component {
    static func fromString(_ string: String) -> Calendar.Component? {
        guard let first = string.lowercased().first else {
            return nil
        }
        
        // We're checking the first letter of the unit string to determine its type
        switch first {
        case "s":
            return .second
        case "m":
            // "m" can be Minute or Month so check the second letter
            let start = string.index(string.startIndex, offsetBy: 1)
            guard string.count >= 2 else {
                return .minute
            }
            let second = string.lowercased()[start...start]
            return (second == "o") ? .month : .minute
        case "h":
            return .hour
        case "d":
            return .day
        case "w":
            return .weekOfYear
        case "y":
            return .year
        default:
            return nil
        }
    }
}
