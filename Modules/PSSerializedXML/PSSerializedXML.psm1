<#
    .Name
    PSSerializedXML

    .Version 
    0.1.0

    .SYNOPSIS
    Converts list of objects to or from serialized XML files

    .DESCRIPTION
    Export-SerializedXML converts provided list of objects into custom type Media to be saved to serialized XML file.
    Import-SerializedXML reads and deserializes XML file back into a list of Objects of type Media

    .Requirements
    - Powershell v3.0 or higher

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES
#>

#----------------------------------------------
#region Add-Type Media
#----------------------------------------------
if(-not [bool]('Media' -as [Type])){ #Checks if type is already loaded. Will occur when module is imported
  Add-Type @"
using System;
using System.Windows;
using System.Collections;
using System.Collections.Specialized;
using System.Collections.Generic;
using System.ComponentModel;
using System.Xml.Serialization;
using System.Xml;
[XmlRoot("dictionary")]
public class SerializableDictionary<TKey, TValue>
    : Dictionary<TKey, TValue>, IXmlSerializable, INotifyCollectionChanged, INotifyPropertyChanged
{
    public event NotifyCollectionChangedEventHandler CollectionChanged;
    public event PropertyChangedEventHandler PropertyChanged;
    protected void OnCollectionChanged(NotifyCollectionChangedEventArgs e)
    {
        // Use BlockReentrancy
            var eventHandler = CollectionChanged;
            if (eventHandler == null) return;

            // Only proceed if handler exists.
            Delegate[] delegates = eventHandler.GetInvocationList();

            // Walk through invocation list.
            foreach (var @delegate in delegates)
            {
                var handler = (NotifyCollectionChangedEventHandler)@delegate;
                var currentDispatcher = handler.Target as DispatcherObject;

                // If the subscriber is a DispatcherObject and different thread.
                if ((currentDispatcher != null) && (!currentDispatcher.CheckAccess()))
                {
                    // Invoke handler in the target dispatcher's thread.
                    currentDispatcher.Dispatcher.Invoke(
                        DispatcherPriority.DataBind, handler, this, e);
                }


                else
                {
                    // Execute as-is
                    handler(this, e);
                }
            }
    }
    public new void Add(TKey key, TValue value)
    {
        base.Add(key, value);
        OnCollectionChanged(new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Add, value));
    }
    public new void Remove(TKey key)
    {
        TValue value;
        if (base.TryGetValue(key, out value))
        {
            base.Remove(key);
            OnCollectionChanged(new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Remove, value));
        }
    }
    public new void Clear()
    {
        if (Count > 0)
        {
            base.Clear();
            OnCollectionChanged(new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Reset));
        }
    }
    public SerializableDictionary() { }
    public SerializableDictionary(IDictionary<TKey, TValue> dictionary) : base(dictionary) { }
    public SerializableDictionary(IDictionary<TKey, TValue> dictionary, IEqualityComparer<TKey> comparer) : base(dictionary, comparer) { }
    public SerializableDictionary(IEqualityComparer<TKey> comparer) : base(comparer) { }
    public SerializableDictionary(int capacity) : base(capacity) { }
    public SerializableDictionary(int capacity, IEqualityComparer<TKey> comparer) : base(capacity, comparer) { }

    #region IXmlSerializable Members
    public System.Xml.Schema.XmlSchema GetSchema()
    {
        return null;
    }

    public void ReadXml(System.Xml.XmlReader reader)
    {
        XmlSerializer keySerializer = new XmlSerializer(typeof(TKey));
        XmlSerializer valueSerializer = new XmlSerializer(typeof(TValue));

        bool wasEmpty = reader.IsEmptyElement;
        reader.Read();

        if (wasEmpty)
            return;

        while (reader.NodeType != System.Xml.XmlNodeType.EndElement)
        {
            reader.ReadStartElement("item");

            reader.ReadStartElement("key");
            TKey key = (TKey)keySerializer.Deserialize(reader);
            reader.ReadEndElement();

            reader.ReadStartElement("value");
            TValue value = (TValue)valueSerializer.Deserialize(reader);
            reader.ReadEndElement();

            this.Add(key, value);

            reader.ReadEndElement();
            reader.MoveToContent();
        }
        reader.ReadEndElement();
    }

    public void WriteXml(System.Xml.XmlWriter writer)
    {
        XmlSerializer keySerializer = new XmlSerializer(typeof(TKey));
        XmlSerializer valueSerializer = new XmlSerializer(typeof(TValue));

        foreach (TKey key in this.Keys)
        {
            writer.WriteStartElement("item");

            writer.WriteStartElement("key");
            keySerializer.Serialize(writer, key);
            writer.WriteEndElement();

            writer.WriteStartElement("value");
            TValue value = this[key];
            valueSerializer.Serialize(writer, value);
            writer.WriteEndElement();

            writer.WriteEndElement();
        }
    }
    #endregion
}

public class Media : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler PropertyChanged;

    public void RaisedOnPropertyChanged(string propertyName)
    {
        var handler = PropertyChanged;
        if (handler != null)
        {
            var e = new PropertyChangedEventArgs(propertyName);
            foreach (PropertyChangedEventHandler h in handler.GetInvocationList())
            {
                var synch = h.Target as ISynchronizeInvoke;
                if (synch != null && synch.InvokeRequired)
                    synch.Invoke(h, new object[] { this, e });
                else
                    h(this, e);
            }
        }
    }
    public string id { get; set; }
    public string User_id { get; set; }
    public string Spotify_id { get; set; }
    public string Artist { get; set; }
    public string Artist_ID { get; set; }
    public string Album { get; set; }
    public string Album_id { get; set; }
    public string title { get; set; }
    public string Name { get; set; }
    public string Playlist { get; set; }
    public string playlist_id { get; set; }
    public string playlist_item_id { get; set; }
    public string Playlist_url { get; set; }
    public string Channel_Name { get; set; }
    public string Channel_ID { get; set; }
    public string description { get; set; }
    public string Live_Status { get; set; }
    public string Stream_title { get; set; }
    private string number;
    public string Number
    {
        get
        {
            return number;
        }
        set
        {
            number = value;
            RaisedOnPropertyChanged("Number");
        }
    }
    private string statusmsg;
    public string Status_Msg
    {
        get
        {
            return statusmsg;
        }
        set
        {
            statusmsg = value;
            RaisedOnPropertyChanged("Status_Msg");
        }
    }
    private string status;
    public string Status
    {
        get
        {
            return status;
        }
        set
        {
            status = value;
            RaisedOnPropertyChanged("Status");
        }
    }
    public int Viewer_Count { get; set; }
    public string Image { get; set; }
    private string fontstyle;
    public string FontStyle
    {
        get
        {
            return fontstyle;
        }
        set
        {
            fontstyle = value;
            RaisedOnPropertyChanged("FontStyle");
        }
    }
    private string fontcolor;
    public string FontColor
    {
        get
        {
            return fontcolor;
        }
        set
        {
            fontcolor = value;
            RaisedOnPropertyChanged("FontColor");
        }
    }
    private string fontweight;
    public string FontWeight
    {
        get
        {
            return fontweight;
        }
        set
        {
            fontweight = value;
            RaisedOnPropertyChanged("FontWeight");
        }
    }
    private string fontsize;
    public string FontSize
    {
        get
        {
            return fontsize;
        }
        set
        {
            fontsize = value;
            RaisedOnPropertyChanged("FontSize");
        }
    }
    public string Margin { get; set; }
    private string tooltip;
    public string ToolTip
    {
        get
        {
            return tooltip;
        }
        set
        {
            tooltip = value;
            RaisedOnPropertyChanged("ToolTip");
        }
    }
    private string statusfontStyle;
    public string Status_FontStyle
    {
        get
        {
            return statusfontStyle;
        }
        set
        {
            statusfontStyle = value;
            RaisedOnPropertyChanged("Status_FontStyle");
        }
    }
    private string statusfontcolor;
    public string Status_FontColor
    {
        get
        {
            return statusfontcolor;
        }
        set
        {
            statusfontcolor = value;
            RaisedOnPropertyChanged("Status_FontColor");
        }
    }
    private string statusfontweight;
    public string Status_FontWeight
    {
        get
        {
            return statusfontweight;
        }
        set
        {
            statusfontweight = value;
            RaisedOnPropertyChanged("Status_FontWeight");
        }
    }
    private string statusfontsize;
    public string Status_FontSize
    {
        get
        {
            return statusfontsize;
        }
        set
        {
            statusfontsize = value;
            RaisedOnPropertyChanged("Status_FontSize");
        }
    }
    private string borderbrush;
    public string BorderBrush
    {
        get
        {
            return borderbrush;
        }
        set
        {
            borderbrush = value;
            RaisedOnPropertyChanged("BorderBrush");
        }
    }
    private string borderthickness;
    public string BorderThickness
    {
        get
        {
            return borderthickness;
        }
        set
        {
            borderthickness = value;
            RaisedOnPropertyChanged("BorderThickness");
        }
    }
    private string numbervisibility;
    public string NumberVisibility
    {
        get
        {
            return numbervisibility;
        }
        set
        {
            numbervisibility = value;
            RaisedOnPropertyChanged("NumberVisibility");
        }
    }
    private string numberfontsize;
    public string NumberFontSize
    {
        get
        {
            return numberfontsize;
        }
        set
        {
            numberfontsize = value;
            RaisedOnPropertyChanged("NumberFontSize");
        }
    }
    public bool AllowDrop { get; set; }
    public bool IsExpanded { get; set; }
    public string directory { get; set; }
    public string SourceDirectory { get; set; }
    public bool PictureData { get; set; }
    public string thumbnail { get; set; }
    public string cached_image_path { get; set; }
    public string Profile_Image_Url { get; set; }
    public string Offline_Image_Url { get; set; }
    public string Bitrate { get; set; }
    public string Chat_Url { get; set; }
    public bool Enable_LiveAlert { get; set; }
    public string Source { get; set; }
    public string Followed { get; set; }
    public string Profile_Date_Added { get; set; }
    public string url { get; set; }
    public string type { get; set; }
    public bool hasVideo { get; set; }
    public string Current_Progress_Secs { get; set; }
    public int Track { get; set; }
    private string duration;
    public string Duration
    {
        get
        {
            return duration;
        }
        set
        {
            duration = value;
            RaisedOnPropertyChanged("Duration");
        }
    }
    public string Size { get; set; }
    public string Subtitles_Path { get; set; }
    private string displayname;
    public string Display_Name
    {
        get
        {
            return displayname;
        }
        set
        {
            displayname = value;
            RaisedOnPropertyChanged("Display_Name");
        }
    }
    public int TimesPlayed { get; set; }
}

public class EQ_Band
{
    public float Band { get; set; }
    public int Band_ID { get; set; }
    public string Band_Name { get; set; }
    public double Band_Value { get; set; }
}

public class EQ_Preset
{
    public int Preset_ID { get; set; }
    public string Preset_Name { get; set; }
}

public class Custom_EQ_Preset
{
    public string Preset_ID { get; set; }
    public string Preset_Name { get; set; }
    public double EQ_Preamp { get; set; }
    public List<EQ_Band> EQ_Bands { get; set; }
    public string Preset_Path { get; set; }
}

public class Twitch_Playlist
{
    public string ID { get; set; }
    public int Number { get; set; }
    public string Name { get; set; }
    public string Path { get; set; }
    public string Type { get; set; }
    public string Followed { get; set; }
    public bool Enable_LiveAlert { get; set; }
}

public class Cookie
{
    public string Name { get; set; }
    public string cookiedurldomain { get; set; }
    public string Value { get; set; }
    public bool isSecure { get; set; }
}

public class WebExtension
{
    public string Name { get; set; }
    public string ID { get; set; }
    public bool IsEnabled { get; set; }
    public string Icon { get; set; }
    public string path { get; set; }
}
public class ColorTheme
{
    public string Name { get; set; }
    public string Menu_item { get; set; }
    public string PrimaryAccentColor { get; set; }
}

public class GlobalHotKey
{
    public string Name { get; set; }
    public string Modifier { get; set; }
    public string Key { get; set; }
}

public class Config
{
    public string Media_Profile_Directory { get; set; }
    public string Bookmarks_Profile_Directory { get; set; }
    public bool Use_Profile_Cache { get; set; }
    public string Log_Level { get; set; }
    public string Streamlink_HTTP_Port { get; set; }
    public string TwitchMedia_Log_File { get; set; }
    public string YoutubeMedia_Log_File { get; set; }
    public string SpotifyMedia_Log_File { get; set; }
    public string Launcher_Log_File { get; set; }
    public string VLC_Arguments { get; set; }
    public bool Auto_UpdateInstall { get; set; }
    public bool LocalMedia_FastImporting { get; set; }
    public bool Enablelinkedconnections { get; set; }
    public bool Found_Hell { get; set; }
    public bool Profile_Write_IDTags { get; set; }
    public bool Mute_Twitch_Ads { get; set; }
    public bool Always_On_Top { get; set; }
    public bool Verbose_logging { get; set; }
    public bool Toggle_FullScreen { get; set; }
    public bool PlayLink_OnDrop { get; set; }
    public bool SplashScreenAudio { get; set; }
    public bool Enable_Marquee { get; set; }
    public bool ForceUse_YTDLP { get; set; }
    public double Media_Volume { get; set; }
    public string Spotify_SP_DC { get; set; }
    public string Youtube_1PSID { get; set; }
    public string Youtube_1PAPISID { get; set; }
    public string Youtube_3PAPISID { get; set; }
    public string Chat_WebView2_Cookie { get; set; }
    public string Twitch_auth_Cookie { get; set; }
    public ArrayList Local_Group_By { get; set; }
    public ArrayList Spotify_Group_By { get; set; }
    public ArrayList Youtube_Group_By { get; set; }
    public ArrayList Twitch_Group_By { get; set; }
    public int SpotifyBrowser_Paging { get; set; }
    public int YoutubeBrowser_Paging { get; set; }
    public int MediaBrowser_Paging { get; set; }
    public int TwitchBrowser_Paging { get; set; }
    public ArrayList Media_Directories { get; set; }
    public List<Custom_EQ_Preset> Custom_EQ_Presets { get; set; }
    public ArrayList Spotify_Playlists { get; set; }
    public ArrayList Youtube_Playlists { get; set; }
    public SerializableDictionary<int, string> Current_Playlist { get; set; }
    public SerializableDictionary<int, string> History_Playlist { get; set; }
    public string Snapshots_Path { get; set; }
    public string LocalMedia_ImportMode { get; set; }
    public bool Use_Twitch_TTVLOL { get; set; }
    public bool Use_Twitch_luminous { get; set; }
    public string Streamlink_Arguments { get; set; }
    public bool Minimize_To_Tray { get; set; }
    public bool Disable_Tray { get; set; }
    public string LocalMedia_MonitorMode { get; set; }
    public string App_UniqueID { get; set; }
    public string Twitch_Quality { get; set; }
    public List<Cookie> Youtube_Cookies { get; set; }
    public bool Verbose_perf_measure { get; set; }
    public bool PODE_SERVER_ACTIVE { get; set; }
    public bool YoutubeMedia_Library_CollapseAllGroups { get; set; }
    public ArrayList YoutubeMedia_Library_Columns { get; set; }
    public ArrayList TwitchMedia_Library_Columns { get; set; }
    public bool IsRead_AboutFirstRun { get; set; }
    public bool IsRead_SpecialFirstRun { get; set; }
    public bool IsRead_TestFeatures { get; set; }
    public bool SpotifyMedia_Library_CollapseAllGroups { get; set; }
    public bool TwitchMedia_Library_CollapseAllGroups { get; set; }
    public bool Use_Preferred_VPN { get; set; }
    public string Preferred_VPN { get; set; }
    public bool Show_Notifications { get; set; }
    public List<WebExtension> Webview2_Extensions { get; set; }
    public bool Use_invidious { get; set; }
    public string Audio_OutputModule { get; set; }
    public bool Notification_Audio { get; set; }
    public ArrayList LocalMedia_Library_Columns { get; set; }
    public ColorTheme Current_Theme { get; set; }
    public bool Enable_EQ2Pass { get; set; }
    public List<Twitch_Playlist> Twitch_Playlists { get; set; }
    public ArrayList TwitchProxies { get; set; }
    public bool UseTwitchCustom { get; set; }
    public bool Remember_Window_Positions { get; set; }
    public bool Mini_Always_On_Top { get; set; }
    public bool Start_Tray_only { get; set; }
    public bool Start_Mini_only { get; set; }
    public bool LocalMedia_Library_CollapseAllGroups { get; set; }
    public bool Shuffle_Playback { get; set; }
    public bool Enable_AudioMonitor { get; set; }
    public bool Auto_UpdateCheck { get; set; }
    public string Last_SpeakerLeft_Image { get; set; }
    public string Vlc_Verbose_logging { get; set; }
    public ArrayList SpotifyMedia_Library_Columns { get; set; }
    public bool Auto_Playback { get; set; }
    public bool Auto_Repeat { get; set; }
    public bool Enable_EQ { get; set; }
    public bool ShowTitleBar { get; set; }
    public string Last_Splash_Image { get; set; }
    public string EQ_Selected_Preset { get; set; }
    public string Libvlc_Version { get; set; }
    public string Current_Audio_Output { get; set; }
    public bool Enable_YoutubeComments { get; set; }
    public bool Enable_Subtitles { get; set; }
    public string LocalMedia_Display_Syntax { get; set; }
    public bool Chat_View { get; set; }
    public bool Video_Snapshots { get; set; }
    public bool App_Snapshots { get; set; }
    public bool Enable_Performance_Mode { get; set; }
    public bool Use_HardwareAcceleration { get; set; }
    public bool Enable_WebEQSupport { get; set; }
    public bool Open_VideoPlayer { get; set; }
    public bool Remember_Playback_Progress { get; set; }
    public bool Start_Paused { get; set; }
    public string Current_Visualization { get; set; }
    public bool Use_Visualizations { get; set; }
    public bool Use_MediaCasting { get; set; }
    public bool LocalMedia_SkipDuplicates { get; set; }
    public bool Enable_LocalMedia_Monitor { get; set; }
    public bool Spotify_WebPlayer { get; set; }
    public bool Spotify_Update { get; set; }
    public string Spotify_Update_Interval { get; set; }
    public bool Youtube_WebPlayer { get; set; }
    public string Youtube_Update_Interval { get; set; }
    public bool Enable_Sponsorblock { get; set; }
    public string Youtube_Quality { get; set; }
    public bool Import_My_Youtube_Media { get; set; }
    public string Twitch_Update_Interval { get; set; }
    public bool Enable_Twitch_Notifications { get; set; }
    public bool Skip_Twitch_Ads { get; set; }
    public string Streamlink_Interface { get; set; }
    public string Streamlink_Verbose_logging { get; set; }
    public bool Twitch_Update { get; set; }
    public bool Start_On_Windows_Login { get; set; }
    public bool Import_Local_Media { get; set; }
    public bool Import_Youtube_Media { get; set; }
    public string Youtube_Browser { get; set; }
    public bool Youtube_Update { get; set; }
    public string Youtube_Download_Path { get; set; }
    public string Sponsorblock_ActionType { get; set; }
    public bool Import_Twitch_Media { get; set; }
    public bool Use_Spicetify { get; set; }
    public bool Import_Spotify_Media { get; set; }
    public bool Install_Spotify { get; set; }
    public bool Import_Youtube_Browser_Auth { get; set; }
    public bool Discord_Integration { get; set; }
    public bool Media_Muted { get; set; }
    public string Current_Playing_Media { get; set; }
    public string Last_Played { get; set; }
    public double EQ_Preamp { get; set; }
    public string Libvlc_Global_Gain { get; set; }
    public string Log_file { get; set; }
    public string Config_Path { get; set; }
    public string Playlists_Profile_Path { get; set; }
    public string Current_Folder { get; set; }
    public string image_Cache_path { get; set; }
    public string App_Name { get; set; }
    public string Templates_Directory { get; set; }
    public string Playlist_Profile_Directory { get; set; }
    public string EQPreset_Profile_Directory { get; set; }
    public string VLC_Log_File { get; set; }
    public string LibVLC_Log_File { get; set; }
    public string Streamlink_Log_File { get; set; }
    public string Startup_Log_File { get; set; }
    public string Error_Log_File { get; set; }
    public string LocalMedia_Log_File { get; set; }
    public string Discord_Log_File { get; set; }
    public string Perf_Log_File { get; set; }
    public string Webview2_Log_File { get; set; }
    public string Setup_Log_File { get; set; }
    public string Threading_Log_File { get; set; }
    public string Uninstall_Log_File { get; set; }
    public string Friends_Profile_Directory { get; set; }
    public string App_Version { get; set; }
    public string App_Exe_Path { get; set; }
    public string App_Build { get; set; }
    public string logfile_directory { get; set; }
    public string SpotifyMedia_logfile { get; set; }
    public string YoutubeMedia_logfile { get; set; }
    public string TwitchMedia_logfile { get; set; }
    public string Tor_Log_File { get; set; }
    public string Download_logfile { get; set; }
    public bool Startup_perf_timer { get; set; }
    public string Temp_Folder { get; set; }
    public bool Dev_mode { get; set; }
    public bool Debug_mode { get; set; }
    public double Splash_Top { get; set; }
    public double Splash_Left { get; set; }
    public List<EQ_Preset> EQ_Presets { get; set; }
    public List<EQ_Band> EQ_Bands { get; set; }
    public string Installed_AppID { get; set; }
    public double MainWindow_Top { get; set; }
    public double MainWindow_Left { get; set; }
    public double MiniWindow_Top { get; set; }
    public double MiniWindow_Left { get; set; }   
    public double VideoWindow_Top { get; set; }
    public double VideoWindow_Left { get; set; }
    public double LibraryWindow_Top { get; set; }
    public double LibraryWindow_Left { get; set; }
    public double BrowserWindow_Top { get; set; }
    public double BrowserWindow_Left { get; set; }
    public List<GlobalHotKey> GlobalHotKeys { get; set; }
    public bool EnableGlobalHotKeys { get; set; }
    public bool Enable_HighDPI { get; set; }
}
public class API
{
    public string Provider { get; set; }
    public string Redirect_URLs { get; set; }
    public string Auth_URLs { get; set; }
    public string ClientSecret { get; set; }
    public string ClientID { get; set; }
    public string ClientToken { get; set; }
}

public class Playlist : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler PropertyChanged;

    public void RaisedOnPropertyChanged(string propertyName)
    {
        var handler = PropertyChanged;
        if (handler != null)
        {
            var e = new PropertyChangedEventArgs(propertyName);
            foreach (PropertyChangedEventHandler h in handler.GetInvocationList())
            {
                var synch = h.Target as ISynchronizeInvoke;
                if (synch != null && synch.InvokeRequired)
                    synch.Invoke(h, new object[] { this, e });
                else
                    h(this, e);
            }
        }
    }


    public string Name { get; set; }
    public string Playlist_name { get; set; }
    private int number;
    public int Number
    {
        get
        {
            return number;
        }
        set
        {
            number = value;
            RaisedOnPropertyChanged("Number");
        }
    }
    public string Title { get; set; }
    private string displayname;
    public string Display_Name
    {
        get
        {
            return displayname;
        }
        set
        {
            displayname = value;
            RaisedOnPropertyChanged("Display_Name");
        }
    }
    private string statusmsg;
    public string Status_Msg
    {
        get
        {
            return statusmsg;
        }
        set
        {
            statusmsg = value;
            RaisedOnPropertyChanged("Status_Msg");
        }
    }
    private string status;
    public string Status
    {
        get
        {
            return status;
        }
        set
        {
            status = value;
            RaisedOnPropertyChanged("Status");
        }
    }
    public string Playlist_ID { get; set; }
    public string Description { get; set; }
    public string Playlist_Path { get; set; }
    public string Playlist_URL { get; set; }
    public SerializableDictionary<int, Media> Playlist_Tracks { get; set; }
    public string Source { get; set; }
    public string Image { get; set; }
    private string fontstyle;
    public string FontStyle
    {
        get
        {
            return fontstyle;
        }
        set
        {
            fontstyle = value;
            RaisedOnPropertyChanged("FontStyle");
        }
    }
    private string fontcolor;
    public string FontColor
    {
        get
        {
            return fontcolor;
        }
        set
        {
            fontcolor = value;
            RaisedOnPropertyChanged("FontColor");
        }
    }
    private string fontweight;
    public string FontWeight
    {
        get
        {
            return fontweight;
        }
        set
        {
            fontweight = value;
            RaisedOnPropertyChanged("FontWeight");
        }
    }
    private string fontsize;
    public string FontSize
    {
        get
        {
            return fontsize;
        }
        set
        {
            fontsize = value;
            RaisedOnPropertyChanged("FontSize");
        }
    }
    public string Margin { get; set; }
    private string tooltip;
    public string ToolTip
    {
        get
        {
            return tooltip;
        }
        set
        {
            tooltip = value;
            RaisedOnPropertyChanged("ToolTip");
        }
    }
    private string statusfontStyle;
    public string Status_FontStyle
    {
        get
        {
            return statusfontStyle;
        }
        set
        {
            statusfontStyle = value;
            RaisedOnPropertyChanged("Status_FontStyle");
        }
    }
    private string statusfontcolor;
    public string Status_FontColor
    {
        get
        {
            return statusfontcolor;
        }
        set
        {
            statusfontcolor = value;
            RaisedOnPropertyChanged("Status_FontColor");
        }
    }
    private string statusfontweight;
    public string Status_FontWeight
    {
        get
        {
            return statusfontweight;
        }
        set
        {
            statusfontweight = value;
            RaisedOnPropertyChanged("Status_FontWeight");
        }
    }
    private string statusfontsize;
    public string Status_FontSize
    {
        get
        {
            return statusfontsize;
        }
        set
        {
            statusfontsize = value;
            RaisedOnPropertyChanged("Status_FontSize");
        }
    }
    private string borderbrush;
    public string BorderBrush
    {
        get
        {
            return borderbrush;
        }
        set
        {
            borderbrush = value;
            RaisedOnPropertyChanged("BorderBrush");
        }
    }
    private string borderthickness;
    public string BorderThickness
    {
        get
        {
            return borderthickness;
        }
        set
        {
            borderthickness = value;
            RaisedOnPropertyChanged("BorderThickness");
        }
    }
    private string numbervisibility;
    public string NumberVisibility
    {
        get
        {
            return numbervisibility;
        }
        set
        {
            numbervisibility = value;
            RaisedOnPropertyChanged("NumberVisibility");
        }
    }
    private string numberfontsize;
    public string NumberFontSize
    {
        get
        {
            return numberfontsize;
        }
        set
        {
            numberfontsize = value;
            RaisedOnPropertyChanged("NumberFontSize");
        }
    }
    public bool AllowDrop { get; set; }
    public string Type { get; set; }
    public bool Enable_LiveAlert { get; set; }
    public string Playlist_Date_Added { get; set; }
    private bool isexpanded;
    public bool IsExpanded
    {
        get
        {
            return isexpanded;
        }
        set
        {
            isexpanded = value;
            RaisedOnPropertyChanged("IsExpanded");
        }
    }
}
"@ -ReferencedAssemblies ("System.Xml.Serialization", "System.Collections","System.Xml","System.Windows","System.Xml.XmlSerializer","System.Xml.ReaderWriter")
}
#----------------------------------------------
#region Add-Type Media
#----------------------------------------------

#---------------------------------------------- 
#region ConvertTo-Media
#----------------------------------------------
function ConvertTo-Media {
  <#
      .Name
      ConvertTo-Media

      .SYNOPSIS
      Converts provided objects into a list of custom type 'Media'

      .OUTPUTS
      System.Collections.Generic.List<Media>
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory, ValueFromPipeline)]
    $InputObject,
    [switch]$List,
    [switch]$Force
  )
  begin {
    if(($List -or $InputObject -is [System.Collections.Generic.list[Media]] -or $InputObject -is [System.Collections.Generic.list[Object]] -or $InputObject -is [Array])){
      $List = $true
      $OutputObject = [System.Collections.Generic.list[Media]]::new()
    }
  } #close begin block

  process {
    try{
      foreach($object in $InputObject){
        if($Force -or $object -isnot [Media]){
          switch ($object.Source) {
            'Local'{
              $mediaObject = [Media]@{
                'Id' = $object.id
                'Artist' = $object.Artist
                'Album' = $object.Album
                'Title' = $object.Title
                'directory' = $object.directory
                'SourceDirectory' = $object.SourceDirectory
                'PictureData' = $object.PictureData
                'Bitrate' = $object.Bitrate
                'Source' = $object.Source
                'Profile_Date_Added' = $object.Profile_Date_Added
                'url' = $object.url
                'type' = $object.type
                'hasVideo' = $object.hasVideo
                'Current_Progress_Secs' = $object.Current_Progress_Secs
                'Track' = $object.Track
                'Duration' = $object.Duration
                'Size' = $object.Size
                'Subtitles_Path' = $object.Subtitles_Path
                'Display_Name' = $object.Display_Name
              }
            } 'Spotify' {
              $mediaObject = [Media]@{
                'Id' = $object.id
                'Spotify_ID' = $object.Spotify_id
                'Artist' = $object.Artist
                'Artist_ID' = $object.Artist_ID
                'Album' = $object.Album
                'Album_ID' = $object.Album_id
                'Title' = $object.Title
                'Playlist' = $object.Playlist
                'Playlist_id' = $object.Playlist_id
                'Playlist_url' = $object.Playlist_url
                'Description' = $object.Description
                'Cached_Image_Path' = $object.Cached_Image_Path
                'Source' = $object.Source
                'Profile_Date_Added' = $object.Profile_Date_Added
                'url' = $object.url
                'type' = $object.type
                'Track' = $object.Track
                'Duration' = $object.Duration
                'Display_Name' = $object.Display_Name
              }
            } {@('Youtube','YoutubeChannel') -contains $_} {
              $mediaObject = [Media]@{
                'Id' = $object.id
                'Artist' = $object.Artist
                'Album' = $object.Album
                'Title' = $object.Title
                'Playlist' = $object.Playlist
                'Playlist_ID' = $object.Playlist_id
                'Playlist_Item_ID' = $object.playlist_item_id
                'Playlist_url' = $object.Playlist_url
                'Channel_ID' = $object.channel_id
                'Description' = $object.Description
                'Cached_Image_Path' = $object.Cached_Image_Path
                'Source' = 'Youtube'
                'Profile_Date_Added' = $object.Profile_Date_Added
                'url' = $object.url
                'type' = $object.type
                'Track' = $object.Track
                'Duration' = $object.Duration
                'Display_Name' = $object.Display_Name
              }                 
            } 'Twitch' {
              $mediaObject = [Media]@{
                'Id' = $object.id
                'User_id' = $object.User_id
                'Artist' = $object.Artist
                'Album' = $object.Album
                'Name' = $object.Name
                'Title' = $object.Title
                'Playlist' = $object.Playlist
                'Playlist_ID' = $object.Playlist_id
                'Playlist_url' = $object.Playlist_url
                'Channel_Name' = $object.Channel_Name
                'Description' = $object.Description
                'Live_Status' = $object.Live_Status
                'Stream_title' = $object.Stream_title
                'Status_Msg' = $object.Status_Msg
                'Viewer_Count' = $object.viewer_count
                'thumbnail' = $object.thumbnail
                'Cached_Image_Path' = $object.Cached_Image_Path
                'Profile_Image_Url' = $object.Profile_Image_Url
                'Offline_Image_Url' = $object.Offline_Image_Url
                'Chat_Url' = $object.Chat_Url
                'Source' = $object.Source
                'Followed' = $object.Followed
                'Profile_Date_Added' = $object.Profile_Date_Added
                'url' = $object.url
                'type' = $object.type
                'Track' = $object.Track
                'Duration' = $object.Duration
                'Enable_LiveAlert' = $object.Enable_LiveAlert
                'Display_Name' = $object.Display_Name
              }
            }
          } 
          if($List){
            $null = $OutputObject.add($mediaObject)
          }else{
            $OutputObject = $mediaObject
          }
        }else{
          if($List){
            $null = $OutputObject.add($Object)
          }else{
            $OutputObject = $Object
          }
          #$null = $all_Media.add($Object)
        }   
      }
    }catch{
      write-ezlogs "An exception occurred in ConvertTo-Media" -CatchError $_
    }
  }
  end {
    $PSCmdlet.WriteObject($OutputObject)
  } #close end block

}
#----------------------------------------------
#endregion ConvertTo-Media
#----------------------------------------------

#---------------------------------------------- 
#region ConvertTo-Playlists
#----------------------------------------------
function ConvertTo-Playlists {
  <#
      .Name
      ConvertTo-Playlists

      .SYNOPSIS
      Converts provided objects into a list of custom type 'playlist' with playlist_tracks property as a sorted list of type 'Media'

      .OUTPUTS
      System.Collections.Generic.List<Media>,API
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory, ValueFromPipeline)]
    $Playlists,
    [switch]$List,
    [switch]$Force
  )
  begin {
    if(($List -or $Playlists -is [System.Collections.Generic.list[Playlist]] -or $Playlists -is [System.Collections.Generic.list[Object]] -or $Playlists -is [System.Collections.ObjectModel.ObservableCollection[playlist]] -or $Playlists -is [Array] -or $Playlists -is [System.Collections.ArrayList]) -and $Playlists -isnot [PsCustomObject]){
      $List = $true
      $OutputObject = [System.Collections.Generic.list[playlist]]::new()
    }
  } #close begin block

  process {
    try{
      foreach($playlist in $Playlists){
        if($Force -or $playlist -isnot [playlist]){
          $playlist_tracks = [SerializableDictionary[int,[Media]]]::new()
          $Sorted = $playlist.Playlist_Tracks.keys | Sort-Object
          foreach($value in $Sorted){
            try{
              if($value -is [Double]){
                $object = $playlist.Playlist_Tracks.Item([Double]$value)
              }else{
                $object = $playlist.Playlist_Tracks.Item($value)
              }
              if($object){
                if($Force -or $object -isnot [Media]){
                  $mediaObject = $object | ConvertTo-Media -Force:$Force
                }else{
                  $mediaObject = $object
                }
                $Null = $playlist_Tracks.Add([int]$value,[media]$mediaObject)
              }
            }catch{
              write-ezlogs "An exception occurred adding playlist_track in ConvertTo-Playlists - value: $($value) - object: $($object)" -CatchError $_
            }finally{
              $mediaObject = $Null
              $object = $Null
            }
          }
          $PlaylistObject = [playlist]@{
            Name = $playlist.name
            Playlist_name = $playlist.Playlist_name
            title = $playlist.title
            Display_Name = $playlist.Display_Name
            #Status = $playlist.Status
            Status_Msg = $playlist.Status_Msg
            Playlist_ID = $playlist.Playlist_ID
            Description = $playlist.Description
            Playlist_Path = $playlist.Playlist_Path
            Playlist_URL = $playlist.Playlist_URL
            Playlist_Tracks = $playlist_Tracks
            #Image = $playlist.image
            Source = $playlist.Source
            Type = $playlist.Type
            Playlist_Date_Added = $playlist.Playlist_Date_Added
            IsExpanded = $playlist.IsExpanded
          }
          if($List){
            $Null = $OutputObject.add($PlaylistObject)
          }else{
            $OutputObject = $PlaylistObject
          }        
        }else{
          if($List){
            $Null = $OutputObject.add($Playlist)
          }else{
            $OutputObject = $Playlist
          }
        }
      }
    }catch{
      write-ezlogs "An exception occurred in ConvertTo-Playlists - mediaObject: $($mediaObject | out-string)" -CatchError $_
    }
  }
  end {
    $PSCmdlet.WriteObject($OutputObject)
  } #close end block

}
#----------------------------------------------
#endregion ConvertTo-Playlists
#----------------------------------------------

#---------------------------------------------- 
#region ConvertTo-EQPreset
#----------------------------------------------
function ConvertTo-EQPreset {
  <#
      .Name
      ConvertTo-EQPreset

      .SYNOPSIS
      Converts provided objects into custom type 'Custom_EQ_Preset'

      .OUTPUTS
      Custom_EQ_Preset
  #>
  [CmdletBinding()]
  param (
    [parameter(Mandatory, ValueFromPipeline)]
    $InputObject
  )
  process {
    try{
      if($InputObject -isnot [Custom_EQ_Preset]){
        if($InputObject.EQ_Bands -isnot [System.Collections.Generic.List[EQ_Band]]){
          if($InputObject.EQ_Bands.count -eq 0){
            $EQ_Bands = [System.Collections.Generic.List[EQ_Band]]::new()
          }else{
            $EQ_Bands = ($InputObject.EQ_Bands | & { process {[EQ_Band]$_}})
          }       
        }else{
          $EQ_Bands = $InputObject.EQ_Bands
        }
        $OutputObject = [Custom_EQ_Preset]@{
          'Preset_Name' = $InputObject.Preset_Name
          'Preset_ID'   = $InputObject.Preset_ID
          'Preset_Path' = $InputObject.Preset_Path
          'EQ_Preamp' = $InputObject.EQ_Preamp
          'EQ_Bands' = $EQ_Bands
        }
      }else{
        $OutputObject = $InputObject
      }
    }catch{
      write-ezlogs "An exception occurred in ConvertTo-Playlists" -CatchError $_
    }
  }
  end {
    $PSCmdlet.WriteObject($OutputObject)
  } #close end block
}
#----------------------------------------------
#endregion ConvertTo-EQPreset
#----------------------------------------------

#----------------------------------------------
#region Export-SerializedXML
#----------------------------------------------
function Export-SerializedXML {
  <#
      .Name
      Export-SerializedXML

      .SYNOPSIS
      Export-SerializedXML converts provided list of objects into custom type MediaObject to be saved to serialized XML file.

      .OUTPUTS
      None

      .NOTES
      - Properties are checked on an object by index of psobject.Properties.Name. Doing this is much faster than using Get-Member or otherwise enumerating member properties
      - If input object was already of type Media, conversion step could be bypassed completely, further improving speed as that is the most expensive step
      - The use of streamreader/writer greatly improves performance when reading/writing to disk as data is streamed to file as they are processed through pipeline. File is then closed in the finally scriptblock
      - Pipeline to Process scriptblock is used in place of foreach or Foreach-Object. Allows best of both worlds - the performance benefit of foreach and the memory benefit of piplining to Foreach-Object
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,
    [Parameter(Mandatory=$true)]
    $InputObject,
    [switch]$isConfig,
    [switch]$isAPI,
    [switch]$isEQPreset,
    [Switch]$isPlaylist,
    [switch]$EncodeValues,
    [switch]$Force,
    [String]$entropy
  )
  try{
    if($isAPI -and [bool]('API' -as [Type])){
      $Output = [API]::new()
      foreach($property in $InputObject.psobject.properties.name){
        if(($Output.psobject.properties[$property])){
          if($EncodeValues){
            if(-not [string]::IsNullOrEmpty($InputObject.$property)){
              $idbytes = [System.Text.Encoding]::UTF8.GetBytes($InputObject.$property)
              $Output.$property = [System.Convert]::ToBase64String($idbytes)
              #$encryptedbyes = [System.Security.Cryptography.ProtectedData]::Protect([System.Text.Encoding]::UTF8.GetBytes($InputObject.$property),[System.Text.Encoding]::UTF8.GetBytes($entropy),[System.Security.Cryptography.DataProtectionScope]::LocalMachine)
              #$Output.$property = [System.Convert]::ToBase64String($encryptedbyes)
            }
          }else{
            $Output.$property = $InputObject.$property
          }
        }
      }
    }elseif($isConfig -and [bool]('Config' -as [Type])){
      #Check types and convert if needed - only required when converting old configs to new format
      #SerializableDictionary is a custom class that acts as a wrapper to make Dictionary be able to be serialized with IXmlSerializable
      if($InputObject.Current_Playlist -isnot [SerializableDictionary[int,string]]){
        if($thisApp.Config.Dev_mode){write-ezlogs "Converting Current_Playlist" -Warning -Dev_mode}
        $Current_Playlist = [SerializableDictionary[int,string]]::new()
        foreach($value in $InputObject.Current_Playlist.keys){
          $Null = $Current_Playlist.Add([int]$value,[string]$InputObject.Current_Playlist.Item($value))
        }
      }else{
        $Current_Playlist = $InputObject.Current_Playlist
      }
      if($InputObject.History_Playlist -isnot [SerializableDictionary[int,string]]){
        if($thisApp.Config.Dev_mode){write-ezlogs "Converting History_Playlist" -Warning -Dev_mode}
        $History_Playlist = [SerializableDictionary[int,string]]::new()
        foreach($value in $InputObject.History_Playlist.keys){
          $Null = $History_Playlist.Add([int]$value,[string]$InputObject.History_Playlist.Item($value))
        }
      }else{
        $History_Playlist = $InputObject.History_Playlist
      }
      if($InputObject.Custom_EQ_Presets -isnot [System.Collections.Generic.List[Custom_EQ_Preset]]){
        if($thisApp.Config.Dev_mode){write-ezlogs "Converting Custom_EQ_Presets" -Warning -Dev_mode}
        if($InputObject.Custom_EQ_Presets.count -eq 0){
          $Custom_EQ_Presets = [System.Collections.Generic.List[Custom_EQ_Preset]]::new()
        }else{
          $Custom_EQ_Presets = ($InputObject.Custom_EQ_Presets | & { process {[Custom_EQ_Preset]$_}})
        }        
      }else{
        $Custom_EQ_Presets = $InputObject.Custom_EQ_Presets
      }
      if($InputObject.Twitch_Playlists -isnot [System.Collections.Generic.List[Twitch_Playlist]]){
        if($thisApp.Config.Dev_mode){write-ezlogs "Converting Twitch_Playlists" -Warning -Dev_mode}
        if($InputObject.Twitch_Playlists.count -eq 0){
          $Twitch_Playlists = [System.Collections.Generic.List[Twitch_Playlist]]::new()
        }else{
          $Twitch_Playlists = ($InputObject.Twitch_Playlists | & { process {[Twitch_Playlist]$_}})
        }      
      }else{
        $Twitch_Playlists = $InputObject.Twitch_Playlists
      }
      if($InputObject.Webview2_Extensions -isnot [System.Collections.Generic.List[WebExtension]]){
        if($thisApp.Config.Dev_mode){write-ezlogs "Converting Webview2_Extensions" -Warning -Dev_mode}
        if($InputObject.Webview2_Extensions.count -eq 0){
          $Webview2_Extensions = [System.Collections.Generic.List[WebExtension]]::new()
        }else{
          $Webview2_Extensions = ($InputObject.Webview2_Extensions | & { process {[WebExtension]$_}})
        }
      }else{
        $Webview2_Extensions = $InputObject.Webview2_Extensions
      }
      if($InputObject.Youtube_Cookies -isnot [System.Collections.Generic.List[Cookie]]){
        if($thisApp.Config.Dev_mode){write-ezlogs "Converting Youtube_Cookies" -Warning -Dev_mode}
        if($InputObject.Youtube_Cookies.count -eq 0){
          $Youtube_Cookies = [System.Collections.Generic.List[Cookie]]::new()
        }else{
          $Youtube_Cookies = ($InputObject.Youtube_Cookies | & { process {[Cookie]$_}})
        }        
      }else{
        $Youtube_Cookies = $InputObject.Youtube_Cookies
      }
      if($InputObject.EQ_Presets -isnot [System.Collections.Generic.List[EQ_Preset]]){
        if($thisApp.Config.Dev_mode){write-ezlogs "Converting EQ_Presets" -Warning -Dev_mode}
        if($InputObject.EQ_Presets.count -eq 0){
          $EQ_Presets = [System.Collections.Generic.List[EQ_Preset]]::new()
        }else{
          $EQ_Presets = ($InputObject.EQ_Presets | & { process {[EQ_Preset]$_}})
        }    
      }else{
        $EQ_Presets = $InputObject.EQ_Presets
      }
      if($InputObject.EQ_Bands -isnot [System.Collections.Generic.List[EQ_Band]]){
        if($thisApp.Config.Dev_mode){write-ezlogs "Converting EQ_Bands" -Warning -Dev_mode}
        if($InputObject.EQ_Bands.count -eq 0){
          $EQ_Bands = [System.Collections.Generic.List[EQ_Band]]::new()
        }else{
          $EQ_Bands = ($InputObject.EQ_Bands | & { process {[EQ_Band]$_}})
        }       
      }else{
        $EQ_Bands = $InputObject.EQ_Bands
      }
      if($InputObject.GlobalHotKeys -isnot [System.Collections.Generic.List[GlobalHotKey]]){
        if($thisApp.Config.Dev_mode){write-ezlogs "Converting GlobalHotKeys" -Warning -Dev_mode}
        if($InputObject.GlobalHotKeys.count -eq 0){
          $GlobalHotKeys = [System.Collections.Generic.List[GlobalHotKey]]::new()
        }else{
          $GlobalHotKeys = ($InputObject.GlobalHotKeys | & { process {[GlobalHotKey]$_}})
        }    
      }else{
        $GlobalHotKeys = $InputObject.GlobalHotKeys
      }
      $Output = [Config]@{
        'Media_Profile_Directory' = $InputObject.Media_Profile_Directory
        'Bookmarks_Profile_Directory' = $InputObject.Bookmarks_Profile_Directory
        'Use_Profile_Cache' = $InputObject.Use_Profile_Cache
        'Log_Level' = $InputObject.Log_Level
        'Streamlink_HTTP_Port' = $InputObject.Streamlink_HTTP_Port
        'TwitchMedia_Log_File' = $InputObject.TwitchMedia_Log_File
        'YoutubeMedia_Log_File' = $InputObject.YoutubeMedia_Log_File
        'SpotifyMedia_Log_File' = $InputObject.SpotifyMedia_Log_File
        'Launcher_Log_File' = $InputObject.Launcher_Log_File
        'VLC_Arguments' = $InputObject.VLC_Arguments
        'Auto_UpdateInstall' = $InputObject.Auto_UpdateInstall
        'LocalMedia_FastImporting' = $InputObject.LocalMedia_FastImporting
        'Enablelinkedconnections' = $InputObject.Enablelinkedconnections
        'Found_Hell' = $InputObject.Found_Hell
        'Profile_Write_IDTags' = $InputObject.Profile_Write_IDTags
        'Mute_Twitch_Ads' = $InputObject.Mute_Twitch_Ads
        'Always_On_Top' = $InputObject.Always_On_Top
        'Verbose_logging' = $InputObject.Verbose_logging
        'Toggle_FullScreen' = $InputObject.Toggle_FullScreen
        'PlayLink_OnDrop' = $InputObject.PlayLink_OnDrop
        'SplashScreenAudio' = $InputObject.SplashScreenAudio
        'Enable_Marquee' = $InputObject.Enable_Marquee
        'ForceUse_YTDLP' = $InputObject.ForceUse_YTDLP
        'Media_Volume' = $InputObject.Media_Volume
        'Spotify_SP_DC' = $InputObject.Spotify_SP_DC
        'Youtube_1PSID' = $InputObject.Youtube_1PSID
        'Youtube_1PAPISID' = $InputObject.Youtube_1PAPISID
        'Youtube_3PAPISID' = $InputObject.Youtube_3PAPISID
        'Chat_WebView2_Cookie' = $InputObject.Chat_WebView2_Cookie
        'Twitch_auth_Cookie' = $InputObject.Twitch_auth_Cookie
        'Local_Group_By' = $InputObject.Local_Group_By
        'Spotify_Group_By' = $InputObject.Spotify_Group_By
        'Youtube_Group_By' = $InputObject.Youtube_Group_By
        'Twitch_Group_By' = $InputObject.Twitch_Group_By
        'SpotifyBrowser_Paging' = $InputObject.SpotifyBrowser_Paging
        'YoutubeBrowser_Paging' = $InputObject.YoutubeBrowser_Paging
        'MediaBrowser_Paging' = $InputObject.MediaBrowser_Paging
        'TwitchBrowser_Paging' = $InputObject.TwitchBrowser_Paging
        'Media_Directories' = $InputObject.Media_Directories
        'Custom_EQ_Presets' = $Custom_EQ_Presets
        'Spotify_Playlists' = $InputObject.Spotify_Playlists
        'Youtube_Playlists' = $InputObject.Youtube_Playlists
        'Current_Playlist' = $Current_Playlist
        'History_Playlist' = $History_Playlist
        'Snapshots_Path' = $InputObject.Snapshots_Path
        'LocalMedia_ImportMode' = $InputObject.LocalMedia_ImportMode
        'Use_Twitch_TTVLOL' = $InputObject.Use_Twitch_TTVLOL
        'Use_Twitch_luminous' = $InputObject.Use_Twitch_luminous
        'UseTwitchCustom' = $InputObject.UseTwitchCustom
        'TwitchProxies' = $InputObject.TwitchProxies
        'Streamlink_Arguments' = $InputObject.Streamlink_Arguments
        'Minimize_To_Tray' = $InputObject.Minimize_To_Tray
        'Disable_Tray' = $InputObject.Disable_Tray
        'LocalMedia_MonitorMode' = $InputObject.LocalMedia_MonitorMode
        'App_UniqueID' = $InputObject.App_UniqueID
        'Twitch_Quality' = $InputObject.Twitch_Quality
        'Youtube_Cookies' = $Youtube_Cookies
        'Verbose_perf_measure' = $InputObject.Verbose_perf_measure
        'YoutubeMedia_Library_CollapseAllGroups' = $InputObject.YoutubeMedia_Library_CollapseAllGroups
        'YoutubeMedia_Library_Columns' = $InputObject.YoutubeMedia_Library_Columns
        'TwitchMedia_Library_Columns' = $InputObject.TwitchMedia_Library_Columns
        'IsRead_AboutFirstRun' = $InputObject.IsRead_AboutFirstRun
        'IsRead_SpecialFirstRun' = $InputObject.IsRead_SpecialFirstRun
        'IsRead_TestFeatures' = $InputObject.IsRead_TestFeatures
        'SpotifyMedia_Library_CollapseAllGroups' = $InputObject.SpotifyMedia_Library_CollapseAllGroups
        'TwitchMedia_Library_CollapseAllGroups' = $InputObject.TwitchMedia_Library_CollapseAllGroups
        'Use_Preferred_VPN' = $InputObject.Use_Preferred_VPN
        'Preferred_VPN' = $InputObject.Preferred_VPN
        'Show_Notifications' = $InputObject.Show_Notifications
        'Webview2_Extensions' = $Webview2_Extensions
        'Use_invidious' = $InputObject.Use_invidious
        'Audio_OutputModule' = $InputObject.Audio_OutputModule
        'Notification_Audio' = $InputObject.Notification_Audio
        'LocalMedia_Library_Columns' = $InputObject.LocalMedia_Library_Columns
        'Current_Theme' = [ColorTheme]@{'Name' = $InputObject.Current_Theme.Name;'Menu_Item' = $InputObject.Current_Theme.Menu_Item;'PrimaryAccentColor' = $InputObject.Current_Theme.PrimaryAccentColor}
        'Enable_EQ2Pass' = $InputObject.Enable_EQ2Pass
        'Twitch_Playlists' = $Twitch_Playlists
        'Remember_Window_Positions' = $InputObject.Remember_Window_Positions
        'Mini_Always_On_Top' = $InputObject.Mini_Always_On_Top
        'Start_Tray_only' = $InputObject.Start_Tray_only
        'Start_Mini_only' = $InputObject.Start_Mini_only
        'LocalMedia_Library_CollapseAllGroups' = $InputObject.LocalMedia_Library_CollapseAllGroups
        'Shuffle_Playback' = $InputObject.Shuffle_Playback
        'Enable_AudioMonitor' = $InputObject.Enable_AudioMonitor
        'Auto_UpdateCheck' = $InputObject.Auto_UpdateCheck
        'Last_SpeakerLeft_Image' = $InputObject.Last_SpeakerLeft_Image
        'Vlc_Verbose_logging' = $InputObject.Vlc_Verbose_logging
        'SpotifyMedia_Library_Columns' = $InputObject.SpotifyMedia_Library_Columns
        'Auto_Playback' = $InputObject.Auto_Playback
        'Auto_Repeat' = $InputObject.Auto_Repeat
        'Enable_EQ' = $InputObject.Enable_EQ
        'ShowTitleBar' = $InputObject.ShowTitleBar
        'Last_Splash_Image' = $InputObject.Last_Splash_Image
        'EQ_Selected_Preset' = $InputObject.EQ_Selected_Preset
        'Libvlc_Version' = $InputObject.Libvlc_Version
        'Current_Audio_Output' = $InputObject.Current_Audio_Output
        'Enable_YoutubeComments' = $InputObject.Enable_YoutubeComments
        'Enable_Subtitles' = $InputObject.Enable_Subtitles
        'LocalMedia_Display_Syntax' = $InputObject.LocalMedia_Display_Syntax
        'Chat_View' = $InputObject.Chat_View
        'Video_Snapshots' = $InputObject.Video_Snapshots
        'App_Snapshots' = $InputObject.App_Snapshots
        'Enable_Performance_Mode' = $InputObject.Enable_Performance_Mode
        'Use_HardwareAcceleration' = $InputObject.Use_HardwareAcceleration
        'Enable_WebEQSupport' = $InputObject.Enable_WebEQSupport
        'Open_VideoPlayer' = $InputObject.Open_VideoPlayer
        'Remember_Playback_Progress' = $InputObject.Remember_Playback_Progress
        'Start_Paused' = $InputObject.Start_Paused
        'Current_Visualization' = $InputObject.Current_Visualization
        'Use_Visualizations' = $InputObject.Use_Visualizations
        'Use_MediaCasting' = $InputObject.Use_MediaCasting
        'LocalMedia_SkipDuplicates' = $InputObject.LocalMedia_SkipDuplicates
        'Enable_LocalMedia_Monitor' = $InputObject.Enable_LocalMedia_Monitor
        'Spotify_WebPlayer' = $InputObject.Spotify_WebPlayer
        'Spotify_Update' = $InputObject.Spotify_Update
        'Spotify_Update_Interval' = $InputObject.Spotify_Update_Interval
        'Youtube_WebPlayer' = $InputObject.Youtube_WebPlayer
        'Youtube_Update_Interval' = $InputObject.Youtube_Update_Interval
        'Enable_Sponsorblock' = $InputObject.Enable_Sponsorblock
        'Youtube_Quality' = $InputObject.Youtube_Quality
        'Import_My_Youtube_Media' = $InputObject.Import_My_Youtube_Media
        'Twitch_Update_Interval' = $InputObject.Twitch_Update_Interval
        'Enable_Twitch_Notifications' = $InputObject.Enable_Twitch_Notifications
        'Skip_Twitch_Ads' = $InputObject.Skip_Twitch_Ads
        'Streamlink_Interface' = $InputObject.Streamlink_Interface
        'Streamlink_Verbose_logging' = $InputObject.Streamlink_Verbose_logging
        'Twitch_Update' = $InputObject.Twitch_Update
        'Start_On_Windows_Login' = $InputObject.Start_On_Windows_Login
        'Import_Local_Media' = $InputObject.Import_Local_Media
        'Import_Youtube_Media' = $InputObject.Import_Youtube_Media
        'Youtube_Browser' = $InputObject.Youtube_Browser
        'Youtube_Update' = $InputObject.Youtube_Update
        'Youtube_Download_Path' = $InputObject.Youtube_Download_Path
        'Sponsorblock_ActionType' = $InputObject.Sponsorblock_ActionType
        'Import_Twitch_Media' = $InputObject.Import_Twitch_Media
        'Use_Spicetify' = $InputObject.Use_Spicetify
        'Import_Spotify_Media' = $InputObject.Import_Spotify_Media
        'Install_Spotify' = $InputObject.Install_Spotify
        'Import_Youtube_Browser_Auth' = $InputObject.Import_Youtube_Browser_Auth
        'Discord_Integration' = $InputObject.Discord_Integration
        'Media_Muted' = $InputObject.Media_Muted
        'Current_Playing_Media' = $InputObject.Current_Playing_Media
        'Last_Played' = $InputObject.Last_Played
        'EQ_Preamp' = $InputObject.EQ_Preamp
        'Libvlc_Global_Gain' = $InputObject.Libvlc_Global_Gain
        'Log_file' = $InputObject.Log_file
        'Config_Path' = $InputObject.Config_Path
        'Playlists_Profile_Path' = $InputObject.Playlists_Profile_Path
        'Current_Folder' = $InputObject.Current_Folder
        'image_Cache_path' = $InputObject.image_Cache_path
        'App_Name' = $InputObject.App_Name
        'Templates_Directory' = $InputObject.Templates_Directory
        'Playlist_Profile_Directory' = $InputObject.Playlist_Profile_Directory
        'EQPreset_Profile_Directory' = $InputObject.EQPreset_Profile_Directory
        'VLC_Log_File' = $InputObject.VLC_Log_File
        'LibVLC_Log_File' = $InputObject.LibVLC_Log_File
        'Streamlink_Log_File' = $InputObject.Streamlink_Log_File
        'Startup_Log_File' = $InputObject.Startup_Log_File
        'Error_Log_File' = $InputObject.Error_Log_File
        'LocalMedia_Log_File' = $InputObject.LocalMedia_Log_File
        'Discord_Log_File' = $InputObject.Discord_Log_File
        'Perf_Log_File' = $InputObject.Perf_Log_File
        'Webview2_Log_File' = $InputObject.Webview2_Log_File
        'Setup_Log_File' = $InputObject.Setup_Log_File
        'Threading_Log_File' = $InputObject.Threading_Log_File
        'Uninstall_Log_File' = $InputObject.Uninstall_Log_File
        'Friends_Profile_Directory' = $InputObject.Friends_Profile_Directory
        'App_Version' = $InputObject.App_Version
        'App_Exe_Path' = $InputObject.App_Exe_Path
        'App_Build' = $InputObject.App_Build
        'logfile_directory' = $InputObject.logfile_directory
        'SpotifyMedia_logfile' = $InputObject.SpotifyMedia_logfile
        'YoutubeMedia_logfile' = $InputObject.YoutubeMedia_logfile
        'TwitchMedia_logfile' = $InputObject.TwitchMedia_logfile
        'Tor_Log_File' = $InputObject.Tor_Log_File
        'Download_logfile' = $InputObject.Download_logfile
        'Startup_perf_timer' = $InputObject.Startup_perf_timer
        'Temp_Folder' = $InputObject.Temp_Folder
        'Dev_mode' = $InputObject.Dev_mode
        'Debug_mode' = $InputObject.Debug_mode
        'Splash_Top' = $InputObject.Splash_Top
        'Splash_Left' = $InputObject.Splash_Left
        'EQ_Presets' = $EQ_Presets
        'EQ_Bands' = $EQ_Bands
        'Installed_AppID' = $InputObject.Installed_AppID
        'MainWindow_Top' = $InputObject.MainWindow_Top
        'MainWindow_Left' = $InputObject.MainWindow_Left
        'MiniWindow_Top' = $InputObject.MiniWindow_Top
        'MiniWindow_Left' = $InputObject.MiniWindow_Left
        'VideoWindow_Top' = $InputObject.VideoWindow_Top
        'VideoWindow_Left' = $InputObject.VideoWindow_Left
        'LibraryWindow_Top' = $InputObject.LibraryWindow_Top
        'LibraryWindow_Left' = $InputObject.LibraryWindow_Left
        'BrowserWindow_Top' = $InputObject.BrowserWindow_Top
        'BrowserWindow_Left' = $InputObject.BrowserWindow_Left
        'GlobalHotKeys' = $GlobalHotKeys
        'EnableGlobalHotKeys' = $InputObject.EnableGlobalHotKeys
        'Enable_HighDPI' = $InputObject.Enable_HighDPI
      }
    }elseif($isPlaylist){
      $output = $InputObject | ConvertTo-Playlists -List -Force:$Force
    }elseif($isEQPreset){
      $output = $InputObject | ConvertTo-EQPreset
    }else{
      $output = $InputObject | ConvertTo-Media -List
    }
    $serializer = [System.Xml.Serialization.XmlSerializer]::new($output.GetType())
    $fs = [System.IO.StreamWriter]::new($Path)
    $serializer.Serialize($fs,$output)
  }catch{
    throw $_
  }finally{
    if($fs -is [System.IDisposable]){
      $null = $fs.dispose()
    }
  }
}
#---------------------------------------------- 
#endregion Export-SerializedXML
#----------------------------------------------

#---------------------------------------------- 
#region Import-SerializedXML
#----------------------------------------------
function Import-SerializedXML {
  <#
      .Name
      Import-SerializedXML

      .SYNOPSIS
      Import-SerializedXML reads and deserializes XML file back into a list of Objects of type Media

      .OUTPUTS
      System.Collections.Generic.List<Media>,API
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,
    [switch]$isAPI,
    [parameter(ValueFromPipeline)]
    [string]$String,
    [switch]$isConfig,
    [switch]$isPlaylist,
    [switch]$isEQPreset,
    [switch]$DecodeValues,
    [string]$entropy
  )
  try{
    if($isAPI){
      $serializer = [System.Xml.Serialization.XmlSerializer]::new([API])
    }elseif($isConfig){
      $serializer = [System.Xml.Serialization.XmlSerializer]::new([Config])
    }elseif($isPlaylist){
      $serializer = [System.Xml.Serialization.XmlSerializer]::new([System.Collections.Generic.List[Playlist]])
    }elseif($isEQPreset){
      $serializer = [System.Xml.Serialization.XmlSerializer]::new([Custom_EQ_Preset])
    }else{
      $serializer = [System.Xml.Serialization.XmlSerializer]::new([System.Collections.Generic.List[Media]])
    }    
    if(-not [string]::IsNullOrEmpty($String)){
      $sr = [XML.XMLReader]::Create([IO.StringReader]$String)
    }else{
      $sr = [System.IO.StreamReader]::new($Path)
    }   
    if($DecodeValues){
      $output = $serializer.Deserialize($sr)
      foreach($property in $output.psobject.properties.name){
        $Output.$property =  [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Output.$property))
        <#        if(-not [string]::IsNullOrEmpty($Output.$property)){
            $encrypteddata = [System.Security.Cryptography.ProtectedData]::UnProtect([System.Convert]::FromBase64String($Output.$property),[System.Text.Encoding]::UTF8.GetBytes($entropy),[System.Security.Cryptography.DataProtectionScope]::LocalMachine)
            $Output.$property = [System.Text.Encoding]::UTF8.GetString($encrypteddata)
        }#>
      }
      $PSCmdlet.WriteObject($output)
    }else{
      $PSCmdlet.WriteObject($serializer.Deserialize($sr)) #PSCmdlet.WriteObject allows the returning of the list without unpacking it
    }
  }catch{
    throw $_
  }finally{
    if($sr -is [System.IDisposable]){
      $Null = $sr.dispose()
    }
  }
}
#----------------------------------------------
#endregion Import-SerializedXML
#----------------------------------------------
Export-ModuleMember -Function @('Export-SerializedXML','Import-SerializedXML','ConvertTo-Playlists','ConvertTo-Media')