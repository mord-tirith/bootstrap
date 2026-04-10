# Nvim
The most I worked on this project, Neovim.

For new users, really all you need to know is, "open neovim, make sure the tag on the bottom left says 'Normal' (press Esc if it doesn't and it will), then press the spacebar."

This will bring up the shortcut info tab which will really show you anything you want, need a different color scheme? It's right there. Need to open the file explorator? Search and replace a text line? Include 42 Header? Choose whether programming language diagnostics appear on screen or not? It's all there.

As a treat, by default, "Tutorial Mode" is enabled. This means that, for any of the shortcuts you can access in that menu, once their job is done, you'll see a "You could have done x" message, teaching you the "classic Neovim way" of doing it.

For example, there is no shame in pressing space on Normal mode, then pressing 's' to get to "shortcuts", 's' again for "search shortcuts" and "r" for "search and replace shortcut." Doing so will prompt you to write what word you want gone, then what word you want to take it's place.

_But,_ if tutorial mode is enabled, doing all of that will also let you know: "You could have done: :%s/ORIGINAL_WORD/NEW_WORD" so, if you want to eventually learn to Vim/Nvim without help, you can get your bearings.

Of course, if you aren't interested in the tutorials, you can toggle them off and those commands will return to quietly just telling you "this is what this command did."

## Recommended boot
The first time you load Neovim, I recommend doing a few things for your own convenience.

All of these expect you to be in Normal Mode. If you look at the bottom left and see "Insert" or "Visual" written there, simply press Esc until it reads "Normal."

Also, by `<leader>` I mean the spacebar for newcomers, I prefer to leave it as `<leader>` because advanced users might want to change that for something they prefer.

1 - `:Lazy update`, I try to keep the repo up-to-date on plugin changes but it's always best to run them yourself
2 - `<leader>ns`, this will prompt you to input your 42 username and email so your header is set for good
3 - `<leader>cc`, this will bring you to the Color Theme picker, where you can freely choose which of the themes you like the most. In case you're wondering, the default it goes out with is tokyodark by tiagovla

## Saving settings

There is a plethora of toggle settings you can access with `<leader>sw`, and I wrote this so that these are remembered by Neovim, so if you turn off relative numbers, close and open it again, they will still be gone until you toggle them back on.

Should you ever want to go back to defaults, you can use `<leader>swd`.

You can also save your default preferences inside of bootstrap/config/nvim/lua/config/config_state.lua. Right at the top of the file you'll see a variable called `M.defaults` where you can put stuff like your username, whether you like relative lines or whether you want the Tutorial Mode turned on or off.

Changing those settings there will make it so `<leader>swd` applies your settings instead.

## Notable plugins
- Blink, by saghen
By far the best autocomplete tool I've ever found on Neovim, slightly altered commands in this bootstrap that make it (IMO) easier to type quickly: you can either use arrows to choose an option or use Alt + 0-9 to select that entry.

- Comment, by NumToStr
Easy "make this line a comment/actually make it code again" commands on demand

- 42-header, by Diogo-ss
Best 42 header plugin out there, though I had to create the "save your username and email" logic outside of it, this plugin made it possible to do it to begin with. Users probably wouldn't notice if I had used a different plugin but as the one who wrote the code to make it work behind the scenes with the rest of the project, this one was a life saver

- 42norm, by MoulatiMehdi
This saint has kept an updated norminette error generator. Yes, this does mean that if you have Inline Errors toggled on in your settings, you'll see stuff like "for loops are forbidden" or "line too long" appear the second those mistakes happen!

- which-key, by folke
Shortcut guide tool, if you see yourself using that "Spacebar on Normal mode" trick often? Yeah, that's ALL this plugin

