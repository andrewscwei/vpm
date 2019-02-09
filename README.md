# VARS Project Manager (vpm)

> Switch between projects quickly in the command line

`vpm` is a CLI tool that lets you access paths in your file system with a single command. It is designed to help you switch between repos quickly.

## TL;DR

First you need to teach `vpm` where to look for your projects:

1. From Terminal, `cd` to the directory of a repo.
2. Run `vpm add <project_key>` to add the current directory to the `vpm` registry, where `<project_key>` is the key you wish to use to name this project.

From now on you can just run `vpm cd <project_key>` to navigate to that project directly from Terminal. Better yet, you can run `vpm project <project_key>` (or `vpm p <project_key>` for short) to immediate open it with your default text editor (`vpm` scans for Xcode project files and Android Studio projects first then falls back to VSCode/Sublime/Atom/TextMate respectively, depending on which editor is installed in your system).

## Usage

Install vpm via cURL:

```sh
$ curl -o- https://raw.githubusercontent.com/andrewscwei/vpm/v2.5.0/install.sh | bash
```

## Commands

```sh
Usage: vpm <command>

where <command> is one of:
     add - Maps the current working directory to a project key.
      cd - Changes the current working directory to the working directory of a vpm project.
   clean - Cleans the vpm registry by reconsiling invalid entries.
    edit - Edits the vpm registry file directly in the default text editor (USE WITH CAUTION).
    help - Provides access to additional info regarding specific vpm commands.
    list - Lists all current projects managed by vpm.
 project - Opens a vpm project in designated IDE (supports Xcode/Sublime/Atom in respective priority).
  remove - Removes a vpm project from the vpm registry.
   serve - Serves a vpm project (looks for www/public/dist folder in project root in respective priority).
```

### `vpm add <project_key>`
Maps the current working directory to a project key. If you don't specify a project key, the name of the current working directory will be used.

### `vpm cd <project_key_or_index>`
Changes the working directory to the working directory of a `vpm` project.

### `vpm list`
Lists all current projects managed by `vpm`

### `vpm project <project_key_or_index>`
Opens a `vpm` project in designated IDE (supports Xcode/Sublime in respective priority).

### `vpm remove <project_key_or_index>`
Removes a `vpm` project from the `vpm` registry. If you don't specify a project key or index, the name of the current working directory will be used.

> Whenever you run a command that expects a project key or index, you can optionally leave the key or index blank. The command will then use key that was last used. You can run `vpm cache` to see what the last iterated project is.

> Whenever you run a command that expects a project key or index, you can use `.` to refer to the working directory (`pwd`).

> Most commands have equivalent short notations. For example, instead of doing `vpm project` you can do `vpm p`.

## Example

Suppose you have a project located in `~/projects/sample-project`. With `vpm`, you can enter shell, `cd` to that directory, and add that directory to the `vpm` registry with a key by executing `vpm add sample-project`, `sample-project` being the key.

You can then quickly access that project by:

```sh
# `cd` to sample-project
$ vpm cd sample-project

# Opens sample-project in the default text editor
$ vpm p sample-project
```

With this set up you can add multiple projects to the `vpm` registry and quickly access all of them. You can do `vpm list` to see the existing projects in the registry and simply access each of them by their key or index. For example, if `sample-project` is the 6th project on the list, you can do `vpm cd 6` instead of `vpm cd sample-project`.

## License

This software is released under the [MIT License](http://opensource.org/licenses/MIT).
