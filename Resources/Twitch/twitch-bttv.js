// ==UserScript==
// @name         BetterTTV
// @namespace    https://nightdev.com/betterttv/
// @version      0.1
// @description  BetterTTV enhances Twitch with new features, emotes, and more. We like to think we make Twitch better.
// @author       night
// @match        *://*.twitch.tv/*
// @exclude      *://*.twitch.tv/*.html
// @exclude      *://*.twitch.tv/*.html?*
// @exclude      *://*.twitch.tv/*.htm
// @exclude      *://*.twitch.tv/*.htm?*
// @grant        none
// ==/UserScript==

//TrustedScriptURL
if (window.trustedTypes && window.trustedTypes.createPolicy) { // Feature testing
    window.trustedTypes.createPolicy('default', {
        createHTML: string => string,
        createScriptURL: string => string, // warning: this is unsafe!
        createScript: string => string, // warning: this is unsafe!
    });
}
function fixCSP () {
  const cspMetaElement = document.querySelector('meta[http-equiv="Content-Security-Policy"]');
  if (!!cspMetaElement) return;
  
  const cspContent = "script-src 'unsafe-eval' 'self' 'unsafe-inline' https://cdn.betterttv.net https://www.google.com https://apis.google.com https://ssl.gstatic.com https://www.gstatic.com https://www.googletagmanager.com https://www.google-analytics.com https://*.youtube.com https://*.google.com https://*.gstatic.com https://youtube.com https://www.youtube.com https://google.com https://*.doubleclick.net https://*.googleapis.com https://www.googleadservices.com https://tpc.googlesyndication.com https://www.youtubekids.com https://www.youtube-nocookie.com https://www.youtubeeducation.com https://www-onepick-opensocial.googleusercontent.com";

  const metaElement = document.createElement('meta');
  metaElement.httpEquiv = "Content-Security-Policy";
  metaElement.content = cspContent;
  
  // To add this element to the document's head:
  document.head.appendChild(metaElement);
}

(function betterttv() {	
    //fixCSP();
    var script = document.createElement('script');
    script.type = 'text/javascript';
    script.src = 'https://cdn.betterttv.net/betterttv.js';
    var head = document.getElementsByTagName('head')[0];
    if (!head) return;
    head.appendChild(script);
})()