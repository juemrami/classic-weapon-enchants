<div align="center">
<h1>
  Classic Weapon Enchants
</h1>
</br>
  <p align="center">
    A small addon for managing temporary weapon enchants in classic world of warcraft. Parses bags for valid item and centralizes them in a flyout menu where they can be easily applied to a weapon depending on the click type. Supports poisons, sharpening stones, weapon oils, and shaman enhancements. 
  </p>
</br>
<img width="80%" src="https://i.imgur.com/GbFFotd.gif">
</div>
<!-- ![gif](https://i.imgur.com/GbFFotd.gif) -->

## Usage:

  1. Hover over the toggle button to open the flyout menu

  2. Click
  - **Left-click**: Apply the selected enchant to the main hand weapon
  - **Right-click**: Apply the selected enchant to the off-hand weapon

## Todo:

- [ ] Add a settings dropdown on right clicking the toggle button to allow for some customization
  - [ ] Flyout direction
  - [ ] Flyout Toggle Mode (Click/Hover)
  - [ ] Hide delay duration on hover mode
  - [ ] add a "Hide" option to completely hide the flyout toggle
- [x] Add support or additional flyout directions.
  - *roughly* implemented. The icons are not organized in a way that makes sense for the new directions, but the flyout does appear in the correct location.
  - [ ] Fix the icon organization for the new directions
- [ ] Add a "click" mode for the flyout toggle by implement it as checkbox widget.

  
## Limited Combat Support:

Because these actions are all protected (casting a spell/using an item), during combat the addon's functionality may be limited.

For now im not handling the edge case of getting new weapon enchant items while in combat, so if you get a new item/enchant while in combat you will have to wait until you are out of combat to see it in the flyout.