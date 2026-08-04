import{a as y}from"./js.cookie-Cz0CWeBA.js";import{C as re,a as ae,p as se,S as le,b as de,c as we,d as ce,e as ue,f as be}from"./sharedFrameEvents-0qZ2yOho.js";import{i as ge}from"./colorHelper-DkkSNPxc.js";import{g as he}from"./_commonjsHelpers-gnU0ypJ3.js";import"./index-DN3rM4CW.js";const me=`
:root {
  --b-100: #F2F3F7;
  --s-700: #37546D;
}

.woot-widget-holder {
  box-shadow: 0 5px 40px rgba(0, 0, 0, .16);
  opacity: 1;
  will-change: transform, opacity;
  transform: translateY(0);
  overflow: hidden !important;
  position: fixed !important;
  transition: opacity 0.2s linear, transform 0.25s linear;
  z-index: 2147483000 !important;
}

.woot-widget-holder.woot-widget-holder--flat {
  box-shadow: none;
  border-radius: 0;
  border: 1px solid var(--b-100);
}

.woot-widget-holder iframe {
  border: 0;
  color-scheme: normal;
  height: 100% !important;
  width: 100% !important;
  max-height: 100vh !important;
}

.woot-widget-holder.has-unread-view {
  border-radius: 0 !important;
  min-height: 80px !important;
  height: auto;
  bottom: 94px;
  box-shadow: none !important;
  border: 0;
}

.woot-widget-bubble {
  background: #000000;
  border-radius: 100px;
  border-width: 0px;
  bottom: 20px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, .16) !important;
  cursor: pointer;
  height: 64px;
  padding: 0px;
  position: fixed;
  user-select: none;
  width: 64px;
  z-index: 2147483000 !important;
  overflow: hidden;
}

.woot-widget-bubble.woot-widget-bubble--flat {
  border-radius: 0;
}

.woot-widget-holder.woot-widget-holder--flat {
  bottom: 90px;
}

.woot-widget-bubble.woot-widget-bubble--flat {
  height: 56px;
  width: 56px;
}

.woot-widget-bubble.woot-widget-bubble--flat svg {
  margin: 16px;
}

.woot-widget-bubble.woot-widget-bubble--flat.woot--close::before,
.woot-widget-bubble.woot-widget-bubble--flat.woot--close::after {
  left: 28px;
  top: 16px;
}

.woot-widget-bubble.unread-notification::after {
  content: '';
  position: absolute;
  width: 12px;
  height: 12px;
  background: #ff4040;
  border-radius: 100%;
  top: 0px;
  right: 0px;
  border: 2px solid #ffffff;
  transition: background 0.2s ease;
}

.woot-widget-bubble.woot-widget--expanded {
  bottom: 24px;
  display: flex;
  height: 48px !important;
  width: auto !important;
  align-items: center;
}

.woot-widget-bubble.woot-widget--expanded div {
  align-items: center;
  color: #fff;
  display: flex;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Oxygen-Sans, Ubuntu, Cantarell, Helvetica Neue, Arial, sans-serif;
  font-size: 16px;
  font-weight: 500;
  justify-content: center;
  padding-right: 20px;
  width: auto !important;
}

.woot-widget-bubble.woot-widget--expanded.woot-widget-bubble-color--lighter div{
  color: var(--s-700);
}

.woot-widget-bubble.woot-widget--expanded svg {
  height: 20px;
  margin: 14px 8px 14px 16px;
  width: 20px;
}

.woot-widget-bubble.woot-elements--left {
  left: 20px;
}

.woot-widget-bubble.woot-elements--right {
  right: 20px;
}

.woot-widget-bubble:hover {
  background: #000000;
  box-shadow: 0 8px 32px rgba(0, 0, 0, .4) !important;
}

.woot-widget-bubble svg {
  all: revert;
  height: 24px;
  margin: 20px;
  width: 24px;
}

.woot-widget-bubble.woot-widget-bubble-color--lighter path{
  fill: var(--s-700);
}

@media only screen and (min-width: 667px) {
  .woot-widget-holder.woot-elements--left {
    left: 20px;
 }
  .woot-widget-holder.woot-elements--right {
    right: 20px;
 }
}

.woot--close:hover {
  opacity: 1;
}

.woot--close::before, .woot--close::after {
  background-color: #fff;
  content: ' ';
  display: inline;
  height: 24px;
  left: 32px;
  position: absolute;
  top: 20px;
  width: 2px;
}

.woot-widget-bubble-color--lighter.woot--close::before, .woot-widget-bubble-color--lighter.woot--close::after {
  background-color: var(--s-700);
}

.woot--close::before {
  transform: rotate(45deg);
}

.woot--close::after {
  transform: rotate(-45deg);
}

.woot--hide {
  bottom: -100vh !important;
  top: unset !important;
  opacity: 0;
  visibility: hidden !important;
  z-index: -1 !important;
}

.woot-widget--without-bubble {
  bottom: 20px !important;
}
.woot-widget-holder.woot--hide{
  transform: translateY(40px);
}
.woot-widget-bubble.woot--close {
  transform: translateX(0px) scale(1) rotate(0deg);
  transition: transform 300ms ease, opacity 100ms ease, visibility 0ms linear 0ms, bottom 0ms linear 0ms;
}
.woot-widget-bubble.woot--close.woot--hide {
  transform: translateX(8px) scale(.75) rotate(45deg);
  transition: transform 300ms ease, opacity 200ms ease, visibility 0ms linear 500ms, bottom 0ms ease 200ms;
}

.woot-widget-bubble {
  transform-origin: center;
  will-change: transform, opacity;
  transform: translateX(0) scale(1) rotate(0deg);
  transition: transform 300ms ease, opacity 100ms ease, visibility 0ms linear 0ms, bottom 0ms linear 0ms;
}
.woot-widget-bubble.woot--hide {
  transform: translateX(8px) scale(.75) rotate(-30deg);
  transition: transform 300ms ease, opacity 200ms ease, visibility 0ms linear 500ms, bottom 0ms ease 200ms;
}

.woot-widget-bubble.woot-widget--expanded {
  transform: translateX(0px);
  transition: transform 300ms ease, opacity 100ms ease, visibility 0ms linear 0ms, bottom 0ms linear 0ms;
}
.woot-widget-bubble.woot-widget--expanded.woot--hide {
  transform: translateX(8px);
  transition: transform 300ms ease, opacity 200ms ease, visibility 0ms linear 500ms, bottom 0ms ease 200ms;
}
.woot-widget-bubble.woot-widget-bubble--flat.woot--close {
  transform: translateX(0px);
  transition: transform 300ms ease, opacity 10ms ease, visibility 0ms linear 0ms, bottom 0ms linear 0ms;
}
.woot-widget-bubble.woot-widget-bubble--flat.woot--close.woot--hide {
  transform: translateX(8px);
  transition: transform 300ms ease, opacity 200ms ease, visibility 0ms linear 500ms, bottom 0ms ease 200ms;
}
.woot-widget-bubble.woot-widget--expanded.woot-widget-bubble--flat {
  transform: translateX(0px);
  transition: transform 300ms ease, opacity 200ms ease, visibility 0ms linear 0ms, bottom 0ms linear 0ms;
}
.woot-widget-bubble.woot-widget--expanded.woot-widget-bubble--flat.woot--hide {
  transform: translateX(8px);
  transition: transform 300ms ease, opacity 200ms ease, visibility 0ms linear 500ms, bottom 0ms ease 200ms;
}

@media only screen and (max-width: 667px) {
  .woot-widget-holder {
    height: 100%;
    right: 0;
    top: 0;
    width: 100%;
 }

 .woot-widget-holder iframe {
    min-height: 100% !important;
  }


 .woot-widget-holder.has-unread-view {
    height: auto;
    right: 0;
    width: auto;
    bottom: 0;
    top: auto;
    max-height: 100vh;
    padding: 0 8px;
  }

  .woot-widget-holder.has-unread-view iframe {
    min-height: unset !important;
  }

 .woot-widget-holder.has-unread-view.woot-elements--left {
    left: 0;
  }

  .woot-widget-bubble.woot--close {
    bottom: 60px;
    opacity: 0;
    visibility: hidden !important;
    z-index: -1 !important;
  }
}

@media only screen and (min-width: 667px) {
  .woot-widget-holder {
    border-radius: 16px;
    bottom: 104px;
    height: calc(90% - 64px - 20px);
    max-height: 640px !important;
    min-height: 250px !important;
    width: 400px !important;
 }
}

.woot-hidden {
  display: none !important;
}
`,pe=()=>{const e=document.createElement("style");e.innerHTML=`${me}`,e.id="cw-widget-styles",e.dataset.turboPermanent=!0,document.body.appendChild(e)},T=(e,o)=>{const t=document.getElementById(e),d=o.querySelector(`#${e}`);t&&!d&&o.appendChild(t)},M=e=>{T("cw-bubble-holder",e),T("cw-widget-holder",e),T("cw-widget-styles",e)},C=(e,o)=>{e.classList.add(...o.split(" "))},_=(e,o)=>{e.classList.toggle(o)},$=(e,o)=>{e.classList.remove(...o.split(" "))},H=({referrerURL:e,referrerHost:o})=>{u.events.onLocationChange({referrerURL:e,referrerHost:o})},fe=()=>{let e=document.location.href;const o=document.location.host,t={childList:!0,subtree:!0};H({referrerURL:e,referrerHost:o});const d=document.querySelector("body");new MutationObserver(n=>{n.forEach(()=>{e!==document.location.href&&(e=document.location.href,H({referrerURL:e,referrerHost:o}))})}).observe(d,t)},U=["standard","expanded_bubble"],I=["standard","flat"],R=["light","auto","dark"],j=e=>U.includes(e)?e:U[0],Z=e=>j(e)===U[1],ve=e=>I.includes(e)?e:I[0],W=e=>e==="flat",q=e=>R.includes(e)?e:R[0],xe=({eventName:e,data:o=null})=>{let t;return typeof window.CustomEvent=="function"?t=new CustomEvent(e,{detail:o}):(t=document.createEvent("CustomEvent"),t.initCustomEvent(e,!1,!1,o)),t},E=({eventName:e,data:o})=>{const t=xe({eventName:e,data:o});window.dispatchEvent(t)},ye="M240.808 240.808H122.123C56.6994 240.808 3.45695 187.562 3.45695 122.122C3.45695 56.7031 56.6994 3.45697 122.124 3.45697C187.566 3.45697 240.808 56.7031 240.808 122.122V240.808Z",Q=document.getElementsByTagName("body")[0],v=document.createElement("div"),x=document.createElement("div"),O=document.createElement("button"),B=document.createElement("button");document.createElement("span");const Ce=e=>{if(Z(window.$chatwoot.type)){const o=document.getElementById("woot-widget--expanded__text");o.innerText=e}},Ee=({className:e,path:o,target:t})=>{let d=`${e} woot-elements--${window.$chatwoot.position}`;const c=document.createElementNS("http://www.w3.org/2000/svg","svg");c.setAttributeNS(null,"id","woot-widget-bubble-icon"),c.setAttributeNS(null,"width","24"),c.setAttributeNS(null,"height","24"),c.setAttributeNS(null,"viewBox","0 0 240 240"),c.setAttributeNS(null,"fill","none"),c.setAttribute("xmlns","http://www.w3.org/2000/svg");const n=document.createElementNS("http://www.w3.org/2000/svg","path");if(n.setAttributeNS(null,"d",o),n.setAttributeNS(null,"fill","#FFFFFF"),c.appendChild(n),t.appendChild(c),Z(window.$chatwoot.type)){const b=document.createElement("div");b.id="woot-widget--expanded__text",b.innerText="",t.appendChild(b),d+=" woot-widget--expanded"}return t.className=d,t.title="Open chat window",t},Se=e=>{e&&C(x,"woot-hidden"),C(x,"woot--bubble-holder"),x.id="cw-bubble-holder",x.dataset.turboPermanent=!0,Q.appendChild(x)},Be=e=>{u.events.onBubbleToggle(e),e?E({eventName:re}):(E({eventName:ae}),O.focus())},S=(e={})=>{const{toggleValue:o}=e,{isOpen:t}=window.$chatwoot;if(t===o)return;const d=o===void 0?!t:o;window.$chatwoot.isOpen=d,_(O,"woot--hide"),_(B,"woot--hide"),_(v,"woot--hide"),Be(d)},$e=()=>{x.addEventListener("click",S)},Te=()=>{const e=document.querySelector(".woot-widget-holder");C(e,"has-unread-view")},P=()=>{const e=document.querySelector(".woot-widget-holder");$(e,"has-unread-view")};var F={exports:{}},A={exports:{}},z;function Me(){return z||(z=1,(function(){var e="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",o={rotl:function(t,d){return t<<d|t>>>32-d},rotr:function(t,d){return t<<32-d|t>>>d},endian:function(t){if(t.constructor==Number)return o.rotl(t,8)&16711935|o.rotl(t,24)&4278255360;for(var d=0;d<t.length;d++)t[d]=o.endian(t[d]);return t},randomBytes:function(t){for(var d=[];t>0;t--)d.push(Math.floor(Math.random()*256));return d},bytesToWords:function(t){for(var d=[],c=0,n=0;c<t.length;c++,n+=8)d[n>>>5]|=t[c]<<24-n%32;return d},wordsToBytes:function(t){for(var d=[],c=0;c<t.length*32;c+=8)d.push(t[c>>>5]>>>24-c%32&255);return d},bytesToHex:function(t){for(var d=[],c=0;c<t.length;c++)d.push((t[c]>>>4).toString(16)),d.push((t[c]&15).toString(16));return d.join("")},hexToBytes:function(t){for(var d=[],c=0;c<t.length;c+=2)d.push(parseInt(t.substr(c,2),16));return d},bytesToBase64:function(t){for(var d=[],c=0;c<t.length;c+=3)for(var n=t[c]<<16|t[c+1]<<8|t[c+2],b=0;b<4;b++)c*8+b*6<=t.length*8?d.push(e.charAt(n>>>6*(3-b)&63)):d.push("=");return d.join("")},base64ToBytes:function(t){t=t.replace(/[^A-Z0-9+\/]/ig,"");for(var d=[],c=0,n=0;c<t.length;n=++c%4)n!=0&&d.push((e.indexOf(t.charAt(c-1))&Math.pow(2,-2*n+8)-1)<<n*2|e.indexOf(t.charAt(c))>>>6-n*2);return d}};A.exports=o})()),A.exports}var k,V;function K(){if(V)return k;V=1;var e={utf8:{stringToBytes:function(o){return e.bin.stringToBytes(unescape(encodeURIComponent(o)))},bytesToString:function(o){return decodeURIComponent(escape(e.bin.bytesToString(o)))}},bin:{stringToBytes:function(o){for(var t=[],d=0;d<o.length;d++)t.push(o.charCodeAt(d)&255);return t},bytesToString:function(o){for(var t=[],d=0;d<o.length;d++)t.push(String.fromCharCode(o[d]));return t.join("")}}};return k=e,k}/*!
 * Determine if an object is a Buffer
 *
 * @author   Feross Aboukhadijeh <https://feross.org>
 * @license  MIT
 */var L,X;function _e(){if(X)return L;X=1,L=function(t){return t!=null&&(e(t)||o(t)||!!t._isBuffer)};function e(t){return!!t.constructor&&typeof t.constructor.isBuffer=="function"&&t.constructor.isBuffer(t)}function o(t){return typeof t.readFloatLE=="function"&&typeof t.slice=="function"&&e(t.slice(0,0))}return L}var Y;function Fe(){return Y||(Y=1,(function(){var e=Me(),o=K().utf8,t=_e(),d=K().bin,c=function(n,b){n.constructor==String?b&&b.encoding==="binary"?n=d.stringToBytes(n):n=o.stringToBytes(n):t(n)?n=Array.prototype.slice.call(n,0):!Array.isArray(n)&&n.constructor!==Uint8Array&&(n=n.toString());for(var s=e.bytesToWords(n),g=n.length*8,i=1732584193,r=-271733879,l=-1732584194,a=271733878,w=0;w<s.length;w++)s[w]=(s[w]<<8|s[w]>>>24)&16711935|(s[w]<<24|s[w]>>>8)&4278255360;s[g>>>5]|=128<<g%32,s[(g+64>>>9<<4)+14]=g;for(var h=c._ff,m=c._gg,p=c._hh,f=c._ii,w=0;w<s.length;w+=16){var te=i,oe=r,ne=l,ie=a;i=h(i,r,l,a,s[w+0],7,-680876936),a=h(a,i,r,l,s[w+1],12,-389564586),l=h(l,a,i,r,s[w+2],17,606105819),r=h(r,l,a,i,s[w+3],22,-1044525330),i=h(i,r,l,a,s[w+4],7,-176418897),a=h(a,i,r,l,s[w+5],12,1200080426),l=h(l,a,i,r,s[w+6],17,-1473231341),r=h(r,l,a,i,s[w+7],22,-45705983),i=h(i,r,l,a,s[w+8],7,1770035416),a=h(a,i,r,l,s[w+9],12,-1958414417),l=h(l,a,i,r,s[w+10],17,-42063),r=h(r,l,a,i,s[w+11],22,-1990404162),i=h(i,r,l,a,s[w+12],7,1804603682),a=h(a,i,r,l,s[w+13],12,-40341101),l=h(l,a,i,r,s[w+14],17,-1502002290),r=h(r,l,a,i,s[w+15],22,1236535329),i=m(i,r,l,a,s[w+1],5,-165796510),a=m(a,i,r,l,s[w+6],9,-1069501632),l=m(l,a,i,r,s[w+11],14,643717713),r=m(r,l,a,i,s[w+0],20,-373897302),i=m(i,r,l,a,s[w+5],5,-701558691),a=m(a,i,r,l,s[w+10],9,38016083),l=m(l,a,i,r,s[w+15],14,-660478335),r=m(r,l,a,i,s[w+4],20,-405537848),i=m(i,r,l,a,s[w+9],5,568446438),a=m(a,i,r,l,s[w+14],9,-1019803690),l=m(l,a,i,r,s[w+3],14,-187363961),r=m(r,l,a,i,s[w+8],20,1163531501),i=m(i,r,l,a,s[w+13],5,-1444681467),a=m(a,i,r,l,s[w+2],9,-51403784),l=m(l,a,i,r,s[w+7],14,1735328473),r=m(r,l,a,i,s[w+12],20,-1926607734),i=p(i,r,l,a,s[w+5],4,-378558),a=p(a,i,r,l,s[w+8],11,-2022574463),l=p(l,a,i,r,s[w+11],16,1839030562),r=p(r,l,a,i,s[w+14],23,-35309556),i=p(i,r,l,a,s[w+1],4,-1530992060),a=p(a,i,r,l,s[w+4],11,1272893353),l=p(l,a,i,r,s[w+7],16,-155497632),r=p(r,l,a,i,s[w+10],23,-1094730640),i=p(i,r,l,a,s[w+13],4,681279174),a=p(a,i,r,l,s[w+0],11,-358537222),l=p(l,a,i,r,s[w+3],16,-722521979),r=p(r,l,a,i,s[w+6],23,76029189),i=p(i,r,l,a,s[w+9],4,-640364487),a=p(a,i,r,l,s[w+12],11,-421815835),l=p(l,a,i,r,s[w+15],16,530742520),r=p(r,l,a,i,s[w+2],23,-995338651),i=f(i,r,l,a,s[w+0],6,-198630844),a=f(a,i,r,l,s[w+7],10,1126891415),l=f(l,a,i,r,s[w+14],15,-1416354905),r=f(r,l,a,i,s[w+5],21,-57434055),i=f(i,r,l,a,s[w+12],6,1700485571),a=f(a,i,r,l,s[w+3],10,-1894986606),l=f(l,a,i,r,s[w+10],15,-1051523),r=f(r,l,a,i,s[w+1],21,-2054922799),i=f(i,r,l,a,s[w+8],6,1873313359),a=f(a,i,r,l,s[w+15],10,-30611744),l=f(l,a,i,r,s[w+6],15,-1560198380),r=f(r,l,a,i,s[w+13],21,1309151649),i=f(i,r,l,a,s[w+4],6,-145523070),a=f(a,i,r,l,s[w+11],10,-1120210379),l=f(l,a,i,r,s[w+2],15,718787259),r=f(r,l,a,i,s[w+9],21,-343485551),i=i+te>>>0,r=r+oe>>>0,l=l+ne>>>0,a=a+ie>>>0}return e.endian([i,r,l,a])};c._ff=function(n,b,s,g,i,r,l){var a=n+(b&s|~b&g)+(i>>>0)+l;return(a<<r|a>>>32-r)+b},c._gg=function(n,b,s,g,i,r,l){var a=n+(b&g|s&~g)+(i>>>0)+l;return(a<<r|a>>>32-r)+b},c._hh=function(n,b,s,g,i,r,l){var a=n+(b^s^g)+(i>>>0)+l;return(a<<r|a>>>32-r)+b},c._ii=function(n,b,s,g,i,r,l){var a=n+(s^(b|~g))+(i>>>0)+l;return(a<<r|a>>>32-r)+b},c._blocksize=16,c._digestsize=16,F.exports=function(n,b){if(n==null)throw new Error("Illegal argument "+n);var s=e.wordsToBytes(c(n,b));return b&&b.asBytes?s:b&&b.asString?d.bytesToString(s):e.bytesToHex(s)}})()),F.exports}var Ae=Fe();const ke=he(Ae),ee=["avatar_url","email","name"],Le=[...ee,"identifier_hash"],D=()=>{const e="cw_user_",{websiteToken:o}=window.$chatwoot;return`${e}${o}`},Ue=({identifier:e="",user:o})=>`${Le.reduce((d,c)=>`${d}${c}${o[c]||""}`,"")}identifier${e}`,De=(...e)=>ke(Ue(...e)),Oe=e=>ee.reduce((o,t)=>o||!!e[t],!1),N=(e,o,{expires:t=365,baseDomain:d=void 0}={})=>{const c={expires:t,sameSite:"Lax",domain:d};typeof o=="object"&&(o=JSON.stringify(o)),y.set(e,o,c)},G=["click","touchstart","keypress","keydown"],Ne=()=>{let e;try{e=new(window.AudioContext||window.webkitAudioContext)}catch{}return e},He=async(e="",o)=>{const t=Ne(),d=c=>{window.playAudioAlert=()=>{if(t){const n=t.createBufferSource();n.buffer=c,n.connect(t.destination),n.loop=!1,n.start()}}};if(t){const{type:c="dashboard",alertTone:n="ding"}=o||{},b=`${e}/audio/${c}/${n}.mp3`,s=new Request(b);fetch(s).then(g=>g.arrayBuffer()).then(g=>(t.decodeAudioData(g).then(d),new Promise(i=>i()))).catch(()=>{})}},J=(e,o="")=>N("cw_conversation",e,{baseDomain:o}),Ie=e=>{const o=de(new Date,1);N("cw_snooze_campaigns_till",Number(o),{expires:o,baseDomain:e})},u={getUrl({baseUrl:e,websiteToken:o}){return`${e}/widget?website_token=${o}`},createFrame:({baseUrl:e,websiteToken:o})=>{if(u.getAppFrame())return;pe();const t=document.createElement("iframe"),d=y.get("cw_conversation");let c=u.getUrl({baseUrl:e,websiteToken:o});d&&(c=`${c}&cw_conversation=${d}`),t.src=c,t.allow="camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;",t.id="chatwoot_live_chat_widget",t.style.visibility="hidden";let n=`woot-widget-holder woot--hide woot-elements--${window.$chatwoot.position}`;window.$chatwoot.hideMessageBubble&&(n+=" woot-widget--without-bubble"),W(window.$chatwoot.widgetStyle)&&(n+=" woot-widget-holder--flat"),C(v,n),v.id="cw-widget-holder",v.dataset.turboPermanent=!0,v.appendChild(t),Q.appendChild(v),u.initPostMessageCommunication(),u.initWindowSizeListener(),u.preventDefaultScroll()},getAppFrame:()=>document.getElementById("chatwoot_live_chat_widget"),getBubbleHolder:()=>document.getElementsByClassName("woot--bubble-holder"),sendMessage:(e,o)=>{u.getAppFrame().contentWindow.postMessage(`chatwoot-widget:${JSON.stringify({event:e,...o})}`,"*")},initPostMessageCommunication:()=>{window.onmessage=e=>{if(typeof e.data!="string"||e.data.indexOf("chatwoot-widget:")!==0)return;const o=JSON.parse(e.data.replace("chatwoot-widget:",""));typeof u.events[o.event]=="function"&&u.events[o.event](o)}},initWindowSizeListener:()=>{window.addEventListener("resize",()=>u.toggleCloseButton())},preventDefaultScroll:()=>{v.addEventListener("wheel",e=>{const o=e.deltaY,t=v.scrollHeight,d=v.offsetHeight,c=v.scrollTop;(c===0&&o<0||d+c===t&&o>0)&&e.preventDefault()})},setFrameHeightToFitContent:(e,o)=>{const t=u.getAppFrame(),d=o?`${e}px`:"100%";t&&t.setAttribute("style",`height: ${d} !important`)},setupAudioListeners:()=>{const{baseUrl:e=""}=window.$chatwoot;He(e,{type:"widget",alertTone:"ding"}).then(()=>G.forEach(o=>{document.removeEventListener(o,u.setupAudioListeners,!1)}))},events:{loaded:e=>{J(e.config.authToken,window.$chatwoot.baseDomain),window.$chatwoot.hasLoaded=!0;const o=y.get("cw_snooze_campaigns_till");u.sendMessage("config-set",{locale:window.$chatwoot.locale,position:window.$chatwoot.position,hideMessageBubble:window.$chatwoot.hideMessageBubble,showPopoutButton:window.$chatwoot.showPopoutButton,widgetStyle:window.$chatwoot.widgetStyle,darkMode:window.$chatwoot.darkMode,showUnreadMessagesDialog:window.$chatwoot.showUnreadMessagesDialog,campaignsSnoozedTill:o,welcomeTitle:window.$chatwoot.welcomeTitle,welcomeDescription:window.$chatwoot.welcomeDescription,availableMessage:window.$chatwoot.availableMessage,unavailableMessage:window.$chatwoot.unavailableMessage,enableFileUpload:window.$chatwoot.enableFileUpload,enableEmojiPicker:window.$chatwoot.enableEmojiPicker,enableEndConversation:window.$chatwoot.enableEndConversation}),u.onLoad({widgetColor:e.config.channelConfig.widgetColor}),u.toggleCloseButton(),window.$chatwoot.user&&u.sendMessage("set-user",window.$chatwoot.user),window.playAudioAlert=()=>{},G.forEach(t=>{document.addEventListener(t,u.setupAudioListeners,!1)}),window.$chatwoot.resetTriggered||E({eventName:ue})},error:({errorType:e,data:o})=>{E({eventName:ce,data:o}),e===le&&y.remove(D())},onEvent({eventIdentifier:e,data:o}){E({eventName:e,data:o})},setBubbleLabel(e){Ce(window.$chatwoot.launcherTitle||e.label)},setAuthCookie({data:{widgetAuthToken:e}}){J(e,window.$chatwoot.baseDomain)},setCampaignReadOn(){Ie(window.$chatwoot.baseDomain)},postback(e){E({eventName:we,data:e})},toggleBubble:e=>{let o={};e==="open"?o.toggleValue=!0:e==="close"&&(o.toggleValue=!1),S(o)},popoutChatWindow:({baseUrl:e,websiteToken:o,locale:t})=>{const d=y.get("cw_conversation");window.$chatwoot.toggle("close"),se(e,o,t,d)},closeWindow:()=>{S({toggleValue:!1}),P()},onBubbleToggle:e=>{u.sendMessage("toggle-open",{isOpen:e}),e&&u.pushEvent("webwidget.triggered")},onLocationChange:({referrerURL:e,referrerHost:o})=>{u.sendMessage("change-url",{referrerURL:e,referrerHost:o})},updateIframeHeight:e=>{const{extraHeight:o=0,isFixedHeight:t}=e;u.setFrameHeightToFitContent(o,t)},setUnreadMode:()=>{Te(),S({toggleValue:!0})},resetUnreadMode:()=>P(),handleNotificationDot:e=>{if(window.$chatwoot.hideMessageBubble)return;const o=document.querySelector(".woot-widget-bubble");e.unreadMessageCount>0&&!o.classList.contains("unread-notification")?C(o,"unread-notification"):e.unreadMessageCount===0&&$(o,"unread-notification")},closeChat:()=>{S({toggleValue:!1})},playAudio:()=>{window.playAudioAlert()}},pushEvent:e=>{u.sendMessage("push-event",{eventName:e})},onLoad:({widgetColor:e})=>{const o=u.getAppFrame();if(o.style.visibility="",o.setAttribute("id","chatwoot_live_chat_widget"),u.getBubbleHolder().length)return;Se(window.$chatwoot.hideMessageBubble),fe();let t="woot-widget-bubble",d=`woot-elements--${window.$chatwoot.position} woot-widget-bubble woot--close woot--hide`;W(window.$chatwoot.widgetStyle)&&(t+=" woot-widget-bubble--flat",d+=" woot-widget-bubble--flat"),ge(e)&&(t+=" woot-widget-bubble-color--lighter",d+=" woot-widget-bubble-color--lighter");const c=Ee({className:t,path:ye,target:O});C(B,d),c.style.background=e,B.style.background=e,x.appendChild(c),x.appendChild(B),$e()},toggleCloseButton:()=>{let e=!1;window.matchMedia("(max-width: 668px)").matches&&(e=!0),u.sendMessage("toggle-close-button",{isMobile:e})}},Re=({baseUrl:e,websiteToken:o})=>{if(window.$chatwoot)return;document.addEventListener("turbo:before-render",n=>{n.detail.renderMethod!=="morph"&&M(n.detail.newBody)}),window.Turbolinks&&document.addEventListener("turbolinks:before-render",n=>{M(n.data.newBody)}),document.addEventListener("astro:before-swap",n=>M(n.newDocument.body));const t=window.chatwootSettings||{};let d=t.locale,c=t.baseDomain;t.useBrowserLanguage&&(d=window.navigator.language.replace("-","_")),window.$chatwoot={baseUrl:e,baseDomain:c,hasLoaded:!1,hideMessageBubble:t.hideMessageBubble||!1,isOpen:!1,position:t.position==="left"?"left":"right",websiteToken:o,locale:d,useBrowserLanguage:t.useBrowserLanguage||!1,type:j(t.type),launcherTitle:t.launcherTitle||"",showPopoutButton:t.showPopoutButton||!1,showUnreadMessagesDialog:t.showUnreadMessagesDialog??!0,widgetStyle:ve(t.widgetStyle)||"standard",resetTriggered:!1,darkMode:q(t.darkMode),welcomeTitle:t.welcomeTitle||"",welcomeDescription:t.welcomeDescription||"",availableMessage:t.availableMessage||"",unavailableMessage:t.unavailableMessage||"",enableFileUpload:t.enableFileUpload,enableEmojiPicker:t.enableEmojiPicker??!0,enableEndConversation:t.enableEndConversation??!0,toggle(n){u.events.toggleBubble(n)},toggleBubbleVisibility(n){let b=document.querySelector(".woot--bubble-holder"),s=document.querySelector(".woot-widget-holder");n==="hide"?(C(s,"woot-widget--without-bubble"),C(b,"woot-hidden"),window.$chatwoot.hideMessageBubble=!0):n==="show"&&($(b,"woot-hidden"),$(s,"woot-widget--without-bubble"),window.$chatwoot.hideMessageBubble=!1),u.sendMessage(be,{hideMessageBubble:window.$chatwoot.hideMessageBubble})},popoutChatWindow(){u.events.popoutChatWindow({baseUrl:window.$chatwoot.baseUrl,websiteToken:window.$chatwoot.websiteToken,locale:d})},setUser(n,b){if(typeof n!="string"&&typeof n!="number")throw new Error("Identifier should be a string or a number");if(!Oe(b))throw new Error("User object should have one of the keys [avatar_url, email, name]");const s=D(),g=y.get(s),i=De({identifier:n,user:b});i!==g&&(window.$chatwoot.identifier=n,window.$chatwoot.user=b,u.sendMessage("set-user",{identifier:n,user:b}),N(s,i,{baseDomain:c}))},setCustomAttributes(n={}){if(!n||!Object.keys(n).length)throw new Error("Custom attributes should have atleast one key");u.sendMessage("set-custom-attributes",{customAttributes:n})},deleteCustomAttribute(n=""){if(n)u.sendMessage("delete-custom-attribute",{customAttribute:n});else throw new Error("Custom attribute is required")},setConversationCustomAttributes(n={}){if(!n||!Object.keys(n).length)throw new Error("Custom attributes should have atleast one key");u.sendMessage("set-conversation-custom-attributes",{customAttributes:n})},deleteConversationCustomAttribute(n=""){if(n)u.sendMessage("delete-conversation-custom-attribute",{customAttribute:n});else throw new Error("Custom attribute is required")},setLabel(n=""){u.sendMessage("set-label",{label:n})},removeLabel(n=""){u.sendMessage("remove-label",{label:n})},setLocale(n="en"){u.sendMessage("set-locale",{locale:n})},setColorScheme(n="light"){u.sendMessage("set-color-scheme",{darkMode:q(n)})},reset(){window.$chatwoot.isOpen&&u.events.toggleBubble(),y.remove("cw_conversation"),y.remove(D());const n=u.getAppFrame();n.src=u.getUrl({baseUrl:window.$chatwoot.baseUrl,websiteToken:window.$chatwoot.websiteToken}),window.$chatwoot.resetTriggered=!0}},u.createFrame({baseUrl:e,websiteToken:o})};window.chatwootSDK={run:Re};
//# sourceMappingURL=sdk-DAPX9WbH.js.map
