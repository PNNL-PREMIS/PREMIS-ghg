# longterm_dat

This folder holds data downloaded from the continuous LI-8100 ("Stuart").

The data files can get quite large (for example, `SALT_20181207_LT.81x` downloaded 24 January 2019 was 230 MB!). Because GitHub limits file sizes, we first split large files on the command line, e.g.:
```
split -l 100000 SALT_20181207_LT.81x SALT_20181207_LT.81x_SPLIT_ 
```
This splits the file into 100,000 line sub-files, which are then put together in a folder.

The data-reading code looks for these files with "SPLIT" in their names, and reads and concatenates them before parsing.
