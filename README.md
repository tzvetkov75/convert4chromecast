# convert4chromecast

converts video files (or hole directory) to be playable at chormecast 1/2

conversion is made minimalistic, thus only if needed,copy if possible, minimal quality decrease 

## Usage 

Usage: convert4chromecast.sh <videofile|directory> [ videofile|directory ... ]

## Details 

This is bash script that requires **ffmpeg** install on your linux 

The script loops over list of files or all files in directory 
* if the file format, audio or video codec is not supported on chromecast the it converts the file in most optimal way 
* after the converision the original file is renamed to *.original*. The new file contains the word chromecast 
* if the file is supported than it is skipped and msg displayed  

Enjoy!

