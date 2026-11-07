OctoWoW Raid Poker v1.2.7 - Multiplayer RAID Transport

Install this version on ALL raid players. /orp opens the poker table; /orp debug opens diagnostics; /orp nettest tests the addon transport; /orp sync requests cards.

NETWORK FIX:
* OctoWoW rejects addon WHISPER with "Unknown addon chat type".
* RAID addon transport was verified bidirectionally with Jarat and Belerda.
* Game traffic now uses RAID. Targeted HAND and control packets carry a TO:<player>: prefix.
* Only the intended recipient processes a targeted packet. Leader validates sender and turn.
* HANDACK diagnostics confirm when a client accepts a five-card hand.

IMPORTANT FAIRNESS LIMITATION:
* RAID addon traffic is broadcast to everyone in the raid. Recipient tags are NOT encryption.
* Other raid members using modified addons can inspect every player's cards.
* This release is intended to validate functional multiplayer, NOT secure competitive poker.
* Gold is tracked manually; the addon does not transfer gold.

Please test with two clients and share both SavedVariables logs after logout.

Version 1.3.17: Poker Settings > UI Scale (75%-150%, 5% increments). Changes the main table immediately and saves the chosen scale in OctoPokerDB.uiScale. Default 125%.


v1.3.38: Rebuilt all twenty high-rank cards (10-A) from the approved boss-art concept. Single-frame Classic Poker cards, TGA 256x512. Updated 52-card boss roster.
