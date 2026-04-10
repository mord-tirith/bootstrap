# binary files
These are pet scripts I've been working on since starting at 42.

## log_all
log_all is mostly an AI-debug conveniency tool: it allows you to instantly generate a temporary file with the dumped text content of all files within the current directory.

In it's current version, log_all also supports a variety of flags for more conveniency, like -d|--maxdepth so you can choose how many subdirectories the search will go into or -s|--save so you can leave the tool aware of what files you last searched for.

It also supports somewhat smart filetype arguments, if you run `log_all c -d 4 -s` the tool will only include .c and .h files in its search, it will search for up to 4 directories deep from PWD and, after doing all that, will save those settings so next time you use it you could just run `log_all` and get the same results.

## locate
Unlike log_all, locate is honestly just an absurd overkill of what could easily be a simple alias but oh well.

It hunts for the given text(s) string(s) on files on the current directory. Like log_all, it can also receive -d to inform of how deep said search is allowed to go, as well as -c|--case for whether or not your search is case sensitive and -p|--partial in case you give multiple strings and want to know even if a file doesn't have all of them
