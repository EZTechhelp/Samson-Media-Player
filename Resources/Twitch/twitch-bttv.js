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

(function betterttv() {
    var script = document.createElement('script');
    script.type = 'text/javascript';
    script.src = 'https://cdn.betterttv.net/betterttv.js';
    var head = document.getElementsByTagName('head')[0];
    if (!head) return;
    head.appendChild(script);
})()