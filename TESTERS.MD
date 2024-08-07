## Notes for QA/Testers

- Those willing to be testers will get access to private QA builds that include extra features and development APIs. So Spotify, YouTube and Twitch features all work without needing to set up your own APIs. (Still have to provide your own credentials for those services of course)
- An in-app Feedback/Bug submission system is included for QA builds, so you can easily/quickly provide logs and/or submit troubleshooting information directly from the app. Supports attaching files such as screenshots..etc
- QA Testers will have access to a private Trello board used for development collaboration which also includes access to the latest test builds as they are compiled/uploaded
- The default **logging verbosity** is high for development reasons, which can cause the log files to grow in size quickly in some cases, so heads up.
  - The log files are located at `%appdata%\roaming\Samson\Logs`
  - Basic computer info such as name, make, model, CPU, RAM, Windows version..etc are included in the log file
  - Log file may also contain details of media you provide, names of playlists, songs..etc. 
  - If DEV mode is enabled (is not by default), additional data may include OAuth tokens and other API credential data, but never passwords
  - If you are concerned about what info you share with the logs, recommend reviewing the log files and scrubbing anything before sharing for support/testing, or just don't submit them. No logs are shared automatically
- By default, Playlist and Media profiles are stored in `%appdata%\roaming\Samson`
  - **Temp files for Webview2 controls** (cookies..etc) and any processed/downloaded images are saved into the **%temp%\Samson** folder. These can be deleted anytime, though any external images will need to be downloaded and cached again. These are usually for profile images or media art..etc
- Core app settings are also stored in `%appdata%\Roaming\Samson`. There is an **XML config file** that holds most of the primary settings for the app
- Any **Custom EQ Presets** created are stored in the **EQPresets** sub-folder of the same directory as the config file