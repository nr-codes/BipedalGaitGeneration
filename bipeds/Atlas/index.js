import { ColladaLoader } from '../../three/examples/jsm/loaders/ColladaLoader.js';

const path = './bipeds/Atlas/meshes/';

export default class AtlasColladaLoader extends ColladaLoader {
  constructor(manager) {
    super( manager );
    this.setPath( path );
  }

  load( root, onLoad, onProgress, onError) {
    const file = root.userData.json.mesh.file;

    if(!file)  {
      // console.log( `No mesh file present for ${root.name}.` );
      if(onLoad) onLoad();
    }
    else {
      const onload = (dae) => {
        dae.scene.rotation.set( 0, 0, 0 );
        if(onLoad) onLoad( dae.scene );
      };
      
      super.load( file, onload, onProgress, onError );
    }
  }
}
