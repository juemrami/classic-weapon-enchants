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

## Todo:

- [ ] Add a settings dropdown on right clicking the toggle button to allow for some customization
 - Flyout direction
 - Flyout Toggle Mode (Click/Hover)
 - Hide delay duration on hover mode
 - add a "Hide" option to completely hide the flyout toggle
- [ ] Add support or additional flyout directions.
- [ ] Add a "click" mode for the flyout toggle by implement it as checkbox widget.

  
## Limited Combat Support:

Because these actions are all protected (casting a spell/using an item) durring combat, the addon (any any others like it) can be limited at times.

Typically you shouldn't notice any bugs durring normal use

For now im not handling the edge case of getting new weapon enchant items while in combat, so if you get a new item/enchant while in combat you will have to wait until you are out of combat to see it in the flyout.