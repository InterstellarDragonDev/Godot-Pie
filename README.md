# Godot-Pie
A simple Pie Menu made in godot

# Developer Notes
  "it works on my machine"

# Video :D


https://github.com/user-attachments/assets/41b7d013-694e-46ae-be28-caaab0fcdc13

please note that the blur effect is not part of GodotPie but is an effect caused by my Window Manager. The menu is actually fully transparent.
No icons shown here are included.


# How to install
  1) download the binary in releases or compile a binary yourself (see building section)
  2) go into your DE/WM config file and bind the binary to execute when a key is pressed. (please google this as every desktop environment is different)
  3) thats it. just restart your PC (or restart your session by loging out and in again) and it will work (if it doesn't than idk you're on your own  :) see Developers Notes for my response to you)

# How to use
  - GodotPie reads from a config file stored at ~/.config/godot-pie/config.cfg
  - To change what applications to launch you must edit this config file. (See Config Docs for details)
  - **Note that any command that can be run from the ternimal can be used.**
  - When the launcher is open, pressing on a button will open its corresponding app or open its submenu.
  - You don't need to hit the button exactly as it will automatically launch the app that is closest to the click location

# Launching Modes
  There are 2 available modes that can be choosen from to launch applications. The launcher mode to use is determined by the Settings of the config file (See Settings Docs). The first option is to use godots inbuilt execute function. This is the easiest and the default as it only requires the launcher binary to be downloaded and run. The other option is to use the daemon launcher which is a small python file that will run the application. If using this method you will need to download the daemon.py file and have it automatically run on startup.
  
  The reason for these 2 different modes is that for some reason godots inbuilt execute function launches most apps but fails to launch a few specific ones (at least for me) that is why if a certain app is not launching using the default launch method you will have to use the daemon. **If all your apps launch fine with the default then there is no need to set up the daemon.**

# Building

  I have provided a release version for linux.
  there is nothing stopping you from running this on windows though. It will just require you to change the config path manually and built from source code.
  If you want to build from source simply clone the repo, open the project in godot 4.4 (any other 4.xx version will probably work as well) and then compile the project manually using the export tab in the godot editor.
  There are plently of tutorials out there on how to compile with godot so just look up one of those.

  Automatic launching on key press is not supported natively. Please check your DE/WM documentation to launch the executable when a key is pressed.

# Docs

  ## Menu Features
  - press the centre icon to either exit a sub-menu or exit the launcher entirely.
  - you don't need to press the button to launch the app. by simply clicking anywhere on the launcher the nearest button will be automatically clicked for you, this allows for greater speed when launching apps.
  - If you want to change the rotation of the buttons and want an exact value; simply run GodotPie from the terminal. Pressing the arrow keys will allow you to rotate the buttons, the amount they have rotated by are output to the terminal.

  ## Config
  **Settings**
  extract from config file:
```
  [Settings]

animate_speed=0.2
radius=250
global_rotation=0.3
fading=true
dynamic_movement=true
clip_circle=false
centre_pointer=false
centre_icon="res://icon.svg"
run_method="godot"

```
- animate_speed: refers to how fast the buttons move to position
- radius: is how far they are from the centre
- global_rotation: is how the buttons are rotated around the centre
- fading: whether buttons further from the cursor fade to transparency
- dynamic_movement: whether buttons move in response to mouse movement
- clip_circle: whether the centre icon is clipped to a circle
- centre_pointer: Enables a little arrow at the centre to always point to the cursor
- centre_icon: is self explainitory
- run_method: choose between "godot" or "daemon" (See Launch modes for more info)

```
[Line_Settings]

connecting_lines=true
thickness=3.0
colour=Color(1, 1, 1, 0.5)

```
- connecting_lines: whether lines are drawn from the centre to each button
- thickness: the thickness of each line
- colour: do I even need this tooltip

**Submenus**

```
[Submenu 1]

Name="SubMenuName"
Type="sub-menu"
IconPath="/path/to/icon"
rotation=0.0
```
- Submenu 1: is just a section name and can be anything you want so long as it's never repeated in the rest of the file
- Name: is what will be shown when you run the pie-menu
- Type: this identifies this section as either an item or a sub-menu. it has to be either of those or the menu won't know what to render
- IconPath: you get the idea
- rotation: allows you to change the rotation of items within the submenu

**Items**

```
[Button 1]

Name="NameOfItem"
Type="item"
IconPath="/path/to/icon"
parent="root"
Command=""
```
- Button 1: is a section name so same as with the previous submenu
- Name: display name for the item
- Type: see submenu for explaination. (in this case it has to be "item")
- IconPath: again u get it
- parent: this is what the item belongs to. it must either be the **Name** of a submenu or it must be root
- command: the command that will be run when this item is clicked on
