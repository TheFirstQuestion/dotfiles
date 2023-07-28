<h1 align="center">Dotfiles</h1>
<div id="top"></div>

<!--
# Steven G. Opferman | steven.g.opferman@gmail.com
# My personal template for README.md files, because I'm lazy :P
# Adapted from:
#   https://github.com/othneildrew/Best-README-Template/
#   https://github.com/kylelobo/The-Documentation-Compendium/
-->

<!--
<p align="center">
  <a href="" rel="noopener">
 <img width=200px height=200px src="https://i.imgur.com/6wj0hh6.jpg" alt="Project logo"></a>
</p>
-->

<!--
The cute little icon things.

<div align="center">

[![Status](https://img.shields.io/badge/status-active-success.svg)]()
[![GitHub Issues](https://img.shields.io/github/issues/kylelobo/The-Documentation-Compendium.svg)](https://github.com/kylelobo/The-Documentation-Compendium/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/kylelobo/The-Documentation-Compendium.svg)](https://github.com/kylelobo/The-Documentation-Compendium/pulls)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)

</div>
-->

<p align="center">
Settings for everything:
by me, for me.
</p>

## Table of Contents

- [About](#about)
- [Usage](#usage)
- [Getting Started](#getting_started)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Acknowledgements](#acknowledgements)

## About <a name="about"></a>

I have specific settings and tweaks for my tools that I like. They also (maybe) help me to be productive and consistent. They're here so that:

- I can keep them in sync across lots of different machines.
- I can refer back to a working version if something breaks.
- If I change my mind, I can undo an edit.
- Others can see what works for me, and figure out what works for them.

<p align="right">(<a href="#top">back to top</a>)</p>

## Usage <a name="usage"></a>

### Terminal Upgrades

- powerlevel10k theme, with cool colors and icons
- autosuggestions for commands
- syntax highlighting
- auto `ls` and `git status` (super convenient!!!)
- ssh shortcuts for my frequent servers
  - `ssh pi`
  - `ssh nas`
  - `ssh myth`
  - `ssh sLaptop`
- move around the filesystem in one keystroke
  - `z <part of folder name>`
- paste stuff into the terminal without accidentally running anything
- show and hide hidden files on macOS

### Templates

- GitHub README.md (like this one!)
  - `template README`
- `.gitignore` that works for lots of situations
  - `template gitignore`

### Scripts

- update all of the everything
  - `run_script update`
- log anything to the specific channel in my specific workspace
  - `log <message>`
- alert me via notification on all my devices
  - `alert <message>`
- play a beep (helpful to chain after long-ish running commands)
  - `<do something>; notify`
- initialize my personal folder structure
  - `run_script init-archive`
- make sure all of these dotfiles are up-to-date and properly linked
  - `dotbot`

### Atom Upgrades

- helpful snippets and syntax highlighting (especially for comments)
- settings for plugins

![usage screenshot](https://raw.githubusercontent.com/TheFirstQuestion/dotfiles/main/screenshot.png)

<!-- _For more examples, please refer to the [Documentation](https://example.com)_ -->

### Other Scripts I Use

- [autorandr](https://github.com/phillipberndt/autorandr/) automatically selects a display configuration based on connected devices
- [tzupdate](https://github.com/cdown/tzupdate) is a fully automated utility to set the system time using geolocation
- [rofi-calc](https://github.com/svenstaro/rofi-calc) does live calculations in rofi

<p align="right">(<a href="#top">back to top</a>)</p>

## Getting Started <a name="getting_started"></a>

These instructions will get you a copy of the project up and running.

### Installation

1. Clone the repo:

    ```sh
    git clone https://github.com/TheFirstQuestion/dotfiles.git && cd dotfiles
    ```

2. Run the install script:

    ```sh
    ./install
    ```

3. In the future, you can update and reinstall by running:

    ```sh
    dotbot
    ```

<p align="right">(<a href="#top">back to top</a>)</p>

## Roadmap <a name="roadmap"></a>

- [ ] `checkin` command that runs on startup
- [ ] `backup` script to sync files with my external hard drive
- [ ] cron jobs to schedule certain scripts (i.e. `update`)
- [ ] look into [xxh](https://github.com/xxh/xxh)
- [ ] different configurations for desktop vs. server
- [ ] install all dependencies
  - [ ] Atom plugins
  - [ ] Keybase
- [ ] Better integration with Winston?

<!--
See the [open issues](https://github.com/github_username/repo_name/issues) for a full list of proposed features (and known issues).
-->

<p align="right">(<a href="#top">back to top</a>)</p>

## Contributing <a name="contributing"></a>

Collaboration is what makes the world such an amazing place to learn, inspire, and create. **Any contributions or suggestions you make are greatly appreciated!**

Feel free to do any of the following:

- send me an [email](mailto:steven.g.opferman@gmail.com)
- open an issue with the tag "enhancement"
- fork the repo and create a pull request

<p align="right">(<a href="#top">back to top</a>)</p>

## Acknowledgements <a name="acknowledgements"></a>

- The rationale for managing dotfiles this way is explained wonderfully here: <https://www.anishathalye.com/2014/08/03/managing-your-dotfiles/>
- This repo is essentially a wrapper around Dotbot: <https://github.com/anishathalye/dotbot>

<p align="right">(<a href="#top">back to top</a>)</p>
