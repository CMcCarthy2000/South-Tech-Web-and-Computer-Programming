const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

canvas.style.backgroundColor = '#87ceeb';

// --- IMAGE LOADING SETUP ---
const playerImage = new Image();
let isImageLoaded = false;

playerImage.onload = () => {
  console.log('Player image loaded successfully!');
  isImageLoaded = true;
};

playerImage.onerror = () => {
  console.error('Failed to load image. Ensure "blahaj.png" is in the same directory or check your path/CORS settings.');
};

// Set path to your image file
playerImage.src = 'js/blahaj.png';

let showDebug = false;

// --- PLAYER RIGID BODY PROPERTIES ---
const player = {
  x: 100,
  y: 80,
  width: 100,             // Scaled up width (formerly 40)
  height: 80,            // Scaled up height (formerly 40)
  vx: 0,
  vy: 0,
  speed: 4,
  jumpForce: -12,
  gravity: 0.5,
  grounded: false,
  color: '#4f46e5',      // Fallback color if image is loading/missing
  
  // Rotational Physics State
  rotation: 0,           // Angle in radians
  angularVelocity: 0,    // Speed of spin (rad/frame)
  angularDamping: 0.95,  // Rotational friction
  isTeetering: false
};

const platforms = [
  { x: 100, y: 340, width: 120, height: 20, color: '#5BCEFA' },
  { x: 200, y: 340, width: 120, height: 20, color: '#F5A9B8' },
  { x: 300, y: 240, width: 120, height: 20, color: '#FFFFFF' },
  { x: 400, y: 240, width: 120, height: 20, color: '#F5A9B8' },
  { x: 500, y: 240, width: 120, height: 20, color: '#5BCEFA' }
];

const keys = { KeyA: false, KeyD: false, KeyW: false, Space: false };

window.addEventListener('keydown', (e) => {
  if (e.code in keys) keys[e.code] = true;
  if (e.code === 'Tab' || e.code === 'KeyI') {
    e.preventDefault();
    showDebug = !showDebug;
  }
});

window.addEventListener('keyup', (e) => {
  if (e.code in keys) keys[e.code] = false;
});

function getDirectionString(vx, vy) {
  if (Math.abs(vx) < 0.1 && Math.abs(vy) < 0.1) return 'IDLE';

  let dir = '';
  if (vy < -0.1) dir += 'UP ';
  else if (vy > 0.5) dir += 'DOWN ';

  if (vx > 0.1) dir += 'RIGHT';
  else if (vx < -0.1) dir += 'LEFT';

  return dir.trim();
}

function update() {
  // 1. Horizontal Movement Forces
  if (keys.ArrowRight || keys.KeyD) player.vx = player.speed;
  else if (keys.ArrowLeft || keys.KeyA) player.vx = -player.speed;
  else player.vx *= 0.8; // Smooth friction deceleration

  // 2. Jumping
  if ((keys.ArrowUp || keys.KeyW || keys.Space) && player.grounded) {
    player.vy = player.jumpForce;
    player.grounded = false;
  }

  // 3. Gravity
  player.vy += player.gravity;

  player.x += player.vx;
  player.y += player.vy;

  // Screen Boundaries
  if (player.x < 0) {
    player.x = 0;
    player.vx = 0;
  }
  if (player.x + player.width > canvas.width) {
    player.x = canvas.width - player.width;
    player.vx = 0;
  }

  // --- PLATFORM PHYSICS & COLLISION RESOLUTION ---
  player.grounded = false;
  player.isTeetering = false;

  platforms.forEach(plat => {
    const overlapsX = player.x < plat.x + plat.width && player.x + player.width > plat.x;
    const overlapsY = player.y < plat.y + plat.height && player.y + player.height > plat.y;

    if (overlapsX && overlapsY) {
      const playerCenter = player.x + player.width / 2;

      if (player.vy > 0 && player.y + player.height - player.vy <= plat.y + 10) {
        player.y = plat.y - player.height;
        player.vy = 0;

        const overhangRight = playerCenter - (plat.x + plat.width);
        const overhangLeft = plat.x - playerCenter;

        if (overhangRight > 0) {
          player.isTeetering = true;
          const torque = overhangRight * 0.002;
          player.angularVelocity += torque;
          player.vx += overhangRight * 0.1;
        } else if (overhangLeft > 0) {
          player.isTeetering = true;
          const torque = overhangLeft * 0.002;
          player.angularVelocity -= torque;
          player.vx -= overhangLeft * 0.1;
        } else {
          player.grounded = true;
          player.angularVelocity = 0;
          player.rotation = 0;
        }
      } 
      else if (player.vy < 0 && player.y - player.vy >= plat.y + plat.height - 10) {
        player.y = plat.y + plat.height;
        player.vy = 0;
      }
      else if (player.vx > 0) {
        player.x = plat.x - player.width;
        player.vx = 0;
      } else if (player.vx < 0) {
        player.x = plat.x + plat.width;
        player.vx = 0;
      }
    }
  });

  // Grass Floor Collision
  const grassHeight = 30;
  const floorY = canvas.height - grassHeight;

  if (player.y + player.height >= floorY) {
    player.y = floorY - player.height;
    player.vy = 0;
    player.grounded = true;
    player.angularVelocity = 0;
    player.rotation = 0;
  }

  // Rotational Physics Updates
  if (!player.grounded) {
    if (!player.isTeetering) {
      player.angularVelocity = player.vx * 0.03;
    }
    player.rotation += player.angularVelocity;
    player.angularVelocity *= player.angularDamping;
  }
}

function draw() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  // Grass Floor
  const grassHeight = 30;
  ctx.fillStyle = '#22c55e';
  ctx.fillRect(0, canvas.height - grassHeight, canvas.width, grassHeight);

  ctx.strokeStyle = '#15803d';
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.moveTo(0, canvas.height - grassHeight);
  ctx.lineTo(canvas.width, canvas.height - grassHeight);
  ctx.stroke();

  // Platforms
  platforms.forEach(plat => {
    ctx.fillStyle = plat.color;
    ctx.fillRect(plat.x, plat.y, plat.width, plat.height);
  });

  // Draw Player Image / Fallback Rect
  ctx.save();
  const centerX = player.x + player.width / 2;
  const centerY = player.y + player.height / 2;
  ctx.translate(centerX, centerY);
  ctx.rotate(player.rotation);

  if (isImageLoaded) {
    ctx.drawImage(
      playerImage,
      -player.width / 2,
      -player.height / 2,
      player.width,
      player.height
    );
  } else {
    // Draw solid color fallback box until image loads
    ctx.fillStyle = player.color;
    ctx.fillRect(-player.width / 2, -player.height / 2, player.width, player.height);

    const borderWidth = 3;
    ctx.strokeStyle = '#000000';
    ctx.lineWidth = borderWidth;
    ctx.strokeRect(
      -player.width / 2 + borderWidth / 2,
      -player.height / 2 + borderWidth / 2,
      player.width - borderWidth,
      player.height - borderWidth
    );
  }

  ctx.restore();

  // Debug HUD
  if (showDebug) {
    const totalSpeed = Math.hypot(player.vx, player.vy);

    if (totalSpeed > 0.1) {
      const vectorLength = 35;
      const angle = Math.atan2(player.vy, player.vx);
      const endX = centerX + Math.cos(angle) * vectorLength;
      const endY = centerY + Math.sin(angle) * vectorLength;

      ctx.strokeStyle = '#ef4444';
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(centerX, centerY);
      ctx.lineTo(endX, endY);
      ctx.stroke();

      ctx.fillStyle = '#ef4444';
      ctx.beginPath();
      ctx.arc(endX, endY, 4, 0, Math.PI * 2);
      ctx.fill();
    }

    ctx.fillStyle = 'rgba(15, 23, 42, 0.85)';
    ctx.fillRect(10, 10, 220, 145);
    ctx.strokeStyle = '#38bdf8';
    ctx.lineWidth = 1;
    ctx.strokeRect(10, 10, 220, 145);

    ctx.fillStyle = '#f8fafc';
    ctx.font = '12px monospace';

    const dirString = getDirectionString(player.vx, player.vy);

    ctx.fillText(`DEBUG OVERLAY [Tab/I]`, 20, 28);
    ctx.fillText(`-------------------`, 20, 40);
    ctx.fillText(`vx:        ${player.vx.toFixed(2)}`, 20, 56);
    ctx.fillText(`vy:        ${player.vy.toFixed(2)}`, 20, 72);
    ctx.fillText(`Speed:     ${totalSpeed.toFixed(2)} px/f`, 20, 88);
    ctx.fillText(`Direction: ${dirString}`, 20, 104);
    ctx.fillText(`Teetering: ${player.isTeetering}`, 20, 120);
    ctx.fillText(`Grounded:  ${player.grounded}`, 20, 136);
  }
}

function gameLoop() {
  update();
  draw();
  requestAnimationFrame(gameLoop);
}

gameLoop();