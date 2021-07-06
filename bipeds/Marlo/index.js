import { MeshPhongMaterial, Mesh } from '../../three/build/three.module.js';
import { STLLoader } from '../../three/examples/jsm/loaders/STLLoader.js';

const path = './bipeds/Marlo/geometries/';

const parts = {};

function mesh(geometry, root, onLoad) {
  const geo = geometry.clone();
  const name = root.name;
  const color = root.userData.json.mesh.link.color;

  if(name === 'right_hip-ry') {
    geo.rotateZ( Math.PI );
  }
  else if(name === 'torso-rx') {
    geo.translate( 0.220, 0, 0.35 );
  }

  const mat = new MeshPhongMaterial( {
    color: color,
    specular: 0x111111,
    shininess: 200
  } );

  const mesh = new Mesh( geo, mat );
  onLoad( mesh );
}

export default class MarloSTLLoader extends STLLoader {
  constructor(manager) {
    super( manager );
    this.setPath( path );
  }

  load( root, onLoad, onProgress, onError) {
    const mngr = this.manager;
    const file = root.userData.json.mesh.file;
    const part = parts[file];

    mngr.start( file );

    if(!onLoad) {
      mngr.end( file, () => {} );
      return;
    }
    else if(!file)  {
      mngr.end( file, onLoad );
    }
    else if(part && part.geo) {
      mngr.end( file, () => mesh(part.geo, root, onLoad) );
    }
    else if(part) {
      part.callbacks.push( geo => mngr.end( file, mesh(geo, root, onLoad) ) );
    }
    else {
      const onload = geo => {
        geo.rotateX( Math.PI / 2 );
        geo.rotateZ( Math.PI / 2 );
        parts[file].geo = geo;

        const cbs = parts[file].callbacks;
        for(let load = cbs.pop(); load; load = cbs.pop()) load(geo);
      };

      parts[file] = { callbacks: [
        geo => mngr.end( file, mesh(geo, root, onLoad) )
      ] };

      super.load( file, onload, onProgress, onError );
    }
  }
}
