OctoWoW Raid Poker
Complete Addon Description & User Guide — Version 1.4.13
1. Overview
OctoWoW Raid Poker is a multiplayer poker addon for World of Warcraft, designed for raid-group entertainment on the OctoWoW server.

The addon allows players to participate in a complete Five Card Draw Poker game without leaving World of Warcraft.

Players can join a shared poker table, receive five cards, place bets, exchange cards, compete for the pot, and track their winnings.

The Raid Leader acts as the game host and controls the poker table, player balances, betting settings, and game administration.
Game Type: Five Card Draw Poker

Players: 2–10 participants

Currency: Virtual Silver (s)

Host: Raid Leader

Interface: World of Warcraft Classic style


Important: The addon does not automatically transfer actual in-game gold or silver between players. All poker balances and bets are tracked virtually. Any real payment arrangements must be handled separately by the players.
https://github.com/PizzaCompanyCom/Server-OctoWoW-5-Card-Poker/issues/1#issue-6261907727
2. Custom Raid Boss Playing Cards































The addon features a custom 52-card deck with World of Warcraft raid and dungeon boss artwork.

Each card has a standard poker rank and suit, with a unique fantasy-themed portrait.

The deck includes:
- 13 ranks: 2 through 10, Jack, Queen, King, and Ace.
- 4 suits: Spades, Hearts, Diamonds, and Clubs.
- Custom boss illustrations, including characters such as Ragnaros, C'Thun, Kel'Thuzad, and other Warcraft bosses.
All cards follow standard poker rules. The artwork does not affect the value of the cards.
3. How to Play Five Card Draw
1. Join the Table
   
   The Raid Leader hosts the game, and participants click Join Table.
2. Start Hand
   
   The Raid Leader starts a new hand. Each participant contributes the configured ante and receives five cards.
3. First Betting Round — BET1
   
   Players take turns checking, calling, raising, folding, or going All-In.
4. Card Exchange — DRAW
   
   Players can select unwanted cards and exchange them, or keep their original hand using Stand Pat.
5. Second Betting Round — BET2
   
   Players place their final bets after the card exchange.
6. Showdown
   
   Remaining hands are compared. The strongest eligible hand wins the pot.
7. Winner Announcement
   
   The winner is displayed, the virtual bank is distributed, and the table becomes ready for another hand.

If all other players fold, the last remaining player wins without needing to reveal or compare a winning combination.
4. Main Poker Window — All Buttons
Table and card controls
Button	Function
Join Table	Join the current poker game.
Leave Table	Leave the poker table.
Start Hand	Start a new poker hand when the game is ready.
Exchange	Replace selected cards during the DRAW phase.
Stand Pat	Keep all five cards without exchanging.
Fold	Surrender the current hand.

During card exchange, click the cards you want to replace, then press Exchange. If you want to keep all five, press Stand Pat.
Betting controls
Check


Call


Raise


Fold Bet


All-In



Illustrative button layout
Button	Function
Check	Continue without adding a bet when no additional call is required.
Call	Match the current required bet.
Raise	Increase the bet by the amount entered in the Raise field, subject to game rules.
Fold Bet	Fold during the betting round.
All-In	Commit the player's entire available virtual balance.

The addon tracks contributions to the pot and includes support for All-In and side-pot distribution.
5. Betting Presets 2.0
The main window includes a Raise input field and six quick-bet buttons.
Button	Description
+10s	Add 10 Silver to the proposed raise amount.
+50s	Add 50 Silver.
+100s	Add 100 Silver.
1/4 Pot	Calculate a raise based on one-quarter of the current pot.
1/2 Pot	Calculate a raise based on half of the current pot.
Pot	Calculate a raise based on the current pot.

These buttons prepare a betting amount; they do not immediately place the bet. The player must press Raise to submit it.

Pot and All-In are different. A pot-sized bet is based on the current bank, while All-In commits the player's remaining available balance.

The Raise input can retain the most recently entered value.
6. Betting Information Display
The main window displays four important values.
BANK
250s

CURRENT BET
50s

YOUR BALANCE
850s

TO CALL
50s


Example values, not live game data
Bank is the current total pot. Current Bet shows the betting level. Your Balance is the player's available virtual Silver. To Call is the amount required to match the current bet.
7. Visual Turn Timer
The addon uses one countdown bar integrated into the main poker window.
YOUR TURN — PLACE YOUR BET

24s





JARAT'S TURN — WAITING

12s





When it is your turn, the bar is green, turning yellow and then red as time runs out. When another player is acting, the bar is grey.

The timer is intended to stop when the betting round or hand ends.
Timer settings
Button	Function
15s	Set the turn limit to 15 seconds.
30s	Set the turn limit to 30 seconds.
60s	Set the turn limit to 60 seconds.
OFF	Disable the turn timer.

The default setting is 30 seconds. The Raid Leader controls the timer duration.

When the timer expires, the game is designed to perform Check if no call is required, or Fold if the player must match a bet.
8. Winner System 2.0
At the end of a hand, the addon determines the winner and distributes the virtual pot.

The WINNER popup is designed to display the winning player's name, the winning poker combination, and the pot.

For a victory caused by all opponents folding, no poker combination is displayed.

If multiple players have equally strong eligible hands, the result can be shown as SPLIT BANK!

The system also records results in Betting Activity and Hand History.
WINNER!
Jarat — Full House
BANK: 250s
Example popup content
Multiplayer note: Winner notifications on non-Raid-Leader clients have experienced synchronization problems in previous versions. Version 1.4.13 includes result retransmission and manual resend controls, but successful delivery on every client has not yet been fully confirmed.
9. Betting Activity
The BETTING ACTIVITY panel provides a running record of game actions.

It can show entries such as:
BETTING ACTIVITY | BANK: 250s

Jarat RAISES 50s
Belerda CALLS 50s
Jarat CHECKS
Belerda CHECKS

RESULT: Winner: Jarat


This allows players to follow the betting sequence without opening another window.
10. Player Balances
The Player Balances window is used for virtual bankroll management.

It displays player names, tracked balances, table participation, connection status, and administrative controls.
Player Balances functions
Control	Function
Player selection	Select a participant for administrative actions.
Balance input	Enter or adjust a player's virtual Silver balance.
Add / Remove	Increase or decrease tracked Silver, where available in the balance-management controls.
Enabled / Disabled	Toggle the player's participation eligibility.
Kick	Remove a player from the poker table.
Sort by Name	Sort players alphabetically.
Sort by Balance	Sort players by tracked balance.
Connection Status	Display available connection information.
Reset All Poker Data	Open the reset action with confirmation.

The Raid Leader is responsible for administrative balance changes.

The old quick-balance buttons 100s, 500s, 1000s, 5000s, and 10000s were removed from Player Balances.
11. Raid Leader Controls 2.0
Version 1.4.12 introduced a dedicated administration panel, retained in v1.4.13.

It can be opened through the crown icon in the top toolbar and is intended for the Raid Leader.
Manual hand management
Button	Function
End Betting	Advance the current betting stage only when required player actions and calls are complete.
Force Showdown	Immediately evaluate the current hands and calculate the winner.
Declare Winner	Manually select an eligible player and award the pot, overriding the normal hand-ranking result.
Cancel Hand	Cancel an active hand and refund contributed virtual Silver.
Select Player	Cycle through table participants to choose a player for manual winner declaration.

Manual actions require confirmation.

Manual winner declaration is restricted when an All-In situation exists, to avoid bypassing side-pot eligibility rules.
Chat announcements
The Raid Leader can choose either /raid or /say.
Button	Function
/raid	Select raid chat as the announcement channel.
/say	Select local Say chat.
Announce Winner	Post the latest recorded winner and pot result.
Announce Balances	Post the tracked balances of participating players.
Announce Table	Post the current phase, pot, and participant list.
Resend WINNER	Retransmit the most recent confirmed winner result to addon clients.

An example announcement:
[Raid Poker] Winner: Jarat - Pot: 250s
[Raid Poker] Current Balance: 850s


These are virtual accounting reports, not actual Silver transfers.
12. Top Toolbar Buttons
The compact top toolbar provides access to the main reference and configuration functions.
Icon / Button	Function
Sync Cards	Request or refresh synchronized card/game information.
Hand Rankings	Open the poker-hand ranking reference.
Game Rules	Open the rules of Five Card Draw.
Poker Help	Open the addon user guide.
Poker Settings	Open addon configuration.
Raid Leader Controls	Open administrative hand and announcement controls; Raid Leader only.

The toolbar uses WoW-style icons to reduce the number of large buttons in the main window.
13. Poker Settings
The settings interface provides configuration options for the poker experience, including supported appearance and sound settings.

Features developed for the addon include:
- Interface scaling and visual appearance.
- Table/background customization.
- Sound effects and sound volume.
- Winner popup visibility.
- Dealer Rotation ON/OFF.
Dealer Rotation automatically changes the dealer between hands. It is recommended for normal multiplayer play.

The exact available settings depend on the installed addon build.
14. Hand Rankings
The addon follows standard Five Card Draw poker rankings.
Rank	Poker Hand	Description
1	Royal Flush	A, K, Q, J, 10 of the same suit.
2	Straight Flush	Five consecutive cards of the same suit.
3	Four of a Kind	Four cards of the same rank.
4	Full House	Three of a kind plus a pair.
5	Flush	Five cards of the same suit.
6	Straight	Five consecutive ranks.
7	Three of a Kind	Three cards of the same rank.
8	Two Pair	Two different pairs.
9	One Pair	Two cards of the same rank.
10	High Card	A hand with none of the combinations above.

The strongest eligible combination wins. Ties are resolved using standard poker hand comparison, including kickers where applicable.
15. History and Statistics
History
The History button opens the record of completed hands and results. It allows players to review previous outcomes.
Player Statistics
The Player Statistics button opens the statistics interface for tracking poker performance.

The addon has developed statistics-related functionality for participation and outcomes. Some extended metrics, such as detailed lifetime profit analysis or separate Fold-win percentages, should be verified in the installed build before being treated as fully supported.
16. Connection Recovery and Multiplayer Synchronization
OctoWoW Raid Poker communicates through raid addon messages to coordinate the table.

The system includes mechanisms for:
- Synchronizing game phases and player actions.
- Updating virtual balances.
- Distributing card and game-state information.
- Recovering state after /reload or temporary desynchronization.
- Requesting missing game results.
- Resending the latest WINNER result.
Connection indicators can include CONNECTED, SYNCING, and NO RAID. The host is also distinguished internally.

Because the addon relies on multiplayer communication, all participants should use the same addon version.

Connection Recovery improves resilience but does not guarantee recovery from every disconnect or lost message.
17. Sound and Emote Buttons
The main interface includes five entertainment buttons.
Laugh


Cry


Chicken


Train


Roar




These buttons provide quick access to character emotes and entertainment actions during the poker game.

They do not change bets, cards, or player balances.
18. Reset All Poker Data
The Reset All Poker Data button provides an administrative reset function.

It is available in the main interface and also through Player Balances.

Because this is a potentially destructive operation, it should be used carefully and only by the Raid Leader.

It is recommended to finish any active hand and review player balances before performing a reset.
19. Recommended Multiplayer Setup
For normal play:
1. Install the same version of OctoWoW Raid Poker on all participating accounts.
2. Form a raid group and assign the intended Raid Leader.
3. Open the poker interface and have players join the table.
4. Configure the ante, player balances, and turn timer.
5. Start the first hand.
6. Play BET1, DRAW, and BET2.
7. Review the winner and distributed pot.
8. Use Raid Leader Controls if a manual intervention or announcement is necessary.
For the best experience, keep Dealer Rotation enabled and use the default 30-second turn timer.

20. Current Development Status — v1.4.13
OctoWoW Raid Poker now includes a broad set of gameplay, visual, and administrative features: custom raid-boss cards, Five Card Draw, betting, virtual balances, timer controls, game history, statistics, synchronization tools, and Raid Leader administration.

The main remaining priority is multiplayer reliability, particularly confirming that all non-host clients consistently receive winner notifications, stop their timers after showdown, and recover correctly after disconnections.

OctoWoW Raid Poker brings a complete fantasy-themed poker table into World of Warcraft, combining traditional Five Card Draw gameplay with raid-based multiplayer controls and Warcraft-inspired visuals.
