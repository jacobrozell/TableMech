import SwiftUI

/// App-flow walkthrough for Ridge Line. Game math stays in the Rules tab.
struct HowToPlayRidgeLineView: View {
    var body: some View {
        List {
            Section {
                Text("Two players, four ’Mechs, about 40 minutes. The phone tells you the next tap.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("The four tabs") {
                flowRow(
                    title: "Play",
                    detail: "Start Ridge Line, or resume the game you left."
                )
                flowRow(
                    title: "Force",
                    detail: "The four 'Mechs and the numbers on their cards. Damage is tracked on the battle screen, not here."
                )
                flowRow(
                    title: "Rules",
                    detail: "Plain-language reminders if you get stuck. You don’t have to read them before you play."
                )
                flowRow(
                    title: "Settings",
                    detail: "Privacy, support, and the trademark note."
                )
            }

            Section("1. Start from Play") {
                paragraph("Tap Play Ridge Line. The app loads both teams.")
                paragraph("Side A is Shadow Hawk and Commando. Side B is Wolverine and Locust. One player takes each side.")
                Text("If a game is already saved, the app asks before it replaces it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("2. Set the table") {
                Text("The next screen is a short checklist: the maps, the tape, who sits where, and how you win.")
                Text("When the models and dice are out, tap Start.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("3. Each turn has four steps") {
                Text("The button at the bottom is the next action. Pass the phone when it says to.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                flowRow(
                    title: "Roll dice",
                    detail: "Each side rolls two dice on the table and types the numbers. The higher total goes last this turn, so they can react. Same total? Roll again."
                )
                flowRow(
                    title: "Move",
                    detail: "The side that lost moves a miniature first. Measure with the tape, then record Stood still, Walked, Sprinted, or Jumped. Then the other side, until every 'Mech has a move."
                )
                flowRow(
                    title: "Shoot",
                    detail: "Measure to the target, then tap Solve a shot. The app shows the number to beat. Type what you rolled and it applies the damage. Tap a 'Mech’s name to see its card. A wreck can still shoot until Clean up."
                )
                flowRow(
                    title: "Clean up",
                    detail: "Pick up any 'Mech whose Structure hit 0, then tap the button. If nobody has won, the next turn starts at Roll dice. Ridge Line lasts at most 6 turns."
                )
            }

            Section("4. How you win") {
                paragraph("Knock out both enemy ’Mechs. After turn 6, the side with more structure left wins. Equal structure is a draw.")
                Text("Then you can rematch, or go back to Play.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("5. Leave and come back") {
                paragraph("Leave saves the game. Play shows Continue, with the turn and the step.")
                Text("Quit and discard, in the ••• menu, throws that game away.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("How to play")
        .accessibilityIdentifier("as.howToPlay.screen")
    }

    private func flowRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .padding(.vertical, 2)
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)
    }

}
