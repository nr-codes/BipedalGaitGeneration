import { Vector3 } from '../three/build/three.module.js';

const PLANAR = 2; // length of axes when planar

export class Axes {
    constructor(axes, name) { 
        this.name = name || '';
        this._axes = ['x', 'y', 'z'];
        this._up = new Vector3().set( 0, 0, 1 );
        this._planar = false;
        if(axes) this.setAxes( axes );
    }

    setName(name) {
        this.name = name;
        return this;
    }

    setAxes(axes) {
        let a = this._axes, p = axes.length === PLANAR;

        a[0] = axes[0];

        if(p) {
            // planar biped
            if(!axes.find( e => e === 'x' )) {
                a[1] = 'x';
            }
            else if(!axes.find( e => e === 'y' )) {
                a[1] = 'y';
            }
            else {
                a[1] = 'z';
            }

            a[2] = axes[1];
        }
        else {
            // 3D biped
            a[1] = axes[1];
            a[2] = axes[2];
        }

        this._planar = p;
        this._up.set( 0, 0, 0 );
        this._up[ this.b ] = 1;

        return this;
    }

    isPlanar() {
        return this._planar;
    }

    toString() {
        let name = `-- ${this.name} (${this._planar})`;
        return `Axis ${name}: [tangent, normal, binormal] = [${this._axes}]`;
    }

    get up() { return this._up; }

    // normal
    get n() { return this._axes[1]; }

    // tangent
    get t() { return this._axes[0]; }

    // binormal/tangent
    get b() { return this._axes[2]; }

    set axes(axes) { this.setAxes( axes ); }
}
