# KlazStats

A World of Warcraft add-on that displays fps, latency, durability, and clock on screen.

Use the command `/klazstats` to see some in-game options. All other settings are hard-coded.

## Features

- Frames per second
- Latency connection to realm server
- Durability of equipped items in gradient scale (e.g. red = broken)
- Time in military format (24-hour clock)
- Garbage collection of add-on memory usage (i.e. `collectgarbage()`)

## Screenshots

Default view displaying fps, latency, durability, and clock in player's class colours.

![](https://github.com/haothitran/KlazStats/blob/master/Media/ScreenshotDefault.png?raw=true)

Hovering mouse over the stats frame will display a tooltip with more information about individual add-on memory usage and network latency.

![](https://github.com/haothitran/KlazStats/blob/master/Media/ScreenshotTooltip.png?raw=true)

## Installation

1. Backup `World of Warcraft\_retail_\Interface` and `World of Warcraft\_retail_\WTF` folders. Just in case.
2. Download and extract folder.
3. Place extracted folder in `World of Warcraft\_retail_\Interface\AddOns\` directory.
4. Restart World of Warcraft client.
