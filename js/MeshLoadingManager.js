/**
* @author Nelson Rosa Jr.
*
*
* BipedAnimation: class for keeping track of animation details
* Biped: class for housing a collection of models
* Model: class for describing kinematics and biped keyframes
* Joint: class for describing joints and links
*/

import { LoadingManager } from '../three/build/three.module.js';

export class MeshLoadingManager extends LoadingManager {
  constructor(resolve, reject) {
    super();

    let console = { log: () => {} };

    this.onStart = (url, loaded, total) => 
      console.log( `${loaded}/${total}: starting to load ${url}.` );

    this.onProgress = (url, loaded, total) => 
      console.log( `${loaded}/${total}: loaded ${url}.` );

    this.onLoad = () => {
      console.log( 'finished loading all items.' );
      resolve();
    };

    this.onError = url => {
      console.log( `error loading ${url}.` );
      reject();
    };
  }

  start(url) { this.itemStart( url ); }

  end(url, cb) {
    const self = this;
    setTimeout( () => {
      if(cb) cb(); 
      self.itemEnd( url );
    }, 0 );
  }
}
