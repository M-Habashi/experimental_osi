import * as T from 'three';
import {V,metal,box,cylinder,post,bolt,tube,tag,batch,STRONG_FLOOR_Y} from './rig.js';

const floorY=STRONG_FLOOR_Y;
const steel=metal(0x505e65,.77,.30), lightSteel=metal(0x919b9c,.69,.34);
const zinc=metal(0x92958c,.72,.4), rust=metal(0x726154,.52,.42);
const yellow=metal(0xca961d,.37,.52), blue=metal(0x305284,.48,.46);
const rubber=metal(0x232726,.02,.89), wood=metal(0xb29471,.03,.91);
const slab=metal(0x97968c,.04,.88), black=metal(0x202725,.16,.8);

function strut(g,a,b,w,d,mat){
  const start=V(...a),end=V(...b),dir=end.clone().sub(start);
  const o=box(g,0,0,0,w,dir.length(),d,mat);
  o.position.copy(start).lerp(end,.5);o.quaternion.setFromUnitVectors(V(0,1,0),dir.normalize());
  return o;
}
function horizontalI(g,x,y,z,length,depth,width,mat){
  box(g,x,y,z,length,depth-.026,.012,mat);
  for(const s of [-1,1])box(g,x,y+s*(depth-.013)/2,z,length,.013,width,mat);
}
function columnI(g,x,z,bottom,top,mat){
  box(g,x,(top+bottom)/2,z,.012,top-bottom,.156,mat);
  for(const s of [-1,1])box(g,x,(top+bottom)/2,z+s*.085,.182,top-bottom,.014,mat);
}
function testBay(){
  const g=new T.Group();g.name='High-bay laboratory fixtures';
  // The second loading station sits behind SP3 in the wide photograph.
  const z=-4.55,x=-2.35,top=2.84;
  for(const col of [-3.11,-.67]){
    columnI(g,col,z,floorY,top-.225,lightSteel);
    box(g,col,floorY+.015,z,.45,.03,.41,steel);
    for(const xx of [-.146,.146])for(const zz of [-.135,.135])bolt(g,col+xx,floorY+.03,z+zz,.017,.018);
    for(let y=.24;y<top-.24;y+=.21)for(const dx of [-.047,.047]){
      cylinder(g,V(col+dx,y,z+.092),V(col+dx,y,z+.094),.011,black,10);
    }
    tag(g,'W14 X 132',col,.79,z+.094,.39,.057,'#313536','',Math.PI/2);
  }
  horizontalI(g,-1.89,top-.11,z,2.92,.23,.23,steel);
  horizontalI(g,-1.89,.68,z-.20,3.32,.23,.17,rust);
  strut(g,[-4.35,floorY,z-.28],[-2.86,2.4,z-.28],.078,.068,lightSteel);
  strut(g,[.50,floorY,z-.30],[-.86,2.5,z-.30],.078,.068,lightSteel);
  box(g,x,-.292,z+.08,.79,.456,1.22,slab,.008);
  box(g,x,-.042,z,.39,.039,.42,steel,.002);
  for(const side of [-1,1]){
    post(g,x+side*.18,-.022,.39,z+.17,.010,zinc,14);
    post(g,x+side*.18,-.022,.39,z-.17,.010,zinc,14);
  }
  post(g,x,.01,.40,z,.081,lightSteel,32);post(g,x,.40,.58,z,.064,black);
  post(g,x,.58,1.15,z,.078,blue,32);post(g,x,1.15,1.32,z,.050,zinc,32);
  post(g,x,1.32,1.39,z,.113,steel);post(g,x,1.39,1.80,z,.117,yellow,36);
  post(g,x,1.80,1.84,z,.129,black);post(g,x,1.84,2.60,z,.071,steel);
  box(g,x,2.64,z,.34,.10,.33,steel,.004);
  tube(g,[[x+.09,1.72,z],[x+.24,1.83,z-.13],[x+.13,2.22,z-.21],[-1.45,2.42,z-.17],[-.76,2.33,z-.16],[-.64,.3,z-.20]],.012,rubber);
  // Bench, rolling acquisition cabinet and coiled hydraulic lines around the bay.
  const bx=3.48,bz=-4.45;
  box(g,bx,.45,bz,1.85,.055,.68,wood,.006);
  for(const a of [-.84,.84])for(const b of [-.27,.27])box(g,bx+a,-.045,bz+b,.05,.96,.05,steel);
  box(g,bx+.34,.65,bz,.47,.28,.045,black,.005);box(g,bx+.34,.51,bz,.038,.09,.044,steel);
  box(g,bx-.48,.586,bz,.47,.21,.31,lightSteel,.008);
  for(let n=0;n<6;n++)box(g,bx-.62+n*.048,.59,bz+.159,.024,.058,.005,black);
  box(g,2.50,-.12,-1.41,.43,.65,.45,lightSteel,.012);
  for(let h=0;h<5;h++)box(g,2.50,-.31+h*.11,-1.18,.37,.087,.014,black,.003);
  for(const dx of [-.15,.15])for(const dz of [-.15,.15])cylinder(g,V(2.50+dx-.025,-.46,-1.41+dz),V(2.50+dx+.025,-.46,-1.41+dz),.052,rubber,16);
  tube(g,[[2.16,-.49,.68],[2.53,-.49,.6],[2.81,-.49,.27],[2.91,-.49,-.63],[2.73,-.48,-1.17],[2.6,-.20,-1.23]],.017,rubber);
  for(const xx of [-1.6,-.95,-.30,.35,1,1.65,2.30])for(const zz of [-1.18,1.16]){
    post(g,xx,floorY-.012,floorY+.006,zz,.024,zinc,16);
  }
  batch(g);return g;
}
function towerCrane(g){
  const x=0,z=0,y0=0,h=10.2,a=.48;
  box(g,x,y0+.31,z,2.8,.62,2.45,slab,.035);
  for(const sx of [-a,a])for(const sz of [-a,a])strut(g,[x+sx,y0+.62,z+sz],[x+sx,h,z+sz],.092,.092,yellow);
  for(let y=y0+.7;y<h-.7;y+=1.24){
    for(const s of [-1,1]){
      strut(g,[x-a,y,z+s*a],[x+a,y+1.24,z+s*a],.048,.048,yellow);
      strut(g,[x+s*a,y,z-a],[x+s*a,y+1.24,z+a],.048,.048,yellow);
      strut(g,[x-a,y,z+s*a],[x+a,y,z+s*a],.047,.047,yellow);
    }
  }
  const boomY=h+.36;
  box(g,x,h+.035,z,1.13,.09,1.13,steel);
  post(g,x,h+.08,boomY,z,.54,yellow,30);
  for(const zz of [-.37,.37])strut(g,[x-13,boomY,z+zz],[x+3.6,boomY,z+zz],.070,.070,yellow);
  strut(g,[x-13,boomY+.64,z],[x+3.6,boomY+.64,z],.071,.071,yellow);
  for(let j=-13;j<3.4;j+=.9)for(const zz of [-.37,.37]){
    strut(g,[x+j,boomY,z+zz],[x+j+.45,boomY+.64,z],.041,.041,yellow);
    strut(g,[x+j+.45,boomY+.64,z],[x+j+.9,boomY,z+zz],.041,.041,yellow);
  }
  box(g,x+.03,h+.06,z+.76,.83,.85,.67,yellow,.03);
  box(g,x+.03,h+.15,z+1.102,.69,.53,.016,metal(0x536b73,.45,.24));
  for(let j=0;j<3;j++)box(g,x+2.4+j*.43,h+.3,z,.39,.93,1.12,slab,.025);
  for(const xx of [-8.8,3.2])strut(g,[x,boomY+2.2,z],[x+xx,boomY+.3,z],.026,.026,steel);
  strut(g,[x,boomY+.48,z],[x,boomY+2.2,z],.064,.064,yellow);
  for(const zz of [-.04,.04])strut(g,[x-6.6,boomY,z+zz],[x-6.6,6.7,z+zz],.013,.013,black);
  box(g,x-6.6,6.63,z,.16,.18,.12,yellow);
}
function constructionSite(){
  const g=new T.Group();g.name='Construction site staging';const grade=floorY-.18;
  box(g,3.6,floorY-.09,0,13.35,.18,3.55,slab,.019);
  // Staged material and formwork lie outside the single active analytical frame.
  for(const x of [10.98,13.85])box(g,x,grade+.085,-4.52,.17,.17,1.02,wood);
  for(let level=0;level<2;level++)for(let n=0;n<3;n++)horizontalI(g,12.40,grade+.262+level*.184,-4.23-n*.27,4.3,.184,.15,steel);
  for(let i=0;i<5;i++)box(g,16.08+(i%2)*.03,grade+.026+i*.052,-4.62,1.85,.052,.75,wood);
  for(const x of [9.8,12.2,14.6,17.0])post(g,x,grade,grade+1.05,-5.8,.038,zinc,12);
  for(const h of [.44,.92])box(g,13.4,grade+h,-5.86,7.26,.08,.05,wood);
  batch(g);
  const crane=new T.Group();towerCrane(crane);batch(crane);
  crane.position.set(26.8,grade,-18);crane.rotation.y=Math.PI*.84;crane.scale.setScalar(.80);g.add(crane);return g;
}

// The bay walls, window frames, lights, rails and floor all have thickness and parallax.
function laboratory(){
  const room=new T.Group(),shell=new T.Group();
  const plaster=metal(0xb7c1bd,.03,.85),lower=metal(0x858f8a,.03,.86);
  const enamel=metal(0x697c83,.50,.37),trim=metal(0x849198,.56,.38);
  const glass=metal(0xb7d5df,.22,.29,{emissive:0x91b8c8,emissiveIntensity:.24});
  const lamp=new T.MeshStandardMaterial({color:0xf4f4e8,emissive:0xfff2d5,emissiveIntensity:.85});
  const concrete=[0x737a76,0x767d79,0x797f7a].map(c=>metal(c,.02,.85));
  const xCuts=[-10,-5,-2.65,3.18,7.05,11],zCuts=[-9,-5.85,-2.12,2.10,5.65,10.5];
  for(let i=1;i<xCuts.length;i++)for(let j=1;j<zCuts.length;j++){
    const x0=xCuts[i-1],x1=xCuts[i],z0=zCuts[j-1],z1=zCuts[j];
    box(shell,(x0+x1)/2,floorY-.09,(z0+z1)/2,x1-x0-.013,.18,z1-z0-.013,concrete[(i+j)%3]);
  }
  box(shell,.5,floorY-.22,.75,21,.07,19.5,lower);
  const eave=5.20,ridge=6.12,mid=.5;
  function wall(x,z,length,rotation,bays){
    const w=new T.Group();w.position.set(x,0,z);w.rotation.y=rotation;shell.add(w);
    const h1=1.00,h2=2.86,h3=4.30,step=length/bays;
    box(w,0,(floorY+h1)/2,0,length,h1-floorY,.21,lower);
    box(w,0,(h1+h2)/2,0,length,h2-h1,.21,plaster);
    box(w,0,(h3+eave)/2,0,length,eave-h3,.21,plaster);
    for(const y of [h2-.035,h3+.035])box(w,0,y,.02,length,.07,.27,trim);
    for(let i=0;i<bays;i++){
      const u=-length/2+(i+.5)*step;
      box(w,u,(h2+h3)/2,-.025,step-.12,h3-h2,.055,glass);
      box(w,u,(h2+h3)/2,.015,.065,h3-h2,.12,trim);
      box(w,u-step/2+.046,(h2+h3)/2,0,.092,h3-h2,.19,enamel);
    }
    batch(w);
  }
  wall(mid,-9.10,21.2,0,7);wall(mid,10.60,21.2,Math.PI,7);
  wall(-10.10,.75,19.5,Math.PI/2,6);wall(11.10,.75,19.5,-Math.PI/2,6);
  const pitch=Math.atan2(ridge-eave,10.5),roof=metal(0xb6c2c2,.19,.74);
  for(const side of [-1,1]){
    const panel=box(shell,mid+side*5.25,(ridge+eave)/2+.085,.75,10.5/Math.cos(pitch),.14,19.9,roof);
    panel.rotation.z=-side*pitch;
  }
  const gable=new T.Shape();gable.moveTo(-10.5,0);gable.lineTo(10.5,0);gable.lineTo(0,ridge-eave);gable.closePath();
  for(const z of [-9.19,10.50]){
    const face=new T.Mesh(new T.ExtrudeGeometry(gable,{depth:.19,bevelEnabled:false}),plaster);
    face.position.set(mid,eave,z);shell.add(face);
  }
  for(const z of [-8.83,-4.45,.1,4.65,10.32]){
    for(const side of [-1,1]){
      const x=mid+side*10.25;
      box(shell,x,(eave+floorY)/2,z,.23,eave-floorY,.27,enamel);
      strut(shell,[x,eave-.12,z],[mid,ridge-.12,z],.23,.22,enamel);
      strut(shell,[x,3.88,z],[x-side*1.6,eave-.01,z],.13,.16,enamel);
    }
  }
  for(const x of [-4.2,4.6])for(const z of [-5.65,1.05,7.6]){
    for(const dz of [-.95,.95])strut(shell,[x,4.74,z+dz],[x,5.53,z+dz],.023,.023,trim);
    box(shell,x,4.71,z,.24,.09,2.35,enamel);
    box(shell,x,4.649,z,.205,.032,2.28,lamp);
  }
  // A single sectional door on the far wall.
  const door=metal(0x87969a,.28,.66);
  box(shell,6.28,1.13,-8.922,3.12,3.30,.13,enamel);
  for(let i=0;i<6;i++)box(shell,6.28,floorY+.285+i*.529,-8.826,2.96,.515,.066,door);
  batch(shell);shell.traverse(o=>{if(o.isMesh)o.castShadow=false;});
  room.add(shell,testBay());return room;
}

function terrainHeight(x,z){
  const ridge=T.MathUtils.smoothstep(Math.hypot(x-4,z),32,91);
  return floorY-.18+ridge*(3.9+2.2*Math.sin(.047*x+.029*z)+1.35*Math.cos(.058*z-.018*x)+.8*Math.sin(.084*x));
}
export function siteFloorAt(x,z){
  return Math.abs(x-3.6)<13.35/2&&Math.abs(z)<3.55/2?floorY:terrainHeight(x,z);
}
function landscape(){
  const g=new T.Group();
  // A single continuous terrain surface extends up into the distant low ridges.
  const geo=new T.PlaneGeometry(380,380,100,100).rotateX(-Math.PI/2),pos=geo.attributes.position;
  const colors=[],near=new T.Color(0x92846c),far=new T.Color(0x657c6a),color=new T.Color();
  for(let i=0;i<pos.count;i++){
    const x=pos.getX(i),z=pos.getZ(i),r=Math.hypot(x-4,z);
    const ridge=T.MathUtils.smoothstep(r,32,91);
    pos.setY(i,terrainHeight(x,z));
    color.copy(near).lerp(far,ridge*(.67+.13*Math.sin(x*.065))).multiplyScalar(1+.013*Math.cos(x*.4+z*.29));
    colors.push(color.r,color.g,color.b);
  }
  geo.setAttribute('color',new T.Float32BufferAttribute(colors,3));geo.computeVertexNormals();
  const land=new T.Mesh(geo,new T.MeshStandardMaterial({vertexColors:true,roughness:.98}));land.receiveShadow=true;g.add(land);
  const sky=new T.Mesh(new T.SphereGeometry(1,40,24),new T.ShaderMaterial({
    side:T.BackSide,depthWrite:false,depthTest:false,
    uniforms:{top:{value:new T.Color(0x4d81aa)},horizon:{value:new T.Color(0xbbcfdc)}},
    vertexShader:'varying vec3 dir;void main(){dir=position;vec4 p=projectionMatrix*vec4(mat3(viewMatrix)*position,1.);gl_Position=p.xyww;}',
    fragmentShader:`varying vec3 dir;uniform vec3 top;uniform vec3 horizon;void main(){
      float h=clamp(normalize(dir).y,0.,1.);
      gl_FragColor=vec4(mix(horizon,top,pow(h,.46)),1.);
      #include <colorspace_fragment>
    }`
  }));sky.frustumCulled=false;sky.renderOrder=-100;g.add(sky);
  g.add(constructionSite());return g;
}

export function createLocations(){
  return {specimen:laboratory(),frame:landscape()};
}

