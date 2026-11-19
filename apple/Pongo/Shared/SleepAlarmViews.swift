import PongoCore
import SwiftUI

/// Sleep timers that fade the music out, and alarms that fade it back in
/// before the user wakes up, as cards that start with a switch.
struct SleepAlarmsView: View {
    @Environment(AppModel.self) private var model
    @State private var alarms: [SleepAlarm] = []
    @State private var editing: SleepAlarm?
    @State private var creating = false
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                #if os(iOS)
                    if !alarms.isEmpty { volumeCard }
                #endif
                ForEach(alarms) { alarm in
                    AlarmCard(alarm: alarm) { editing = alarm } delete: { delete(alarm) }
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                if loaded && alarms.isEmpty {
                    VStack(spacing: 16) {
                        EmptyMessage(systemImage: "moon.zzz", title: L10n.createnewsleepalarm)
                        Button(L10n.create, systemImage: "plus") { creating = true }.buttonStyle(.glassProminent)
                            .tint(.pongoTeal)
                    }
                    .padding(.top, 80)
                }
            }
            .padding(15)
            .animation(.snappy, value: alarms)
        }
        .background { AppBackground() }
        .navigationTitle(L10n.sleep)
        .toolbar {
            Button(L10n.createnewsleepalarm, systemImage: "plus") { creating = true }
        }
        .sheet(item: $editing) { alarm in SleepAlarmEditor(alarm: alarm, isNew: false) }
        .sheet(isPresented: $creating) { SleepAlarmEditor(alarm: SleepAlarm(id: -1), isNew: true) }
        .task(id: model.libraryRevision) {
            alarms = (try? await model.database.sleepAlarms()) ?? []
            loaded = true
        }
    }

    #if os(iOS)
        /// The volume an alarm rises to.
        private var volumeCard: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.maximumvolumeofthealarm).font(.system(size: 15, weight: .semibold))
                ElasticSlider(
                    value: model.settings.settings.sleepAlarmDeviceVolume, height: 7, focusedHeight: 14,
                    onChanged: { level in model.settings.update { $0.sleepAlarmDeviceVolume = level } }
                ) {
                    Image(systemName: "speaker.fill").frame(width: 24)
                } trailing: {
                    Image(systemName: "speaker.wave.3.fill").frame(width: 28)
                }
                .tint(.primary)
            }
            .padding(16)
            .background(Color.pongoCard.opacity(0.55), in: .rect(cornerRadius: 22, style: .continuous))
            .environment(\.colorScheme, .dark)
        }
    #endif

    private func delete(_ alarm: SleepAlarm) {
        if model.player.activeSleepAlarm == alarm.id { model.player.stopSleepAlarm() }
        Task {
            try? await model.database.removeSleepAlarm(alarm.id)
            model.libraryChanged()
        }
    }
}

/// One sleep alarm: what it does, a switch that starts it, and a menu.
private struct AlarmCard: View {
    @Environment(AppModel.self) private var model
    let alarm: SleepAlarm
    var edit: () -> Void
    var delete: () -> Void

    var body: some View {
        let active = model.player.activeSleepAlarm == alarm.id
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                if alarm.sleep {
                    Label {
                        Text("\(L10n.sleepin) \(alarm.sleepDuration) min")
                    } icon: {
                        Image(systemName: "moon.zzz.fill").foregroundStyle(Color.pongoIcon)
                    }
                }
                if alarm.alarmClock {
                    Label {
                        Text("\(L10n.alarm) \(wakeTime(alarm.wakeTime))")
                    } icon: {
                        Image(systemName: "alarm.fill").foregroundStyle(Color.pongoIcon)
                    }
                }
                if !alarm.sleep && !alarm.alarmClock {
                    Text(L10n.off).foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 19, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            Toggle(isOn: Binding { active } set: { start in toggle(start) }) {}
                .labelsHidden()
                .tint(.pongoTeal)
        }
        .padding(18)
        .background(
            active ? Color.pongoTeal.opacity(0.25) : Color.pongoCard.opacity(0.55),
            in: .rect(cornerRadius: 22, style: .continuous)
        )
        .contentShape(.rect(cornerRadius: 22))
        .onTapGesture(perform: edit)
        .contextMenu {
            Button(L10n.change, systemImage: "pencil", action: edit)
            Button(L10n.delete, systemImage: "trash", role: .destructive, action: delete)
        }
        .animation(.snappy, value: active)
    }

    private func toggle(_ start: Bool) {
        let player = model.player
        if !start {
            player.stopSleepAlarm()
        } else if player.queue.isEmpty {
            model.messages.show(L10n.thequeuemustnotbeemptyinordertostartthealarm, systemImage: "alarm", isError: true)
        } else if !alarm.sleep && !alarm.alarmClock {
            model.messages.show(L10n.cannotstartalarm, systemImage: "alarm", isError: true)
        } else {
            player.startSleepAlarm(alarm)
        }
    }
}

/// A time of day stored as minutes after midnight, such as `07:30`.
func wakeTime(_ minutes: Int) -> String {
    String(format: "%02d:%02d", minutes / 60, minutes % 60)
}

/// Creates or changes a sleep alarm with wheels for its times.
struct SleepAlarmEditor: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State var alarm: SleepAlarm
    var isNew: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $alarm.sleep.animation()) {
                        GroupedRow(systemImage: "moon.zzz.fill", title: L10n.sleepin)
                    }
                    if alarm.sleep {
                        Picker(L10n.sleep, selection: $alarm.sleepDuration) {
                            ForEach(Array(stride(from: 5, through: 240, by: 5)), id: \.self) { minutes in
                                Text(verbatim: "\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 130)
                        Toggle(L10n.linearsleepin, isOn: $alarm.sleepLinear)
                    }
                } footer: {
                    if alarm.sleep { Text(L10n.pongowillgraduallylowerthevolumefor) }
                }
                .groupedRowBackground()
                Section {
                    Toggle(isOn: $alarm.alarmClock.animation()) {
                        GroupedRow(systemImage: "alarm.fill", title: L10n.alarm)
                    }
                    if alarm.alarmClock {
                        DatePicker(selection: wakeDate, displayedComponents: .hourAndMinute) {}
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        Stepper(value: $alarm.beforeEndTimeMin, in: 5...120, step: 5) {
                            LabeledContent(L10n.beforeyouneedtowakeupat, value: "\(alarm.beforeEndTimeMin) min")
                        }
                        Toggle(L10n.linearalarm, isOn: $alarm.alarmClockLinear)
                    }
                } footer: {
                    if alarm.alarmClock { Text(L10n.pongowillgraduallyincreasethevolume) }
                }
                .groupedRowBackground()
            }
            .tint(.pongoTeal)
            .pongoBackground()
            .navigationTitle(L10n.sleepandalarmclock)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.cancel) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? L10n.create : L10n.change) { Task { await save() } }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func save() async {
        guard alarm.sleep || alarm.alarmClock else {
            model.messages.show(L10n.cannotcreateasleepalarmwithoutthe, systemImage: "alarm", isError: true)
            return
        }
        if isNew {
            _ = try? await model.database.addSleepAlarm(alarm)
        } else {
            try? await model.database.updateSleepAlarm(alarm)
        }
        model.libraryChanged()
        dismiss()
    }

    private var wakeDate: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: alarm.wakeTime / 60, minute: alarm.wakeTime % 60, second: 0, of: Date())
                ?? Date()
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            alarm.wakeTime = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        }
    }
}
