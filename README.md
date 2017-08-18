# VARS Project Manager (vpm)

A CLI tool that helps manage and open local projects quickly. No more manually navigating to or searching through your file system to find your project.

## How It Works:

1. From Terminal, you `cd` to the directory of a project you are working on.
2. Run `vpm add` to add the current directory to the `vpm` registry. The key is the name of the directory if there is no additional parameter specified. For example, `vpm add foo` will map the current directory to `foo` in the `vpm` registry.

From now on you can just run `vpm cd foo` to navigate to that project directly from Terminal. Better yet, you can run `vpm project foo` or `vpm p foo` for short to immediate open it using either Xcode/VSCode/Sublime/Atom/nano (it scans for Xcode project files first then falls back to VSCode/Sublime/Atom/nano respectively, depending on which editor is installed in your system)!

## Installation

Clone this repo and symlink to `/usr/local/bin` (you may need `sudo` access):

```sh
$ git clone https://github.com/andrewscwei/vpm.git
$ sudo ln -s /path/to/vpm /usr/local/bin
```

Create an alias in your local `.bash_profile` or equivalent so `vpm` can directly execute commands like `cd`:

```sh
# ~/.bash_profile

...

alias vpm=". vpm"
```

## Commands

```sh
Usage: vpm <command>

where <command> is one of:
     add - Maps the current working directory to a project key.
      cd - Changes the current working directory to the working directory of a vpm project.
   clean - Cleans the vpm registry by reconsiling invalid entries.
    edit - Edits the vpm tool directly in the default text editor (USE WITH CAUTION).
    help - Provides access to additional info regarding specific vpm commands.
    list - Lists all current projects managed by vpm.
  manage - Edits the vpm registry file directly in the default text editor (USE WITH CAUTION).
    open - Opens the working directory of a vpm project in Finder.
 project - Opens a vpm project in designated IDE (supports Xcode/Sublime/Atom in respective priority).
  remove - Removes a vpm project from the vpm registry.
 version - Shows the version of vpm.
```

### `vpm add <project_alias>`
Maps the current working directory to a project key. If you don't specify a project key, the name of the current working directory will be used.

### `vpm cd <project_alias_or_index>`
Changes the working directory to the working directory of a `vpm` project.

### `vpm list`
Lists all current projects managed by `vpm`

### `vpm open <project_alias_or_index` 
Opens the working directory of a `vpm` project in Finder.

### `vpm project <project_alias_or_index` 
Opens a `vpm` project in designated IDE (supports Xcode/Sublime in respective priority).

### `vpm remove <project_alias_or_index>`
Removes a `vpm` project from the `vpm` registry. If you don't specify a project key or index, the name of the current working directory will be used.

### `vpm <command>`
When no project key or index is specified, the last iterated project will be used to perform the `<command`>. You can use `vpm cache` to see what the last iterated project is. Not all commands support this notation.

### `vpm <command> .`
Performs the `<command>` on the hashed project whose path equates the current directory (`pwd`). 

### `vpm help` 
...or simply `vpm` for a full list of commands with details.

> Most commands have equivalent short notations. For example, instead of doing `vpm project` you can do `vpm p`.

> If you previously executed a command on a valid key, it stays in cache. You can then access it using `.`. i.e. `vpm p .`.  To view which key is cached, do `vpm cache`.

## Example

Suppose you have a project located in `~/projects/SampleProject`. With `vpm`, you can enter shell, `cd` to that directory, and hash that directory to the `vpm` registry with a key by executing `vpm add SampleProject`, `SampleProject` being the key.

You can then quickly access that project by:

```sh
# Opens SampleProject in Finder
$ vpm open SampleProject

# Opens SampleProject in the appropriate text editor in the following priority: Xcode, VSCode, Sublime, Atom, nano
$ vpm project SampleProject
```

With this set up you can add multiple projects to the `vpm` registry and quickly access all of them. You can do `vpm list` to see the existing projects in the registry and simply access each of them by their key or index. For example, if `SampleProject` is the 6th project on the list, you can do `vpm open 6` to open it in Finder.

## License

This software is released under the [MIT License](http://opensource.org/licenses/MIT).
