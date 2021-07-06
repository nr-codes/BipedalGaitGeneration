/**
* @author Nelson Rosa Jr. 
*
*
* BipedAnimations: class for keeping track of animation details
*/

import {
  AnimationMixer,
  AnimationClip,
  LoopOnce,
  Box3,
  Clock,
  Scene,
  OrthographicCamera,
  WebGLRenderer,
  Vector3,
  Line3,
  Color,
  HemisphereLight,
  DirectionalLight,
  BoxBufferGeometry,
  MeshBasicMaterial,
  DoubleSide,
  Mesh,
  Plane,
  PlaneHelper,
  SphereBufferGeometry
} from '../three/build/three.module.js';

import { Line2 } from '../three/examples/jsm/lines/Line2.js';
import { LineGeometry } from '../three/examples/jsm/lines/LineGeometry.js';
import { LineMaterial } from '../three/examples/jsm/lines/LineMaterial.js';
import { GLTFLoader } from '../three/examples/jsm/loaders/GLTFLoader.js';
import { MeshLoadingManager } from './MeshLoadingManager.js';
import { Axes } from './Axes.js';
import { Biped } from './Biped.js';

const DELAY = 0.75;
const VIEW_HEIGHT = 0.55;
const COLORS = {
  Default: new Color( 1.0, 1.0, 1.0 ),
  Top: new Color( 0.5, 0.5, 0.7 ), 
  Side: new Color( 0.7, 0.5, 0.5 ),
  Front: new Color( 0.5, 0.7, 0.7 )
};

const NEAR = 1; // prefer to keep near plane fixed
const FAR_PAD = 1.01;

const snapshot = document.createElement( 'canvas' );
//snapshot.width = 1920;
//snapshot.height = 1080;

const container = document.getElementById( "container" );
const canvas = document.getElementById( "canvas" );
const myRange = document.getElementById("myRange");
const url = document.getElementById( "bundle" ).getAttribute( "data-url" );

const pixelRatio = window.devicePixelRatio;

const scene = new Scene();
const camera = new OrthographicCamera( -1, 1, 1, -1, NEAR, 10 );
const renderer = new WebGLRenderer( { canvas: canvas, antialias: true } );
const hemiLight = new HemisphereLight( 0x443333, 0x112222, 1 );
const sideLight = new DirectionalLight( 0xffffff, 1 );

/*
const surface = new Mesh( 
  new BoxBufferGeometry(1, 1, 1), 
  new MeshBasicMaterial( { color: 'black', side: DoubleSide } )
);
*/

const plane = new Plane();
const surface = new Line2( 
  new LineGeometry(), 
  new LineMaterial( { color: 'black', linewidth: 0.005 } )
);

const ground = new Line2( 
  new LineGeometry(), 
  new LineMaterial( { color: 'gray', linewidth: 0.0025 } )
);

ground.visible = false;

scene.add( hemiLight );
scene.add( sideLight );
scene.add( surface );
scene.add( ground );

// helper functions
//const surface2 = new PlaneHelper( plane, 10, 0 );
//scene.add( surface2 );

//renderer.setPixelRatio( window.devicePixelRatio );
//renderer.setSize( container.clientWidth - 1, container.clientHeight - 1 );

export class Animations {
  constructor() {
    this.clips = {};
    this.delay = 0;
    this.clock = new Clock();
    this.deltas = [];
    this.bipeds = [];
  }

  addBiped(biped) {
    if(biped.userData.isBiped) for(let c of biped.children) this.addModel( c );
  }

  addModel(model) {
    if(model.userData.isModel) {
      const mixer = new AnimationMixer( model );
      const a = new Axes( model.userData.axes );
      const c = model.userData.clips;
      const b = model.userData.boxes;
      const s = model.userData.surfaces;

      for(let i = 0; i < c.length; i++) {
        const box = new Box3( b[i].min, b[i].max );
        const action = mixer.clipAction( AnimationClip.parse( c[i] ) );
        action.setLoop( LoopOnce ).clampWhenFinished = true;
        this.addClip( c[i].name, action, box, a, s[i] );
      }
    }
  }

  addClip(name, action, box, axes, surface) {
    this.clips[ name ] = {
      action: action,
      box: box,
      axes: axes,
      surface: surface
    };
  }

  async fetch(onFetch) {
    const self = this;

    const bipeds = document.getElementById( "bundle" )
      .getAttribute( "data-bipeds").split(',');

    for(let k in self.clips) delete self.clips[k];

    await Promise.all( bipeds.map( async b => {
      const biped = await (new Biped().fetch( b ));
      await biped.mesh();
      biped.boxes();
      self.bipeds.push( biped );
      self.addBiped( biped.root );
      return Promise.resolve();
    } ) );

    if(onFetch) onFetch( this.clips );
  }
}

export class AnimationClock {
  constructor() {
    this.delay = 0;
    this.clock = new Clock();
    this.deltas = [];
  }

  setTimes(n) {
    const d = this.deltas;
    d.length = 0;

    if(n === 0) return;

    const m = n - 1;

    d.push( 0 );
    for(let i = 1; i < m; i++) {
      d.push( i / m );
    }

    if(n > 1) d.push( 1 );
  }

  setDeltas(T, n) {
    const d = this.deltas;
    d.length = 0;

    d.push( 0 );
    n--;
    if(n) {
      const dt = T / n;
      for(let i = 1; i <= n; i++) {
        d.push( dt );
      }
    }
  }

  getTime() {
    const n = this.deltas.length;
    const d = this.clock.getDelta();

    if(this.delay > 0) {
      this.delay -= d;
      return 0;
    }

    return n ? this.deltas.shift() : 1;
  }

  getDelta() {
    let d;

    const n = this.deltas.length;
    d = this.clock.getDelta();

    if(this.delay > 0) {
      this.delay -= d;
      d = 0;
    }
    else if(n) {
      d = this.deltas.shift();
    }

    return d;
  }
}

export const animation = {
  _name: '',
  _clips: {},
  _clock: new AnimationClock(),

  view: 'Default',

  resizeCanvas: resizeCanvas,
  animate: animate,
  render: render,
  splitView: splitView,

  set clips(clips) { this._clips = clips; },

  set current(name) {
    let action;
    this.delay = Infinity;

    // remove old action
    if(this._name) {
      action = this.action;
      action.stop();
      scene.remove( action.getRoot() );
    }

    // add new action
    this._name = name;
    action = this.action;
    action.stop().play();
    this.update = 0;
    scene.add( action.getRoot() );

    sideLight.target = action.getRoot();

    setCamera();
    updateSurface();

    this.delay = DELAY;
  },

  get current() { return this._clips[ this._name ]; },

  get action() { return this.current.action; },
  get paused() { return this.action.paused; },
  get duration() { return this.action.getClip().duration; },
  get time() { return this.action.time; },
  set scaledTime(t) { this.action.time = t * this.duration; },
  get scaledTime() { return this.time / this.duration; },
  set update(delta) { this.action.getMixer().update( delta ); },

  //get width() { return (container.clientWidth - 1); // * pixelRatio; },
  //get height() { return (container.clientHeight - 1); // * pixelRatio; },
  get width() { return (container.clientWidth - 1); },
  get height() { return (container.clientHeight - 1); },
  get ratio() {
    const w = this.width;
    const h = this.height;
    return h > 0 ? w / h : 0;
  },

  get axes() { return this.current.axes; },
  get box() { return this.current.box; },
  get surface() { return this.current.surface; },

  set delay(delay) { this._clock.delay = delay; },

  set save(n) { this._clock.setTimes( n ); },
  get saving() { return this._clock.deltas.length > 0; },
  get tic() { return this._clock.getTime(); },
  get delta() { return this._clock.getDelta(); },

  set send(o) { socket( Object.assign( { name: this._name }, o ) ); },
  get snapshot() {
    const src = canvas;
    const sw = src.width;
    const sh = src.height;

    snapshot.width = sw;
    snapshot.height = sh;

    const dst = snapshot;
    const dw = dst.width;
    const dh = dst.height;

    const r = Math.min ( dw / sw, dh / sh);
    const x = (dw - sw * r) / 2;
    const y = (dh - sh * r) / 2;  

    const ctx = dst.getContext( '2d' );
    ctx.clearRect( 0, 0, dw, dh );
    ctx.drawImage(src, 0, 0, sw, sh, x, y, sw * r, sh * r);

    return dst.toDataURL().split( ',' )[1];
  },

  get scene() { return scene; },
  get camera() { return camera; },
  get renderer() { return renderer; },
  get hemisphereLight() { return hemiLight; }
};

function resizeCanvas() {
  renderer.setSize( animation.width, animation.height, false );
  setCamera();
}

function viewAxes(view) {
  let n, t, b;

  const axes = animation.axes;
  const box = animation.box;
  const size = box.getSize( new Vector3() );

  n = view || animation.view; // normal direction to the plane
  switch(n) {
    case 'Top':
      n = '+' + axes.b;
      break;
    case 'Side':
      n = '+' + axes.n;
      break;
    case 'Front':
      n = '+' + axes.t;
      break;
    case 'All Views':
    case 'Default':
      n = axes.n;
      break;
      // default: leave n unchanged
  }

  if(axes.isPlanar() && n === 'y') {
    // 2D motion
    n = '-y';
  }
  else if(is3D) {
    // 3D motion
    const t = n === 'x' ? 'y' : 'x'; // width direction in plane
    p[t] = s[t] / 2;
  }

  return { t: t, n: n, b: b };
}

function getEye(view) {
  let a, n, p;

  const b = animation.box;
  a = animation.axes;
  const is3D = !a.isPlanar();

  const s = b.getSize( new Vector3() );
  p = new Vector3(); // midpoint of widest face

  n = view || animation.view; // normal direction to the plane
  switch(n) {
    case 'Top':
      n = '+' + a.b;
      break;
    case 'Side':
      n = '+' + a.n;
      break;
    case 'Front':
      n = '+' + a.t;
      break;
    case 'All Views':
    case 'Default':
      n = a.n;
      break;
      // default: leave n unchanged
  }

  if(n.length > 1) {
    // plane and view defined, e.g., +x, -z, etc. 
    a = n[0] === '-' ? -1 : 1;
    n = n[1];
  }
  else {
    // 2D motion
    a = n === 'y' ? -1 : 1; // x => (y, z), y => (x, z), z => (x, y)

    // 3D motion
    if(is3D) {
      const t = n === 'x' ? 'y' : 'x'; // width direction in plane
      p[t] = s[t] / 2;

      const b = n === 'z' ? 'y' : 'z'; // height direction in plane
      p[b] = s[b] / 40; // random value that looks nice for certain models
    }
  }

  p[n] = a * s[n] / 2;

  return p;
}

function setCamera(view, ratio) {
  let w, h, pad;

  if(!ratio) ratio = animation.ratio;
 
  const a = animation.axes;
  const b = animation.box;
  const s = b.getSize( new Vector3() );

  const p = getEye( view );
  const c = b.getCenter( new Vector3() );
  const r = new Line3( c, p.add( c ) );

  const e = r.distance(); // half width of far plane
  const d = NEAR;  // distance from camera to box edge
  const t = (d + e) / e; // distance from camera to box center

  // TODO for 3D this w isn't the width of the box, should compute new w
  w = s[ a.t ];
  h = s[ a.b ];

  // get tightest bounding box w/ correct aspect ratio
  pad = 1.1; // well add a little padding
  h = pad * Math.max( h, w / ratio );
  w = h * ratio;

  w /= 2;
  h /= 2;

  camera.near = NEAR;
  camera.far = d + (2 + FAR_PAD) * e; // have near/far sandwich bounding box
  camera.top = h;
  camera.bottom = -h;
  camera.left = -w;
  camera.right = w;
  camera.position.copy( r.at( t, new Vector3() ) );
  camera.up.copy( a.up );
  camera.lookAt( c );
  camera.updateProjectionMatrix();
  camera.updateMatrixWorld();

  hemiLight.position.copy( a.up );
  sideLight.position.copy( camera.position );
}

// TODO delete eventually
const sphere = new Mesh( 
  new SphereBufferGeometry( 0.01, 64, 64 ),
  new MeshBasicMaterial( {color: 0x00ff00} )
);

//scene.add( sphere );

function updateSurface() {
  let angle, w, h;
  const a = animation.axes;
  const s = animation.surface;
  const box = animation.box;
  const size = box.getSize( new Vector3() );
  const positions = [];
  const line = new Line3();
  const target = new Vector3();

  sphere.position.fromArray( s.o );
  sphere.updateMatrixWorld();

  plane.normal.fromArray( s.n );
  plane.constant = s.c;
  plane.normalize();

  // determine which direction plane intersects line best
  // if 45 <= angle <= 135 degrees, go along box sides of binormal direction
  angle = a.up.dot( plane.normal );
  angle = angle <= -Math.SQRT1_2 || angle >= Math.SQRT1_2;
  w = angle ? a.t : a.b;
  h = angle ? a.b : a.t;

  // start at bottom-most corner
  line.start.copy( box.min );
  line.end.copy( box.min );

  // make sure line is longer than box for intersection function
  line.start[ h ] -= size[ h ];
  line.end[ h ] += 2 * size[ h ];

  // point 1: start drawing plane at bottom-most corner
  plane.intersectLine( line, target );
  positions.push( ...target.toArray() );

  // point 2: end point of back line in step direction
  line.start[ w ] += size[ w ];
  line.end[ w ] += size[ w ];
  plane.intersectLine( line, target );
  positions.push( ...target.toArray() );

  if(a.isPlanar()) {
    const c = box.getCenter( new Vector3() );
    const o = new Vector3().fromArray( s.o );
    const p = [];

    o[ a.n ] = c[ a.n ] - FAR_PAD * size[ a.n ] / 2;
    o[ a.t ] = c[ a.t ] - size[ a.t ] / 2;
    p.push( ...o.toArray() );

    o[ a.t ] += size[ a.t ];
    p.push( ...o.toArray() );

    ground.geometry.setPositions( p );
    ground.visible = true;

    // need to have same length as 3D plane for 3D plane to render correctly
    positions.push( ...target.toArray() );
    positions.push( ...target.toArray() );
    positions.push( ...target.toArray() );

  }
  else{
    ground.visible = false;

    // point 3: end point of right-most corner of front line
    line.start[ a.n ] += size[ a.n ];
    line.end[ a.n ] += size[ a.n ];
    plane.intersectLine( line, target );
    positions.push( ...target.toArray() );

    line.start[ w ] -= size[ w ];
    line.end[ w ] -= size[ w ];
    plane.intersectLine( line, target );
    positions.push( ...target.toArray() );

    // point 5: finish loop back to start
    line.start[ a.n ] -= size[ a.n ];
    line.end[ a.n ] -= size[ a.n ];
    plane.intersectLine( line, target );
    positions.push( ...target.toArray() );
  }

  surface.geometry.setPositions( positions );
}

function splitView(view) {
  let left, bottom, width, height;

  if(!view) {
    left = 0;
    height = 1;
    bottom = 0;
    width = 1;
    view = animation.view;
  }
  else if(view === 'Default') {
    left = 0;
    height = VIEW_HEIGHT;
    bottom = 1 - height;
    width = 1;
  }
  else {
    if(view === 'Top') {
      left = 0;
    }
    else if(view === 'Side') {
      left = 1 / 3;
    }
    else { // view === 'Front'
      left = 2 / 3;
    }

    height = 1 - VIEW_HEIGHT;
    bottom = 0;
    width = 1 / 3;
  }

  left = Math.floor( animation.width * left );
  bottom = Math.floor( animation.height * bottom );
  width = Math.floor( animation.width * width );
  height = Math.floor( animation.height * height);

  setCamera( view, width / height );

  renderer.setViewport( left, bottom, width, height );
  renderer.setScissor( left, bottom, width, height );
  renderer.setScissorTest( true );
  renderer.setClearColor( COLORS[view] );
}

function render() {
  myRange.value = animation.scaledTime;

  if(animation.view === 'All Views' ) {
    for(let i of [ 'Default', 'Top', 'Side', 'Front' ]) {
      splitView( i );
      renderer.render(scene, camera);
    }
  }
  else {
    splitView();
    renderer.render(scene, camera);
  }
}

function socket(obj) {
  const b = new Blob( [ JSON.stringify( obj ) ], { type: 'application/json' } );
  const socket = new WebSocket( url );

  socket.onopen = e => socket.send( b );
  socket.onerror = e => console.error( e );
  socket.onmessage = e => socket.close();
}

function animate() {
  if(animation.saving) return;
  requestAnimationFrame( animate );
  animation.update = animation.delta;
  render();
}
