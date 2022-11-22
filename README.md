# Anchor Annotations

This is a plugin for [Glyphs](https://glyphsapp.com) that offers many customizable modes for displaying anchors in Edit View.

![](Assets/Screenshot.png)

## Installation

[Install **Anchor Annotations** in Glyphs](https://florianpircher.com/glyphs/plugins/anchor-annotations/install)

Install the plugin using the link above or search for “Anchor Annotations” in the Plugin Manager.
Relaunch Glyphs for the plugin to be loaded.

## Usage

Activate and deactivate the plugin from the menu bar: *View* → *Show Anchor Annotations*.
You can assign a keyboard shortcut to this action in *Glyphs* → *Preferences…* → *Shortcuts* for quick access.

Anchors placed directly onto a layer appear as small diamond ◆ shapes.
Anchors that *shine through* from within components appear as downwards pointing triangle ⏷ shapes.

If there are multiple anchor names that would overlap one another, they are stacked vertically.
Anchor names that have been shifted are still connected to their original anchor position with a faint line.

## Settings

Anchor Annotations offers a range of configurable settings.

![](Assets/Settings.png)

### Include inactive layers

Select *Include inactive layers* if anchors from all layers should be shown, not only for the current layer.
On by default.

### Include nested anchors

Select *Include nested anchors* to show anchors which are included in component glyphs.
Note that not all anchors that are part of component glyphs are shown since some anchors might get overwritten by a different anchor of the same name on a higher nesting layer.
On by default.

### Display anchor names

Select *Display anchor names* to show the name of the anchors alongside their position.
The name of selected anchors will never be shown regardless of this setting.
On by default.

### Font size

The *Font size* controls the size of the anchor names as displayed by the plugin.

### Font width

On recent macOS versions, you can change the font width at which the anchor names are displayed.
Pick a narrow width to reduce the risk of colliding anchor names.
The default value is 90%; values from 50% (full compression) to 100% (no compression) can be chosen.

### Color

The *Color* setting controls the color of the anchor points and anchor names.
The options are *Red*, *Orange*, *Brown*, *Yellow*, *Green*, *Blue*, *Purple*, *Pink*, and *Gray*.
Additionally, the *Text* option applies the current foreground color.

You can define custom colors for certain anchor names in the *Special Colors* section.

### Abbreviations

The *Abbreviations* section lets you define text replacements for parts of anchor names.
These replacements do not affect the anchor name itself, only how it is displayed by the plugin.
Use arrows, dashes, or emoji to make anchor names stand out and take up less space visually.

The *Text* column of the table defines text patterns that get replaced by the respective entry in the *Abbr.* column.
Double-click an entry to edit it.

By default, “top” is shortened to “↑” and “bottom” is shortened to “↓”.
An anchor named `top` would thus appear as `↑` while an anchor named `bottomleft` would appear as `↓left`.

Add custom entries by clicking the plus button below the *Abbreviations* table.
To delete an entry, click on its row and then click the minus button.

Select the *Case insensitive* setting to perform these text replacements regardless of capitalization.
For example, with this setting selected and “top” mapping to “↑”, “TopLeft” would appear as “↑Left”.

### Special Colors

In the *Special Colors* you can define colors deviating from the main anchor color.
Add an entry and write the full name of an anchor in the *Anchor Name* column.
In the *Color* column, pick the color for anchors with this name.

## Licenses

Licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
