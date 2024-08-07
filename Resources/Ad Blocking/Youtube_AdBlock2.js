// ==UserScript==
// @name YouTube Ad Blocker YouTube AD Blocker
// @name:zh-CN YouTube Advertisement
// @name:zh-TW YouTube Ads Free
// @name:zh-HK YouTube without advertising
// @name:zh-MO YouTube without ads
// @namespace http://tampermonkey.net/
// @version 5.2
// @description This is a script that removes ads on YouTube, it's lightweight and efficient, capable of smoothly removing interface and video ads, including 6s ads.
// @author iamfugui
// @match *://*.youtube.com/*
// @icon https://www.google.com/s2/favicons?sz=64&domain=YouTube.com
// @grant none
// @license MIT
// ==/UserScript==
function runBlockYoutube() {
    `use strict`;
        const LOGO_ID = 'block-youtube-ads-logo';
        const addAdGuardLogoStyle = () => {
            const id = 'block-youtube-ads-logo-style';
            if (document.getElementById(id)) {
                return;
            }

            // Here is what these styles do:
            // 1. Change AG marker color depending on the page
            // 2. Hide Sign-in button on m.youtube.com otherwise it does not look good
            // It is still possible to sign in by clicking "three dots" button.
            // 3. Hide the marker when the user is searching for something
            // 4. On YT Music apply display:block to the logo element
            const style = document.createElement('style');
            style.innerHTML = `[data-mode="watch"] #${LOGO_ID} { color: #fff; }
[data-mode="searching"] #${LOGO_ID}, [data-mode="search"] #${LOGO_ID} { display: none; }
#${LOGO_ID} { white-space: nowrap; }
.mobile-topbar-header-sign-in-button { display: none; }
.ytmusic-nav-bar#left-content #${LOGO_ID} { display: block; }`;
            document.head.appendChild(style);
        };

        const addAdGuardLogo = () => {
            if (document.getElementById(LOGO_ID)) {
                return;
            }
            log(`Adding Youtube Logo title: Enhanced By Samson Media Player`);
            const logo = document.createElement('span');
            logo.innerHTML = 'Enhanced By Samson Media Player';
            logo.setAttribute('id', LOGO_ID);

            if (window.location.hostname === 'm.youtube.com') {
                const btn = document.querySelector('header.mobile-topbar-header > button');
                if (btn) {
                    btn.parentNode.insertBefore(logo, btn.nextSibling);
                    addAdGuardLogoStyle();
                }
            } else if (window.location.hostname === 'www.youtube.com') {
                const code = document.getElementById('country-code');
                if (code) {
                    code.innerHTML = '';
                    code.appendChild(logo);
                    addAdGuardLogoStyle();
                }
            } else if (window.location.hostname === 'music.youtube.com') {
                const el = document.querySelector('.ytmusic-nav-bar#left-content');
                if (el) {
                    el.appendChild(logo);
                    addAdGuardLogoStyle();
                }
            } else if (window.location.hostname === 'www.youtube-nocookie.com') {
                const code = document.querySelector('#yt-masthead #logo-container .content-region');
                if (code) {
                    code.innerHTML = '';
                    code.appendChild(logo);
                    addAdGuardLogoStyle();
                }
            }
        };	

    /// interface ad selector
    const cssSeletorArr = [
        `#masthead-ad`,//The banner ad at the top of the home page.
        `ytd-rich-item-renderer.style-scope.ytd-rich-grid-row #content:has(.ytd-display-ad-renderer)`,//Home page video layout advertisement.
        `ytd-rich-section-renderer #dismissible`,//Banner advertisement in the middle of the homepage.
        `.video-ads.ytp-ad-module`,// Advertisement at the bottom of the player..
        `tp-yt-paper-dialog:has(yt-mealbar-promo-renderer)`,//Play member promotion advertisement on page.
        `#related #player-ads`,//Promote ads on the right side of the comment area of the player page.
        `#related ytd-ad-slot-renderer`, //The video typesetting advertisement on the right side of the comment area of the playback page.
        `ytd-ad-slot-renderer`,// search page advertisement.
        `yt-mealbar-promo-renderer`,//Play page member recommendation advertisement.	
    ];
	
	
	
    const dev = true;//开发使用
    let video;//视频dom


    /**
    * 将标准时间格式化
    * @param {Date} time 标准时间
    * @param {String} format 格式
    * @return {String}
    */
    function moment(time, format = `YYYY-MM-DD HH:mm:ss`) {
        // 获取年⽉⽇时分秒
        let y = time.getFullYear()
        let m = (time.getMonth() + 1).toString().padStart(2, `0`)
        let d = time.getDate().toString().padStart(2, `0`)
        let h = time.getHours().toString().padStart(2, `0`)
        let min = time.getMinutes().toString().padStart(2, `0`)
        let s = time.getSeconds().toString().padStart(2, `0`)
        if (format === `YYYY-MM-DD`) {
            return `${y}-${m}-${d}`
        } else {
            return `${y}-${m}-${d} ${h}:${min}:${s}`
        }
    }

    /**
    * 输出信息
    * @param {String} msg 信息
    * @return {undefined}
    */
    function log(msg) {
        if(!dev){
            return false;
        }
        console.log(`${moment(new Date())}  ${msg}`)
    }

    /**
    * 获取当前url的参数,如果要查询特定参数请传参
    * @param {String} 要查询的参数
    * @return {String || Object}
    */
    function getUrlParams(param) {
        // 通过 ? 分割获取后面的参数字符串
        let urlStr = location.href.split(`?`)[1]	
        if(!urlStr){
            return ``;
        }
        // 创建空对象存储参数
        let obj = {};
        // 再通过 & 将每一个参数单独分割出来
        let paramsArr = urlStr.split(`&`)
        for(let i = 0,len = paramsArr.length;i < len;i++){
            // 再通过 = 将每一个参数分割为 key:value 的形式
            let arr = paramsArr[i].split(`=`)
            obj[arr[0]] = arr[1];
        }

        if(!param){
            return obj;
        }

        return obj[param]||``;
    }

    /**
    * 生成去除广告的css元素style并附加到HTML节点上
    * @param {String} styles 样式文本
    * @param {String} styleId 元素id
    * @return {undefined}
    */
    function generateRemoveADHTMLElement(styles,styleId) {
        //如果已经设置过,退出.
        if (document.getElementById(styleId)) {
            return false
        }

        //设置移除广告样式.
        let style = document.createElement(`style`);//创建style元素.
        style.id = styleId;
        (document.querySelector(`head`) || document.querySelector(`body`)).appendChild(style);//将节点附加到HTML.
        style.appendChild(document.createTextNode(styles));//附加样式节点到元素节点.
        log(`Shield page ad node has been generated`)

    }

    /**
    * 生成去除广告的css文本
    * @param {Array} cssSeletorArr 待设置css选择器数组
    * @return {String}
    */
    function generateRemoveADCssText(cssSeletorArr){
        cssSeletorArr.forEach((seletor,index)=>{
            cssSeletorArr[index]=`${seletor}{display:none!important}`;//遍历并设置样式.
        });
        return cssSeletorArr.join(` `);//拼接成字符串.
    }

    /**
    * skip ad
    * @return {undefined}
    */
    function skipAd(mutationsList, observer) {
        const minTime = 60;
        const maxTime = 120;
        const randomTime = Math.floor(Math.random() * (maxTime - minTime + 1)) + minTime;

        let skipButton = document.querySelector(`.ytp-ad-skip-button`);
        let shortAdMsg = document.querySelector(`.video-ads.ytp-ad-module .ytp-ad-player-overlay`);
        let adsShowing  = document.querySelector('.ad-showing')
        if(!skipButton && !shortAdMsg && !adsShowing){
            log(`******Ad End Changes******`);
            return false;
        }

        const fn = () => {
            skipButton = document.querySelector(`.ytp-ad-skip-button`);
            shortAdMsg = document.querySelector(`.video-ads.ytp-ad-module .ytp-ad-player-overlay`);
            adsShowing = document.querySelector('.ad-showing')
            if(skipButton||shortAdMsg||adsShowing){
                video.muted = true;//Turn off ad sound
            }

            //Ads with a skip button.
            if(skipButton)
            {
                log(`~~~~~~~~~~~~~regular video ad`);
                log(`total time:`);
                log(`${video.duration}`)
                log(`current time:`);
                log(`${video.currentTime}`)
                skipButton.click();// 跳过广告.
                log(`button to skip the ad~~~~~~~~~~~~~`);
                return false;//termination
            }

            //Short ads without skip buttons.
            if(shortAdMsg){
                log(`~~~~~~~~~~~~~Forced video advertisement`);
                log(`total time:`);
                log(`${video.duration}`)
                log(`current time:`);
                log(`${video.currentTime}`)
                video.currentTime = 1024;
                log(`Force ended the ad~~~~~~~~~~~~~`);
                return false;//termination
            }
            if(adsShowing && video && video.duration){
				try{
					console.log(`~~~~~~~~~~~~~Forced video advertisement`);
					console.log(`total time: ${video.duration}`);
					console.log(`current time: ${video.currentTime}`);
					if(video && video.duration){
					  video.currentTime = video.duration;
					  log(`Force ended the ad~~~~~~~~~~~~~`);	
					}
				}catch (e){
					console.log('An exception occurred force ending the ad',e);
				}
                return false;//termination
            }			
            video.muted = false;//Turn on video sound
            log(`######Ad previously closed######`);
        }
        fn();//Standard implementation

        let timer = setTimeout(fn, randomTime);//ready for execution

        setTimeout(()=>{
            skipButton = document.querySelector(`.ytp-ad-skip-button`);
            shortAdMsg = document.querySelector(`.video-ads.ytp-ad-module .ytp-ad-player-overlay`);
			adsShowing = document.querySelector('.ad-showing')
            if(skipButton || shortAdMsg || adsShowing){
                log(`*****Failed to close all advertisements, continue to execute a round of Fn******`);
            }else{
                clearTimeout(timer);
                log(`*****Close Advertisement Successfully******`);
            }
        }, 0);

    }

    /**
    * Remove ads while playing
    * @return {undefined}
    */
    function removePlayerAD(){
        let observer;//listener         
        //start listening
        function startObserve(){
            video = document.querySelector(`video`);//get video node           
            //Advertising node monitoring
            //const targetNode = document.querySelector(`.video-ads.ytp-ad-module`);
			const targetNode = document.querySelector('.ad-showing');				
            //There are no ads in this video
            if(!targetNode){
                //log(`There are no ads in this video`);
                return false;
            }

            //Listen to the advertisement in the video and process it
            const config = {childList: true, subtree: true };// Monitor the changes of the target node itself and the nodes under the subtree
            observer = new MutationObserver(skipAd);// Create an instance of the observer and set the callback function that handles the ad
            observer.observe(targetNode, config);// Start observing the ad node with the above configuration

            //Initialize monitoring, discover and process advertisements
            let skipButton = document.querySelector(`.ytp-ad-skip-button`);
            let shortAdMsg = document.querySelector(`.video-ads.ytp-ad-module .ytp-ad-player-overlay`);
			try{
				if(skipButton || shortAdMsg){
					log(`Initialize monitoring, discover and process advertisements`);
					skipAd();
				}else if(targetNode){
					log(`Initialize monitoring of ads`);
					skipAd();				
				}else{
					log(`Initialize monitoring, no advertisement found`);
				}
			}catch (e){
				console.log('An exception occurred checking for ads',e);
			}
        }

        //结束监听
        function closeObserve(){
            observer.disconnect();
            observer = null;
        }

        //轮询任务
        setInterval(function(){
            //视频播放页			
            if(getUrlParams(`v`) || getUrlParams(`vp`) || getUrlParams(`vpp`)){				 
                if(observer){
                    return false;
                }
                startObserve();
            }else{
                //其它界面
                if(!observer){
                    return false;
                }
                closeObserve();
            }
        },16);

        log(`Remove video ad script is running continuously`)
    }

    /**
    * main函数
    */
    function main(){		
        generateRemoveADHTMLElement(generateRemoveADCssText(cssSeletorArr),`removeAD`);//移除界面中的广告.
        removePlayerAD();//移除播放中的广告.				
    }

    if (document.readyState === `loading`) {
		addAdGuardLogo();
        log(`YouTube de-advertising script quick call:`);
        document.addEventListener(`DOMContentLoaded`, main);// 此时加载尚未完成
    } else {
		addAdGuardLogo();
        log(`YouTube de-advertising script quick call:`);
        main();// 此时`DOMContentLoaded` 已经被触发
    }

};
runBlockYoutube();