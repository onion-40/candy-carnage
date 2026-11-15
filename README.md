# candy-carnage

A 2D tower-defense prototype made with Godot 4.7.

## Note: Candy Carnage is still in prototyping phase, so most elements are still in blobs and squares.

## Run it

1. **Download this repo as ZIP**
2. Extract the ZIP file to access the .exe file (**Candy Carnage.exe**)
3. Play and Enjoy :)

## How to play

A **How to Play** popup opens when the game starts. Reopen it any time with the **?** button in the top-right corner.

- Enemies follow the road. Each one that reaches the end takes HP from your base. At 0 HP it's game over, and **Restart** starts a new game.
- The game has 6 waves. Survive all of them to reach the **Victory** screen, then **Play Again** to start over.
- **Left-click a blue tower spot** to select it (it turns yellow), then pick a tower in the bottom HUD to build it there (Laser costs 15 bones and 5 organs, Cannon costs 25 bones and 7 organs). A greyed-out button means you can't afford it yet.
- Towers shoot the nearest enemy in range. A killed enemy drops a random body part on the ground: bones (60%), organs (35%) or eyeballs (5%). **Click it to collect it**, otherwise it is collected automatically after 8 seconds.
- **Click a tower** to open its panel, then **Upgrade** (up to level 3) or **Sell** (refunds half the build cost).
- **Click the Special Character Button** to enable special character ability/deployment.
- **Use your cursor to choose where to deploy your special character**
- **Click on the chosen area** to deploy your special character

Work in Progress: 
- HP label for Special Character 
- Additional Shape and Color Shift in tower type upgrades

## UPDATE 1.2
- **Added 3 more waves to test game difficulty**
- Nerfed towers to make current enemies harder to kill
- Gave enemies more HP for testing purposes

## UPDATE 1.3.1
- Build buttons show their cost and grey out when you can't afford them
- The Upgrade button shows "NOT ENOUGH RESOURCES" or "MAX LEVEL" instead of silently doing nothing
- The selected tower spot is highlighted
- Moved the 6th tower spot out from under the bottom HUD, where it couldn't be clicked

## UPDATE 1.3.2 (playtest build)
- Victory screen when all 6 waves are cleared, with waves cleared, base HP left and a Play Again button
- How to Play popup on launch (the game waits until you close it), reopenable with the ? button
- Code cleanup: removed debug logs and unused files
