const express = require('express');
const glob = require('glob');
const fs = require('fs').promises;
const zlib = require('zlib');
const path = require("path");
const WebSocket = require('ws').Server;
const { spawn } = require('child_process');
const { pipeline, Readable } = require('stream');
const opener = require('opener');
const ffbinaries = require('ffbinaries');

/************* GLOBAL VARIABLES *****************/

const p = f => path.join( __dirname, f );
const pkg = f => path.join( process.cwd(), 'GaitBrowserOutput', f); 
const output = f => process.pkg ? pkg( f ) : p( f );

const globOpts = { cwd: p( './public/bipeds' ) };
const bipedFiles = glob.sync('*.json', globOpts)
  .map( b => b.replace(/.json/, '') );

console.log(bipedFiles);

const bipedImages = {};

// const { ffmpeg } = ffbinaries.locateBinariesSync("ffmpeg", { paths: [ output( '' ) ] } );
const ffmpeg = {};

const ffmpegArgs = [
    // ffmpeg doc: https://ffmpeg.org/documentation.html
    // libx264 guide: https://trac.ffmpeg.org/wiki/Encode/H.264
    '-y', 
    '-f', 'image2pipe',
    '-framerate', '< insert fps here >',
    '-i', 'pipe:0',
    //'-s', 'hd1080',
    '-aspect', '16:9',
    //'-vf', 'pad=1920:1080:-1:-1:black',
    '-vcodec', 'libx264', 
    '-crf', '25',
    '-pix_fmt', 'yuv420p',
    '< insert output .mp4 file here >'
];

const iFps = ffmpegArgs.indexOf( '-framerate' ) + 1;
const iOut = ffmpegArgs.length - 1;

/************* SERVER *****************/

const app = express();
app.set('view engine', 'ejs');
app.set('views', p( './views' ) );
app.use(express.static( p( './public' ) ) );
app.use( express.static( p( './public/bipeds' ) ) );

app.get('/build/three.module.js$', (req, res) => {
  const resPath = p( '../node_modules/three/build' );
  res.sendFile( 'three.module.js', { root: resPath } );
});

app.get('/three/:jsm(*.js$)', (req, res) => {
  const resPath = p( `../node_modules/three/examples/jsm` );
  res.sendFile( req.params.jsm, { root: resPath } );
});

app.get('/biped/:biped$', async (req, res) => {
  res.sendFile( `${req.params.biped}.json`, { root: p( './public/bipeds/' ) } );
});

const server = app.listen(() => {
    let { port, address, family } = server.address();

    if(family === 'IPv6') address = `[${address}]`;

    const url = `${address}:${port}`;

    const data = { url: "ws://" + url, bipeds: bipedFiles };
    
    app.get('/', (req, res) => res.render('index', data));

    console.log(`Listening on http://${url}`);
    console.log('Launching web browser...');
    opener(`http://${url}`);
});

const socket = new WebSocket( { server: server } );

socket.on('connection', ws => {
  ws.on('message', msg => message( msg, ws ));
});

function downloadFfmpeg(dest) {
  console.log( 'You do not have an (executable) version of ffmpeg installed.',
    'Attempting to download from ffbinaries.com.');

  return new Promise( (resolve, reject) => ffbinaries.downloadFiles( 
    'ffmpeg',
    { destination: dest }, 
    (e, d) => {
      if(e) reject( new Error( `Error downloading ffmpeg: ${e}` ) );
      dest = path.join( d[0].path, d[0].filename );
      console.log(`Downloaded ffmpeg to: ${dest}.`);
      resolve( dest );
  } ) );
}

function message(msg, ws) {
  const arg = JSON.parse( msg );
  const name = arg.name;

  switch(arg.status) {
    case 'start':
      console.log( 'start', name, arg.n );
      bipedImages[name] = { 
        name: name,
        fps: arg.fps, 
        video: arg.video, 
        n: arg.n,
        t: [], 
        imgs: []
      };
      break;

    case 'img':
      if(bipedImages[name]) {
        bipedImages[name].t.push( arg.t );
        bipedImages[name].imgs.push( arg.img );
      }
      console.log( 'img', name, bipedImages[name].t.length, 'of',
        bipedImages[name].n);
      break;

    case 'done':
      console.log( 'done', name );
      let b = bipedImages[name];
      if(b.video) {
        saveVid( b );
      }
      else {
        saveImgs( b );
      }
      break;

    default:
      console.warn( 'unrecognized status', arg.status );
  }

  ws.send('ACK');
}

async function saveImgs(biped) {
  let name, imgs, dir, n;

  name = biped.name;
  imgs = biped.imgs;
  dir = output( 'imgs/' + name + '/' );

  await fs.mkdir( dir, { recursive: true } );

  await Promise.all( (await fs.readdir( dir ))
    .filter( x => x.match( /\d+\.png$/ ) )
    .map( x => fs.unlink( dir + x ) ) 
  );

  n = (imgs.length - 1).toString().length;

  await Promise.all( imgs.map( (x, i) => {
    let f = dir + i.toString().padStart(n, '0') + '.png';
    return fs.writeFile( f, Buffer.from( x, 'base64' ) );
  } ) );

  console.log( imgs.length + ' images saved to: ' + dir );
}

async function saveVid(biped) {
  let i, n;

  // download ffmpeg or use locally installed version?
  if(!ffmpeg.isExecutable) {
    const bin = output( 'bin' );
    await fs.mkdir( bin, { recursive: true } );
    ffmpeg.path = await downloadFfmpeg( bin );
    ffmpeg.isExecutable = true;
  }

  const name = biped.name;
  const imgs = biped.imgs;
  const dir = output( 'vids/' );

  await fs.mkdir( dir, { recursive: true } );

  ffmpegArgs[iFps] = biped.fps.toString();
  ffmpegArgs[iOut] = dir + name + '.mp4';

  console.log( '*********************************' );
  console.log( 'ffmpeg', ffmpegArgs.join(' ') );

  i = 0;
  n = imgs.length;

  const reader = new Readable( {
    read: function () {
      if(i >= n) this.push( null );
      while(i < n) this.push( Buffer.from( imgs[i++], 'base64' ) );
    }
  } );

  const proc = spawn( ffmpeg.path, ffmpegArgs );

  proc.stdout.on( 'data', (data) => {
    console.log(`stdout: ${data}`);
  } );

  proc.stderr.on( 'data', (data) => {
    console.log(`stderr: ${data}`);
  } );

  proc.on( 'close', (code) => {
    console.log(`ffmpeg process exited with code ${code}`);
    console.log( n + ' images saved to: ' + ffmpegArgs[iOut] );
  } );

  pipeline( reader, proc.stdin, err => { if(err) console.error(err); } );
}

if (process.platform === 'win32') {
  require('readline').createInterface({
    input: process.stdin,
    output: process.stdout
  }).on('SIGINT', function () {
    process.emit('SIGINT');
  });
}

process.on('SIGINT', function () {
  console.log('\n' + 'express server stopped.');
  server.close();
  process.exit();
});

process.on('SIGTERM', function () {
  console.log('\n' + 'express server stopped.');
  server.close();
  process.exit();
});
