<h1 align="center">Classic Weapon Enchants</h1>
<div align="center">
  <p align="center">
    A small addon for managing temporary weapon enchants in classic world of warcraft. Parses bags for valid item and centralizes them in a flyout menu where they can be easily applied to a weapon depending on the click type. Supports poisons, sharpening stones, weapon oils, and shaman enhancements.
  </p>
  <img width="80%" src="https://i.imgur.com/GbFFotd.gif" alt="Addon usage showcase">
</div>
<!-- ![gif](https://i.imgur.com/GbFFotd.gif) -->

## Usage

1. Hover to open the flyout menu.
2. Click weapon enchant.
    1. **Left-click**: Apply the selected enchant to the main hand weapon
    2. **Right-click**: Apply the selected enchant to the off-hand weapon

*Supports Season of Discovery ✔️*.

### Slash Commands

usage: `/cwe {command} {arg}`

- `show` - Shows the flyout toggle
- `hide` - Hides the flyout toggle
- `reset` - Resets the flyout menu to its default position
- `debug` - Toggles debug print statements
- `direction` or `dir` - Sets the direction of the flyout menu
  - `up` - Flyout will appear above the toggle button (default)
  - `down` - Flyout will appear below the toggle button
  - `left` - Flyout will appear to the left of the toggle button
  - `right` - Flyout will appear to the right of the toggle button
- `lines` - Sets the number of lines in the flyout menu
  - `1` - Flyout menu will have 1 line (default)
  - `2` - Flyout menu will have 2 lines
  - `3` - Flyout menu will have 3 lines (pictured)
  - *Inputs beyond `3` not encouraged; maybe not behave as expected*
- `delay` - Sets the delay duration in seconds for the flyout menu to hide after the mouse leaves the flyout
  - `[0.2, 5]` - number between `0.2` and `5`, inclusive
  - default is `0.5`, recommended is `0.25`
  - *Inputs clamped*
- `icon` - Sets the flyout toggle button's icon
  - arg is a either a number, which can be a `iconFileID` or a preset `[0-4]`
    - `0` - This fallback icon is dynamic based on the players class.
    - `1` - Poison icon
    - `2` - Weapon oil icon
    - `3` - Sharpening stone icon
    - `4` - Shaman enhancement icon
  - or a `iconFilePath` string such as `"Interface\Icons\INV_Misc_QuestionMark"`

## Todo

1. [ ] Add Dropdown settings on right clicking the toggle button to allow for some customization
    1. Would include options such as:
        - Flyout direction
        - Flyout Toggle Mode (Click/Hover)
        - Hide delay duration on hover mode
        - add a "Hide" option to completely hide the flyout toggle
2. [x] Add support or additional flyout directions.

    *roughly* implemented. The buttons are not organized in a way that makes sense for the new directions, but the flyout does appear in the correct location.
    1. [ ] Fix the button organization for the new directions
3. [ ] Add a "click" mode for the flyout toggle by implement it as checkbox widget.
4. [x] fix bug with `debug` value being reset to `false` on reload occasionally.

## Limitations

Because these actions are all "protected" (casting a spell/using an item in), during combat the addon's functionality *may* be limited.

For now im not handling the edge case of getting new weapon enchant items while in combat, so if you get a new item/enchant while in combat you will have to wait until you are out of combat to see it in the flyout.
