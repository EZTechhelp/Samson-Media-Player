**Enables use of the subtitle controls within the Video Viewer. Also allows ability to 'Auto-Fetch' subtitles, which attempts to lookup and download subtitles for the current playing media** 

 ![Subtitles]([CURRENTFOLDER]/Resources/Docs/Images/Subtitles_Control.png)

#####__IMPORTANT__

%{color:#FFFFD265} ❗% This feature is in experimental testing. Subtitle lookups (via Auto-Fetch) are currently limited to 10 per day while API is in testing

%{color:#FFFFD265} ❗% Auto-Fetch accuracy and proper subtitle timing will vary greatly depending on video and cannot be guaranteed. 

%{color:#FFFFD265} ❗% Embedded subtitles are used first if available, then SRT files are used. SRT files must be in the same directory and must have the same name as the video file name

+ Example -- Video file: D:\Videos\My Movie.mkv -- Valid Subtitle file: D:\Videos\My Movie.srt

%{color:#FFFFD265} ❗% Increase/Decrease delay buttons can be used to attempt to fix subtitles that are out of sync with video. 

+ This can help for subtitles that are slighly out of sync, but usually this means the subtitles are not correct for the video

######__INFO__

%{color:cyan}❓% Auto-Fetch uses [Open Subtitles](https://www.opensubtitles.org) API to attempt query and download of SRTs


