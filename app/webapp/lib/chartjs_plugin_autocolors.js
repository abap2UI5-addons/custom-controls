/*!
 * chartjs-plugin-autocolors v0.5.1
 * https://github.com/kurkle/chartjs-plugin-autocolors#readme
 * (c) 2026 Jukka Kurkela <jukka.kurkela@gmail.com>
 * Released under the MIT license
 */
!function(t,o){"object"==typeof exports&&"undefined"!=typeof module?module.exports=o():"function"==typeof define&&define.amd?define(o):(t="undefined"!=typeof globalThis?globalThis:t||self)["chartjs-plugin-autocolors"]=o()}(this,function(){
"use strict";
/*!
 * @kurkle/color v0.0.0-development
 * https://github.com/kurkle/color#readme
 * (c) 2026 Jukka Kurkela
 * Released under the MIT License
 */function t(t){return t+.5|0}var o=(t,o,e)=>Math.max(Math.min(t,e),o);function e(e){return o(t(255*e),0,255)}function r(t,o,e){const r=(r,n=(r+t/60)%6)=>e-e*o*Math.max(Math.min(n,4-n,1),0);return[r(5),r(3),r(1)]}function n(t,o,n){
return a=r,d=t,u=o,c=n,(Array.isArray(d)?a(d[0],d[1],d[2]):a(d,u,c)).map(e);var a,d,u,c}function a(e){return e&&(e.a<255?`rgba(${e.r}, ${e.g}, ${e.b}, ${function(e){return o(t(e/2.55)/100,0,1)}(e.a)})`:`rgb(${e.r}, ${e.g}, ${e.b})`)}
function d(t,o,e,r){return"data"===r?(t.backgroundColor=o,t.borderColor=e):(t.backgroundColor=t.backgroundColor||o,t.borderColor=t.borderColor||e),t.backgroundColor===o&&t.borderColor===e}function u(t,o,e){const r=t.next().value;
return"function"==typeof o?o(Object.assign({colors:r},e)):r}return{beforeUpdate(t,o,e){const{mode:r="dataset",enabled:c=!0,customize:f,repeat:l}=e;if(!c)return;const s=function*(t=1){const o=function*(){for(yield 0;;)for(let t=1;t<10;t++){
const o=1<<t;for(let t=1;t<=o;t+=2)yield t/o}}();let e=o.next();for(;!e.done;){let r=n(Math.round(360*e.value),.6,.8);for(let o=0;o<t;o++)yield{background:a({a:192,b:r[2],g:r[1],r:r[0]}),border:a({a:144,b:r[2],g:r[1],r:r[0]})};r=n(Math.
round(360*e.value),.6,.5);for(let o=0;o<t;o++)yield{background:a({a:192,b:r[2],g:r[1],r:r[0]}),border:a({a:144,b:r[2],g:r[1],r:r[0]})};e=o.next()}}(l);if(e.offset)for(let t=0;t<e.offset;t++)s.next();return"label"===r?function(t,o,e,r){
const n={};for(const a of t.data.datasets){const c=a.label??"";n[c]||(n[c]=u(o,e,{chart:t,dataIndex:void 0,datasetIndex:0,label:c}));const f=n[c];d(a,f.background,f.border,r)}}(t,s,f,r):function(t,o,e,r){const n="dataset"===r;let a=u(o,e,{
chart:t,dataIndex:n?void 0:0,datasetIndex:0});for(const c of t.data.datasets)if(n)d(c,a.background,a.border,r)&&(a=u(o,e,{chart:t,datasetIndex:c.index}));else{const n=[],f=[];for(let r=0;r<c.data.length;r++)n.push(a.background),f.push(a.
border),a=u(o,e,{chart:t,dataIndex:r,datasetIndex:c.index});d(c,n,f,r)}}(t,s,f,r)},id:"autocolors"}});

