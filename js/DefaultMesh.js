import {
  BufferGeometry,
  BufferAttribute,
  PointsMaterial,
  Points,
  CylinderBufferGeometry,
  MeshBasicMaterial,
  Mesh,
  DoubleSide,
  EdgesGeometry,
  LineBasicMaterial,
  LineSegments,
  Vector3,
  Matrix4,
  Quaternion,
  Group,
  Object3D,
  Box3,
  PlaneBufferGeometry,
  BoxBufferGeometry,
  ConeBufferGeometry,
  Shape,
  ShapeBufferGeometry,
  CurvePath,
  CubicBezierCurve3,
  DefaultLoadingManager
} from '../three/build/three.module.js';

/*
import {
  BufferGeometryUtils
} from 'three/examples/jsm/utils/BufferGeometryUtils.js';
*/

export default class DefaultMeshLoader {
  constructor(manager, planarize) {
    const w = 0.05;
    this.defaults = {
      link: { width: w, minLength: 10e-4, n: 50 },
      joint: { radius: w / 2, height: 1.1 * w },
      edge: { color: 'black' }
    };

    this.manager = manager || DefaultLoadingManager;

    this.planarize = planarize;
  }

  setMeshData(mesh, name, type, root) {
    const data = { type: type, [`is${type}`]: true };
    mesh.name = name;
    Object.assign( mesh.userData, data );
  }

  load(root, onLoad, onProgess, onError) {
    const manager = this.manager;
    const url = `Mesh: ${root.name}`;
    manager.itemStart( url );

    const mesh = this.parse( root );
    setTimeout( () => { // from THREE.FileLoader
      if(onLoad) onLoad( mesh );
      manager.itemEnd( url )
    }, 0 );
  }

  parse(root) {
    let mesh;

    const dof = root.userData.json.dof;
    switch( dof ) {
      case 'rx':
      case 'ry':
      case 'rz':
        mesh = this.parseJoint( root );
        break;

      case 'px':
      case 'py':
      case 'pz':
      case 'poi':
      case 'poi-flat':
        mesh = this.parsePoint( root );
        break;

      case 'poi-circ':
        mesh = this.parsePOICirc( root );
        break;

      default:
        console.warn( 'invalid dof parameter: ' + dof );
    };

    const links = this.parseLink( root ).filter( r => !!r );
    if(links.length) {
      if(!mesh) mesh = links.shift();
      mesh.add( ...links );
    }

    return mesh;
  }

  parsePoint(root) {
    const json = root.userData.json;
    const joint = json.mesh.joint;
    if(!joint || joint.color === undefined) return;

    // draw point
    const v = new Float32Array( 3 ); // 1 point * 1 vertex * 3 coords
    const g = new BufferGeometry();
    g.setAttribute( 'position', new BufferAttribute( v, 3 ) );
    planarize( root.name, g, this.planarize );

    const m = new PointsMaterial( { color: joint.color } );
    const p = new Points( g, m );
    this.setMeshData( p, json.dof, 'PointMesh', root );

    return p;
  }

  parseJoint(root) {
    let g, m;

    const json = root.userData.json;
    const joint = json.mesh.joint;

    if(!joint || joint.color === undefined) return;

    // draw joint
    const defaults = this.defaults;
    const r = joint.radius || defaults.joint.radius;
    const h = joint.height || defaults.joint.height;
    g = new CylinderBufferGeometry( r, r, h, 30 );

    // set color and orientation of joint
    switch(json.dof) {
      case 'rx':
        g.rotateZ( -Math.PI / 2 );
        break;
      case 'ry':
        break;
      case 'rz':
        g.rotateX( Math.PI / 2 );
        break;
      default:
        console.warn( 'invalid dof parameter: ' + json.dof );
    }

    planarize( root.name, g, this.planarize );

    m = new MeshBasicMaterial( { color: joint.color } );

    const j = new Mesh(g, m);
    this.setMeshData( j, json.dof, 'JointMesh', root );

    // draw top and bottom edges of joint in black
    g = new EdgesGeometry( g, 90 );
    m = new LineBasicMaterial( { color: defaults.edge.color } );
    j.add( new LineSegments( g, m ) );

    return j;
  }

  parsePOICirc(root) {
    let g, m, theta;

    const json = root.userData.json;
    const joint = json.mesh.joint;

    if(!joint || joint.color === undefined) return;

    // draw joint
    const defaults = this.defaults;
    const r = joint.radius || defaults.joint.radius;
    const h = joint.height || defaults.joint.height;

    // set orientation of joint
    const parent = root.parent.userData.json.dof;
    switch(parent) {
      case 'rx':
        theta = -Math.PI / 2;
        break;
      case 'rz':
        theta = Math.PI / 2;
        break;
      default /* or 'ry' */:
        theta = 0;
    }

    g = new CylinderBufferGeometry( r, r, h, 30, 4, false,
      theta + Math.PI, Math.PI );

    switch(parent) {
      case 'rx':
        g.rotateZ( theta );
        break;
      case 'ry':
        break;
      case 'rz':
        g.rotateX( theta );
        break;
      default:
        console.warn( 'invalid dof parameter: ' + parent );
    }

    planarize( root.name, g, this.planarize );

    m = new MeshBasicMaterial( { color: joint.color } );

    const j = new Mesh(g, m);
    this.setMeshData( j, json.dof, 'POICircMesh', root );

    // draw top and bottom edges of joint in black
    g = new EdgesGeometry( g, 90 );
    m = new LineBasicMaterial( { color: defaults.edge.color } );
    j.add( new LineSegments( g, m ) );

    return j;
  }

  parseLink(root) {
    const defaults = this.defaults;
    const axis = this.planarize;
    const rjson = root.userData.json;
    const dof = rjson.dof;
    const name = root.name;

    const rwidth = rjson.mesh.link ? rjson.mesh.link.width : 0;
    const w = rwidth || defaults.link.width;
    const d = new Vector3( w, w, w );
    const p = new Vector3();

    const linkCap = new LinkCap().setBox( d ).setDOF( dof );
    const link = new Link().start( linkCap );

    return root.children.map( c => {
        let m, g, ldata;

        const data = c.userData;
        if(!data.isJoint) return;

        const json = data.json;

        ldata = json.mesh.link;
        if(!ldata || ldata.color === undefined) return;

        const M = c.matrix;
        p.setFromMatrixPosition( M );
        // don't draw tiny links
        if(p.length() <= defaults.link.minLength) return;

        const e = new LinkCap().setBox( d ).setWorld( M ).setDOF( json.dof );
        g = link.getLinkBufferGeometry( e, defaults.link.n );
        planarize( name, g, axis );

        m = new MeshBasicMaterial( { color: ldata.color, side: DoubleSide } );

        const l = new Mesh( g, m );
        this.setMeshData( l, `${root.name} > ${c.name}`, 'LinkMesh', root );

        // draw edges of link
        g = new EdgesGeometry( g, 35 );
        m = new LineBasicMaterial( { color: defaults.edge.color } );
        l.add( new LineSegments( g, m ) );

        return l;
    }, this );
  }
}

class Link {
  constructor() {
    this.p0 = new LinkCap();
    this.curveType = 'bezier';
    this.d = [ 1, 1 ];  // 1 unit = length of normal direction
  }

  setCurveType(s) {
    this.curveType = s;  // 'bezier' or 'line'
    return this;
  }

  start(o) {
    this.p0.set( o );
    return this;
  }

  clearLinks() {
    this.curve.curves.length = 0;
    this.curve.updateArcLengths();
    return this;
  }

  getCurvesConnectingCorners(e) {
    let i, j, k, c;

    const s = this.p0;
    const d = this.d;
    const cT = this.curveType;
    const curve = new CurvePath();

    // must call before sc/ec
    const min = s.getNearestBottomRightCornerTo( e ); // face has been set

    const sc = s.getCorners();
    const sd = s.getCorners( d[0] );

    const ec = e.getCorners();
    const ed = e.getCorners( d[1] );

    // add edges starting from their bottom-right corners
    const n = sc.length; // num corners
    for(k = 0; k < n; k++) {
      i = (min[0] + k) % n;
      j = (min[1] - k) % n;

      if(i < 0) i += n;
      if(j < 0) j += n;

      if(cT === 'bezier') {
        c = new CubicBezierCurve3( sc[i], sd[i], ed[j], ec[j] );
      }
      else { // 'line'
        c = new CurvePath();
        c.add( new LineCurve3( sc[i], sd[i] ) );
        c.add( new LineCurve3( sd[i], ed[j] ) );
        c.add( new LineCurve3( ed[j], ec[j] ) );
      }

      curve.add( c );
    }

    // curves are ordered: [ bot-right, top-right, top-left, bot-left ]
    return curve;
  }

  getLinkBufferGeometry(o, n) {
    let uv, i, j, k, u, u0, u1, v0, v1, va, vb, vc, vd;

    const s = this.p0;
    const e = new LinkCap().set( o );
    const c = this.getCurvesConnectingCorners( e ).curves;

    if(!n) n = 5; // num points exclusive
    const m = c.length;

    const vert = [];
    uv = [];
    const ind = [];
    const geo = new BufferGeometry();

    // TODO fix below comment (???)
    // curves form sides:
    // (0, 1) -> bot-right, (1, 2) -> top-right,
    // (2, 3) -> top-left, (3, 0) -> bot-left

    // TODO: simplify vertices to only use indices
    // duplicate edges to add multiple norms
    for(j = 0; j < m; j++) {
      k = j + 1;

      v0 = j / m;
      v1 = k / m;

      if(k === m) k = 0;

      for(u = 0; u < n; u++) {
        u0 = u / n;
        u1 = (u + 1) / n;

        va = c[j].getPointAt( u0 );
        vb = c[j].getPointAt( u1 );
        vc = c[k].getPointAt( u0 );
        vd = c[k].getPointAt( u1 );

        if(j < 2) {
          vert.push( va, vc, vb, vc, vd, vb );
          uv.push( u0, v0, u0, v1, u1, v0, u0, v1, u1, v1, u1, v0 );
        }
        else {
          vert.push( vd, vb, vc, vb, va, vc );
          uv.push( u1, v1, u1, v0, u0, v1, u1, v0, u0, v0, u0, v1 );
        }
      }
    }

    for(i = 0; i < vert.length; i++) {
      ind.push(i);
    }

    uv = new BufferAttribute( new Float32Array( uv ), 2 );

    // create mesh
    geo.setIndex( ind );
    geo.setFromPoints( vert );
    geo.setAttribute( 'uv', uv );
    geo.computeVertexNormals();

    k = [ s.getCap(), geo, e.getCap() ];
    return mergeBufferGeometries( k );
  }
}

class LinkCap {
  constructor() {
    this.W = new Matrix4();
    this.axes = new Vector3( 0.5, 0.5, 0.5 );
    this.dof = '';

    this._face = 'x+';
    this._F = new Matrix4();
  }

  static toFaceMatrix(f, a) {
    const p = new Vector3().fromArray( f, 4 ).multiply( a );
    const q = new Quaternion().fromArray( f );
    const s = new Vector3( 1, 1, 1 );
    return new Matrix4().compose( p, q, s );
  }

  clone() {
    return new LinkCap().set(this);
  }

  set(o) {
    let W, a, d, s;
    if(o instanceof LinkCap) {
      d = o.dof;
      W = o.W;
      a = o.axes;
      s = 1;
    }
    else if(o.userData.linkCap) {
      d = o.userData.linkCap.dof;
      W = o.userData.linkCap.W;
      a = o.userData.linkCap.axes;
      s = 1;
    }
    else if(o instanceof Group) {
      d = o.userData.json.dof;
      W = o.matrixWorld;
      a = o.clone( false );
      a.position.set( 0, 0, 0);
      a.rotation.set( 0, 0, 0);
      a.parent = null;
      // s = undefined => use default value of setBox
    }
    else if(o instanceof Object3D) {
      d = '';
      W = o.matrixWorld;
      a = o;
      // s = undefined => use default value of setBox
    }

    this.setDOF( d );
    this.setWorld( W );
    this.setBox( a, s );

    return this;
  }

  setDOF(dof) {
    this.dof = dof;
    return this;
  }

  setWorld(W) {
    this.W.copy( W );
    return this;
  }

  setBox(o, scale) {
    var b = new Box3();  // assumes infinite size as default

    if(o instanceof Group) {
      b.setFromObject( o );
    }
    else if(o instanceof Object3D) {
      b.setFromBufferAttribute( o.geometry.attributes.position );
    }
    else if(o instanceof BufferGeometry) {
      b.setFromBufferAttribute( o.attributes.position );
    }
    else if(o instanceof Vector3) {
      b.setFromCenterAndSize( new Vector3(), o );
    }
    else {
      console.warn(
          'unknown object; box will have zero size.\n', o);
    }

    b.getSize( this.axes ).multiplyScalar( scale || 0.5 );
    return this;
  }

  getScaleFactor(face) {
    let a, n, t, b;

    if(!face) face = this.nearestFace;
    a = this.axes;

    switch(face[0]) {
      case 'y':
        n = a.y;
        t = a.x; // width
        b = a.z; // height
        break;

      case 'z':
        n = a.z;
        t = a.y;
        b = a.x;
        break;

      case 'x':
      default:
        n = a.x;
        t = a.y;
        b = a.z;
        break;
    }

    return new Vector3( n, t, b );
  }

  setFace(i) {
    if(typeof i === 'string') i = LinkCap._toNum[i];

    if(i < 0) i += LinkCap._faces.length;

    const F = LinkCap.toFaceMatrix( LinkCap._faces[i], this.axes );

    this._face = LinkCap._toName[i];
    this._F.copy( F );
    return this;
  }

  getFaces() {
    return LinkCap._faces.map( f => {
      let F = LinkCap.toFaceMatrix( f, this.axes );
      F.premultiply( this.W );
      return new Vector3().setFromMatrixPosition( F );
    }, this );
  }

  getCorner(i, d) {
    const c = LinkCap._corners[i];
    c[0] = d || 0; // TODO don't scale d; bad idea for big boxes
    const a = this.getScaleFactor();
    const p = new Vector3().fromArray( c ).multiply( a );
    const F = this.fmat;
    return p.applyMatrix4( F );
  }

  getCorners(d) {
    return LinkCap._corners.map( (e, i) => {
      return this.getCorner( i, d );
    }, this );
  }

  setNearestFaceTo(b) {
    // TODO add option to choose 2nd closest face, check dof, if dof === face
    // then choose 2nd option
    const min = minDistanceTo( this.getFaces(), b.getFaces() );
    // set faces to min indices
    this.setFace( min[0] );
    b.setFace( min[1] );
    return this;
  }

  moveFaceToOrigin(x, check) {
    const M = this.fmat;
    const xprime = new Vector3().setFromMatrixColumn( M, 0 );

    // preserve orientation
    if(check && x.dot( xprime ) < 0) x.negate();

    const angle = xprime.angleTo( x );
    const axis = new Vector3();
    // rotate about cross(x', x) or M's z-axis
    if(angle < Math.PI) {
      axis.crossVectors( xprime, x );
    }
    else {
      axis.setFromMatrixColumn( M, 2 );
    }
    axis.normalize();

    const pos = new Vector3().setFromMatrixColumn( M, 3 ).negate();
    const T = new Matrix4().setPosition( pos );
    const R = new Matrix4().makeRotationAxis( axis , angle );

    return R.multiply(T);
  }

  getNearestCornerTo(b, bottomRight) {
    let i, j, min, T;

    const n = new Vector3(1, 0, 0); // normal direction
    const f = p => p.applyMatrix4( T );

    this.setNearestFaceTo( b );

    T = this.moveFaceToOrigin( n, true );
    const m0 = this.getCorners().map( f );

    T = b.moveFaceToOrigin( n.negate(), false );
    const m1 = b.getCorners().map( f );

    // find min distance corner pair
    min = minDistanceTo( m0, m1 );

    if(bottomRight) {
      // find bottom-right corner
      i = min[0];
      j = min[1];
      n.set( 0, 1, -1 ).multiply( this.getScaleFactor() );

      min = minDistanceTo(m0, [ n ]);  // find min to b-r corner

      j = (j - (min[0] - i)) % 4; // get corresponding pair
      if(j < 0) j += 4; // 4 corners

      min[1] = j;
    }

    return min;
  }

  getNearestBottomRightCornerTo(b) {
    return this.getNearestCornerTo( b, true );
  }

  getCap() {
    let c;

    switch(this.dof) {
      case 'rx':
      case 'ry':
      case 'rz':
        c = this.getRotationalJointCap();
        break;
      case 'poi-circ':
        c = this.getPOICircCap();
        break;
      case 'poi':
        c = this.getPOICap();
        break;
      case 'poi-flat':
      case 'px':
      case 'py':
      case 'pz':
      default:
        c = this.getPrismaticJointCap();
    }

    return c;
  }

  getPrismaticJointCap() {
    const w = 1;
    const s = this.getScaleFactor().multiplyScalar( 2 );

    const geo = new PlaneBufferGeometry( w, w );
    geo.rotateY( -Math.PI / 2 );
    geo.scale( s.x, s.y, s.z );
    geo.applyMatrix4( this.fmat );

    return geo;
  }

  getPOICircCap() {
    const w = 1;
    const s = this.getScaleFactor().multiplyScalar( 2 );

    // cube
    const geo = new BoxBufferGeometry( w, w, w );
    geo.scale( s.x, s.y, s.z );
    geo.applyMatrix4( this.fmat );

    return geo;
  }

  getPOICap() {
    const d = 1 / 2; // half width of unit square
    const h = 0.5;
    const r = d / Math.sin( Math.atan( d / h ) );
    const s = this.getScaleFactor().multiplyScalar( 2 );

    // pyramid
    const geo = new ConeBufferGeometry( r, h, 4, 1, true, Math.PI / 4 );
    geo.rotateZ( Math.PI / 2 );
    geo.translate( -h / 2, 0, 0 );
    geo.scale( s.x, s.y, s.z );
    geo.applyMatrix4( this.fmat );

    return geo;
  }

  getRotationalJointCap() {
    const dof = this.dof;
    const face = this.nearestFace;
    const d = 1;
    const r = d / 2;
    const s = this.getScaleFactor().multiplyScalar( 2 );

    const f = new Shape();
    if(dof[1] === face[0]) {
      f.moveTo( -r, 0 );
      f.lineTo( r, 0 );
    }
    else {
      f.absarc( 0, 0, r , Math.PI, 2 * Math.PI );
    }

    f.lineTo( r, -r );
    f.lineTo( -r, -r );
    f.lineTo( -r, 0 );
    const front = new ShapeBufferGeometry( f );
    const back = front.clone();

    const left = new PlaneBufferGeometry( d, r );
    const right = left.clone();

    front.translate( 0, 0, r );

    back.rotateY( Math.PI );
    back.translate( 0, 0, -r );

    left.rotateY( -Math.PI / 2 );
    left.translate( -r, -d / 4, 0 );

    right.rotateY( Math.PI / 2 );
    right.translate( r, -d / 4, 0 );

    const a = [ front, back, left, right ];

    const geo = mergeBufferGeometries( a );
    geo.translate( 0, r, 0 );
    geo.rotateX( -Math.PI / 2 );
    geo.rotateY( Math.PI / 2 );

    if(dof === 'rx' && face[0] === 'z') {
      geo.rotateX( Math.PI / 2 );
    }
    else if(dof === 'rz') {
      geo.rotateX( Math.PI / 2 );
    }

    geo.scale( s.x, s.y, s.z );
    geo.applyMatrix4( this.fmat );

    return geo;
  }

  get fmat() { return this.W.clone().multiply( this._F ); }

  get nearestFace() { return this._face; }
}

LinkCap._corners = [ // x y z
  [0, 1, -1],
  [0, 1, 1],
  [0, -1, 1],
  [0, -1, -1]
];

LinkCap._faces = (() => {
  const r = Math.SQRT1_2; // sin(pi/4) = cos(pi/4)
  return [
  // qx, qy, qz, qw, px, py, pz
  [ 0, 0, 0, 1, 1, 0, 0 ],
  [ 0, 0, r, r, 0, 1, 0 ],
  [ 0, -r, 0, r, 0, 0, 1 ],
  [ 0, 0, 1, 0, -1, 0, 0 ],
  [ 0, 0, -r, r, 0, -1, 0 ],
  [ 0, r, 0, r, 0, 0, -1 ] ];
} )();

LinkCap._toNum = { 'x+': 0, 'y+': 1, 'z+': 2, 'x-': 3, 'y-': 4, 'z-': 5 };

LinkCap._toName = [ 'x+', 'y+', 'z+', 'x-', 'y-', 'z-' ];

function minDistanceTo(s, d) {
  var i, j, dist;

  // find closest pair of points
  dist = [];
  for(i = 0; i < s.length; i++) {
    for(j = 0; j < d.length; j++) {
      dist.push( [ i, j, s[i].distanceTo( d[j] ) ] );
    }
  }

  dist.sort( (a, b) => a[2] - b[2] );

  i = dist[0][0];
  j = dist[0][1];

  return [ i, j ];
}

export function planarize(name, geometry, n, pat) {
  if(!n.match(/x|y|z/)) return;

  if(!pat) pat = { left: /^left/i, right: /^right/i };

  const g = geometry;
  const s = new Vector3( 1, 1, 1 );
  const t = new Vector3();
  const box = new Box3();

  box.setFromBufferAttribute( g.getAttribute( 'position' ) );

  s[n] /= 2;
  g.scale( s.x, s.y, s.z );

  t[n] = box.getSize( new Vector3() )[n] / 2;
  if(name.match( pat.left )) {
    g.translate( t.x, t.y, t.z );
  }
  else if(name.match( pat.right )) {
    t.negate();
    g.translate( t.x, t.y, t.z );
  }
}

// possible bug in BufferGeometryUtils.mergeBufferGeometries, so use this until
// reported/fix bug appears when calling getRotationalJointCap(...)
function mergeBufferGeometries(geometries) {
  let template;

  const geometry = new BufferGeometry();
  const attributes = geometries.map( g => g.attributes );

  // merge attributes
  template = attributes[0];
  for(let k in template) {
    const itemSize = template[k].itemSize;
    const count = attributes.reduce( (acc, a) => acc + a[k].count, 0 );
    const array = new template[k].array.constructor( itemSize * count );

    attributes.reduce( (acc, a) =>  {
      // copy attribute arrays into merged array
      array.set( a[k].array, acc * itemSize );
      return acc + a[k].count;
    }, 0 );

    geometry.setAttribute( k, new BufferAttribute( array, itemSize ) );
  }

  template = geometries[0].getIndex();
  if(template) {
    // merge index
    const itemSize = template.itemSize;
    const count = geometries.reduce( (acc, g) => acc + g.getIndex().count, 0 );
    const array = new template.array.constructor( itemSize * count );

    geometries.reduce( (acc, g) => {
      const pStart = acc[0];
      const iStart = acc[1];
      const index = g.getIndex();
      array.set( index.array.map( i => i + pStart ), iStart );
      return [ pStart + g.attributes['position'].count, iStart + index.count ];
    }, [0, 0] );

    geometry.setIndex( new BufferAttribute( array, itemSize ) );
  }

  return geometry;
}
