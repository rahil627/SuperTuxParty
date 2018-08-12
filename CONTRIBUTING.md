# Contributing

## Git
[git-lfs](https://git-lfs.github.com/) is used in this project for handling
asset files. Tutorial for git-lfs can be found [here]
(https://www.atlassian.com/git/tutorials/git-lfs).

Too clone the repository, simply run:
- `git clone https://gitlab.com/SuperTuxParty/SuperTuxParty.git`
- `git lfs pull`

If you want to merge changes into the repository you must first fork the
project, upload your changes there and then create a merge request on the main
repository.

## Tools
Super Tux Party is built in Godot 3.0.6 with GDscript.
3D models are exported from [Blender](https://www.blender.org/) with the
[godot-blender-exporter](https://github.com/godotengine/godot-blender-exporter)
add-on installed.
### File structure
- Assets should be placed in the same folder as the scene using them.
- Exception to that should be assets that are used a lot across multiple scenes,
  they should have their own folder
- Minigames should be placed in the corresponding folder under the `minigames`
  folder
- Boards should be placed under the `boards` folder in their own folder: the
  name must match the name of the board

## Coding style
- All file names are lowercase
- All function and variable names use snake_case
- No semicolons