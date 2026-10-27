import SwiftUI

/// App-flow walkthrough for Ridge Line. Game math stays in the Rules tab.
struct HowToPlayRidgeLineView: View {
    var body: some View {
        List {
            Section {
                Text("Ridge Line is the beginner game: two players, four 'Mechs, about 40 minutes. The miniatures stay on the table. This phone tells you what to do next. Here is the whole path, from the first tap to a winner.")
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
                Text("Tap Play Ridge Line. The app loads both teams.")
                Text("Side A is Shadow Hawk and Commando. Side B is Wolverine and Locust. One player takes each side. Sit so you can both see the phone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("If a game is already saved, the app asks before it replaces it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("2. Set the table") {
                Text("The next screen is a short checklist: the maps, the tape, who sits where, and how you win.")
                Text("When the models and dice are out, tap “The table is set — start the first turn.”")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("3. Each turn has four steps") {
                Text("The screen always says what to do now. The button at the bottom is the next action. When it says to pass the phone, hand it over before you tap.")
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
                Text("Knock out both enemy 'Mechs. If any are still standing after turn 6, the side with more Structure left wins. The same Structure is a draw.")
                Text("Then you can rematch with fresh damage, or go back to Play.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("5. Leave and come back") {
                Text("Leave saves the game. Play shows Resume, with the turn and the step you were on.")
                Text("Quit and discard, in the ••• menu during a game, throws that progress away.")
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
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
