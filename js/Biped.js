/**
* @author Nelson Rosa Jr.
*
*
* BipedAnimation: class for keeping track of animation details
* Biped: class for housing a collection of models
* Model: class for describing kinematics and biped keyframes
* Joint: class for describing joints and links
*/

import {
  Group,
  AnimationMixer,
  AnimationClip,
  LoopOnce,
  LoadingManager,
  Vector3,
  Box3
} from '../three/build/three.module.js';

import { GLTFExporter } from '../three/examples/jsm/exporters/GLTFExporter.js';

import { Axes } from './Axes.js';
import { MeshLoadingManager } from './MeshLoadingManager.js';
import DefaultMeshLoader from './DefaultMesh.js';

async function fetchJSON(file, model, joint) {
  // changed folder from biped/ to js/bipeds/ -NR 07/06/21
  let json = await (await fetch( './bipeds/' + file )).json();

  if(model) {
    json = json["models"].find( m => m.name === model );

    if(!json) {
      console.warn( `The model '${model}' does not exist in ${file}.` );
    }

    if(joint) {
      json = json["joints"].find( j => j.name === joint );

      if(!json) {
        console.warn(
          `The joint '${joint}' of model '${model}' does not exist in ${file}`
        );
      }
    }
  }

  return json;
}

class Base {
  constructor() {
    this.root = new Group();
    this.children = [];
  }

  add(child) {
    this.root.add( child.root );
    this.children.push( child );
  }

  async fetch(file, model, joint) {
    const json = await fetchJSON( file, model, joint );
    if(json) this.parse( json );
    return this;
  }

  parse(json, type, data) {
    const root = this.root;
    root.name = json.name;

    if(Array.isArray( data )) {
      data = Object.fromEntries( data.map( k => [k, json[k]] ) );
    }

    Object.assign( root.userData, { type: type, [`is${type}`]: true }, data );

    return this;
  }

  mesh() {
    return this.children.map( m => m.mesh( ...arguments ) );
  }

  toGLTF(opts) {
    const root = this.root;
    const exporter = new GLTFExporter();
    return new Promise( resolve => exporter.parse(
      root,
      gltf => {
        const json = JSON.stringify( { [root.name]: gltf } );
        resolve( new Blob( [ json ], { type: 'application/json' } ) );
      },
      opts
    ) );
  }
}

export class Biped extends Base {
  fetch(file) { return super.fetch( file ); }

  parse(jsonBiped) {
    super.parse( jsonBiped, 'Biped' );
    jsonBiped.models.forEach( m => this.add( new Model().parse( m ) ), this );

    return this;
  }

  mesh() {
    return Promise.all( super.mesh() );
  }

  boxes() {
    this.children.forEach( c => { c.root.userData.boxes = c.getBoxes(); } );
  }

  toGLTF(opts) {
    this.boxes();
    return super.toGLTF( opts );
  }
}

class Model extends Base {
  constructor() {
    super();
    this.axes = new Axes();
    this.clips = [];
    this.loader = '';
  }

  fetch(file, model) { return super.fetch( file, model ); }

  parse(jsonModel) {
    super.parse( jsonModel, 'Model', [ 'axes', 'clips', 'surfaces' ] );

    this.clips.splice(0, this.clips.length, ...jsonModel.clips );
    this.loader = jsonModel.loader || 'DefaultMesh.js';
    this.axes.setAxes( jsonModel.axes );

    // add joints
    jsonModel.joints.forEach( o => this.add( new Joint().parse( o ) ), this );

    // add joint to parent
    const joints = [ this.root ];
    this.children.forEach( j => {
      const root = j.root;
      const p = root.userData.json.parent;
      joints.push( root );
      joints[p].add( root );
    } );

    return this;
  }

  mesh() {
    const l = this.loader;
    const n = this.axes.isPlanar() ? this.axes.n : '';

    return new Promise( async (resolve, reject) => {
      const Loader = (l === 'DefaultMesh.js') ?  DefaultMeshLoader :
        (await import(/* webpackIgnore: true */ `../bipeds/${l}` )).default;

      const manager = new MeshLoadingManager( resolve, reject );
      super.mesh( new Loader( manager, n ) );
    } );
  }

  getBoxes(n) {
    const root = this.root;
     
    return this.clips.map( c => {
      const mixer = new AnimationMixer( root );
      const action = mixer.clipAction( AnimationClip.parse( c ) );
      const T = action.getClip().duration;

      // update bounding box
      action.stop().play(); // set t = 0
      if(!n) n = 20; // # of points for t \in [0, T]

      const box = new Box3();
      for(let i = 0; i <= n; i++) {
        action.time = (i / n) * T;
        mixer.update( 0 );
        box.expandByObject( root );
      }

      return { min: box.min, max: box.max };
    } );
  }

  static parseClips(model) {
    const mixer = new AnimationMixer( model.root );
    const clips = model.root.userData.clips;
    for(let i = 0; i < clips.length; i++) {
      clips[i] = mixer.clipAction( AnimationClip.parse( clips[i] ) );

      // stop after animation is done
      clips[i].setLoop( LoopOnce ).clampWhenFinished = true;
    }
  }

  static parseAxes(model) {
    const axes = model.root.userData.axes;
    model.root.userData.axes = new Axes( axes );
  }
}

class Joint extends Base {
  async fetch(file, model, joint) { return super.fetch( file, model, joint ); }

  parse(jsonJoint) {
    super.parse( jsonJoint, 'Joint', { json: jsonJoint } );

    const root = this.root;
    root.matrixAutoUpdate = false;
    root.matrix.fromArray( jsonJoint.value );

    return this;
  }

  mesh(loader) {
    const self = this;
    const onLoad = obj3d => { if(obj3d) self.root.add( obj3d ); };
    loader.load( self.root, onLoad );
  }
}
