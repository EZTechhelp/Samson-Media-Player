Allows adding a comma-seperated list of additional command-line options to pass to LIBVLC when playing media that does not use WebPlayers.

#####__IMPORTANT__
%{color:RED}**FOR ADVANCED USERS ONLY!**% 

Do not use if you do not know what you are doing!

Not all options are guaranteed to work, and some options could break things. Some options are overridden by the player regardless of what is entered here.  

######__INFO__
LIBVLC is the Library or 'Engine' that powers VLC. Many command-line options that work with VLC.exe will likely work for LIBVLC, but not all. It is recommended to set LIBVLC logging to DEBUG (3) when testing or troubleshooting.

**Example**

```diff
--audio-filter=normalizer,--audio-visual=projectm,--projectm-preset-path=c:\MilkDrop\MilkdropPresets
```


For an exhaustive list of available options, visit [VLC command-line help](https://wiki.videolan.org/VLC_command-line_help/)