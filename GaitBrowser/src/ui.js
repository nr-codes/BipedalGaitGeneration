/**
 * @author Nelson Rosa Jr.
 *
 * Helper functions called within index.html
 */

import { animation } from './Animations.js';

const DEFAULT_DURATION = 4;

export function initGUI(clips) {
  let d, toggle;

  const keys = Object.keys( clips ).sort( compare );

  // set up bipeds in Gaits menu
  const roots = {}; // avoid adding extra events
  for(let k of keys) {
    const id = clips[k].action.getRoot().id;
    if(!roots[id]) {
      const mixer = clips[k].action.getMixer();
      mixer.addEventListener( 'finished', () => play( false ) );
      roots[id] = true;
    }
  }

  // add biped names to dropdown menu
  d = document.getElementById( "myDropdown" );
  while(d.hasChildNodes()) d.removeChild(d.lastChild);

  const c = o => {
    const button = document.createElement( 'button' );
    button.type = "button";
    button.onclick = e => playClip( e.target );
    button.innerHTML = o;
    d.appendChild( button );
  };

  keys.forEach( c );

  // add clips to shared object
  animation.clips = clips;
  playClip( keys[0] );

  // setup rest of UI
  toggleText();

  toggle = e => toggleDropdown( e.target );
  document.getElementById( "Gaits" ).onclick = toggle;
  document.getElementById( "myInput" ).onkeyup = e => filter( e.target );

  document.getElementById( "View" ).onclick = toggle;
  d = document.getElementById( "view-content" );
  for(let k of [ 'Default', 'Top', 'Side', 'Front', 'All Views' ]) {
    const button = document.createElement( 'button' );
    button.type = "button";
    button.onclick = e => setView( e.target );
    button.innerHTML = k;
    d.appendChild( button );
  }

  document.getElementById( "play" ).onclick = e => play( e.target );

  document.getElementById( "myRange" ).oninput = e => seek( e.target );
  document.getElementById( "myRange" ).onchange = e => seek( e.target );

  toggle = e => toggleSpeed( e.target );
  document.getElementById( "slow-fast-checkbox" ).onclick = toggle;

  toggle = e => toggleText( e.target );
  document.getElementById( "video-image-checkbox" ).onclick = toggle;

  document.getElementById( "save-button" ).onclick = e => saveImages();

  window.addEventListener( 'resize', animation.resizeCanvas, false );
  animation.resizeCanvas();
  requestAnimationFrame( animation.animate );
}

function compare(a, b) {
  let c, fig;

  c = 1; // assume b < a
  fig = /^Figure/i;

  if(a.match( fig ) && !b.match( fig )) {
    c = -1;
  }
  else if(!a.match( fig ) && b.match( fig )) {
    c = 1;
  }
  else if( a <= b ) {
    c = a === b ? 0 : -1;
  }

  return c;
}

function filter() {
  const input = document.getElementById("myInput");
  const filter = input.value.toUpperCase();
  const div = document.getElementById("myDropdown");
  const b = div.getElementsByTagName("button");
  for (let i = 0; i < b.length; i++) {
    const txt = b[i].textContent || b[i].innerText;
    if (txt.toUpperCase().indexOf(filter) > -1) {
      b[i].style.display = "";
    }
    else {
      b[i].style.display = "none";
    }
  }
}

function toggleDropdown(button) {
  let drop;

  // close open dropdowns, assumes prevSibling is dropdown button
  drop = document.getElementsByClassName( "show-dropdown-container" );

  for(let i = 0; i < drop.length; i++) {
    const b = drop[i].previousElementSibling;
    if(b === button) continue;
    drop[i].classList.remove( "show-dropdown-container" );
    b.innerHTML = b.id;
  }

  if(button) {
    drop = button.nextElementSibling;
    if(drop.classList.toggle( "show-dropdown-container" )) {
      // set button text to close character
      button.innerHTML = "&#x274C;"
    }
    else {
      // set button text to menu name
      button.innerHTML = button.id;
    }
  }
}

function toggleSpeed(o) {
  if(!o) o = document.getElementById( 'slow-fast-checkbox' );

  const action = animation.action;
  if(o.checked) {
    action.setDuration( DEFAULT_DURATION );
  }
  else {
    action.timeScale = 1;
  }
}

function toggleText(o) {
  toggleDropdown();

  if(!o) o = document.getElementById( 'video-image-checkbox' );
  const input = document.getElementById( 'images-input' );

  if(o.checked) {
    input.placeholder = "# of images";
  }
  else {
    input.placeholder = "# of frames";
  }
}

function play(p) {
  let play;

  toggleDropdown();

  const playURL = 'url("./css/playicon.svg")';
  const pauseURL = 'url("./css/pauseicon.svg")';

  if(typeof p === "boolean") {
    //set button
    play = p;
    p = document.getElementById( "play" );
  }
  else {
    // p is a button or undefined, toggle button
    if(!p) p = document.getElementById( "play" );
    play = p.style.backgroundImage === pauseURL;
  }

  animation.delay = play ? 0 : Infinity;

  // toggle button icon
  if(play) {
    p.style.backgroundImage = playURL;
    if(animation.paused) animation.action.reset().play();
  }
  else{
    p.style.backgroundImage = pauseURL;
  }
}

function seek(t) {
  play( false ); // pause icon
  animation.scaledTime = parseFloat( t.value );
  animation.update = 0;
}

function playClip(a) {
  let n;

  if(typeof a === 'string') {
    n = a;
  }
  else {
    n = a.textContent || a.innerText;
  }

  if(n === 'All Gaits in Paper') {

  }
  else {
    animation.current = n;
    animation.view = 'Default';
  }

  // update playback speeds
  toggleSpeed();
  document.getElementById( 'slow-fast-text' ).attributes["slow"].value =
    (DEFAULT_DURATION / animation.duration).toFixed(2) + "x";

  // close all dropdown menus
  toggleDropdown();

  // update slider (t = 0, button = play)
  document.getElementById("myRange").value = 0;
  document.getElementById( "info" ).innerHTML = n;
  play( true );
}

function setView(button) {
  animation.view = button.textContent || button.innerText;
  toggleDropdown();
  if(animation.delay === Infinity) play( true );
}

function disableInputs(disable) {
  const ui = [
    'video-image-checkbox',
    'images-input',
    'slow-fast-checkbox',
    'save-button',
    'myRange',
    'Gaits',
    'View',
    'play'
  ];

  for(let i = 0; i < ui.length; i++) {
    document.getElementById( ui[i] ).disabled = disable;
  }
}

function socketAnimate() {
  if(animation.saving) {
    requestAnimationFrame( socketAnimate );
    animation.scaledTime = animation.tic;
    animation.update = 0;

    animation.render();

    //const canvas = viewer.render( scene ).getImageCanvas();

    // send to server
    animation.send = {
      status: 'img',
      t: animation.scaledTime,
      img: animation.snapshot
    };
  }
  else {
    // send done message;
    animation.send = { status: 'done' };

    // reenable checkboxes and buttons and textfields
    play( false );
    requestAnimationFrame( animation.animate );
    disableInputs( false );
  }
}

function saveImages() {
  let n, fps;

  disableInputs( true );

  // get input
  n = document.getElementById( 'images-input' ).value;
  fps = false;

  if(n[0] === "@") {
    n = n.substring(1);
    fps = true;
  }

  n = parseInt(n);
  if(isNaN(n) || n <= 0) {
    console.warn( 'Invalid # of images: n =', n, '; n > 0.' );
    disableInputs( false );
    return;
  }

  const video = !document.getElementById( 'video-image-checkbox' ).checked;
  const name = animation.name;
  const T = animation.duration / animation.action.timeScale;

  if(fps) {
    // compute # of images based on @nn
    fps = n;
    n = fps * T;
  }
  else if(video) {
    // compute fps for video based on # of images
    fps = n / T;
  }
  else {
    // fps is ignored for # of images
    fps = 1;
  }

  n = Math.round( n );

  // setup up deltas, this should avoid race conditions on renderer
  animation.save = n;
  animation.send = { status: 'start', video: video, fps: fps, n: n };

  // start saving
  requestAnimationFrame( () => {
    // turn off rendering loop and reset timer
    seek( { value: 0 } );
    play( true );
    socketAnimate();
  } );
}
