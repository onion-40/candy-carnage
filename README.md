# candy-carnage

A 2D tower-defense prototype made with Godot 4.7.

## Run it

1. Install [Godot 4.7](https://godotengine.org/download) (standard build, not .NET). On macOS you can use `brew install --cask godot`.
2. Clone the repo:
   ```bash
   git clone git@github.com:onion-40/candy-carnage.git
   ```
3. Open Godot, click **Import**, select `candy-carnage/project.godot`, then press **F5**.

Or run it straight from a terminal:

```bash
cd candy-carnage
godot --path .      # play
godot -e --path .   # open the editor
```

It's a native desktop game, so there is no URL or port.

## How to play

- Enemies follow the road. Each one that reaches the end takes HP from your base. At 0 HP it's game over.
- **Left-click a blue build spot** to place a Laser tower (costs 15 bones and 5 organs).
- Towers shoot the nearest enemy in range. A killed enemy drops a random body part: bones (60%), organs (35%) or eyeballs (5%). It goes straight into your resources at the bottom right.
- **Click a tower** to open its panel, then **Upgrade** (up to level 3) or **Sell** (refunds half the build cost).

Work in progress: the Laser/Heavy Cannon buttons in the bottom bar, the special character and the on-screen HP display are not wired up yet.
