import { Cache } from 'three';

import { initGUI } from './ui.js';
import { Animations } from './Animations.js';

Cache.enabled = true;

const animations = new Animations();
animations.fetch( initGUI );

/*

For images and videos make screen size (w + 1) x (h + 101), I think, e.g., 
1920 x 1080 => 1921 x 1181

*/
