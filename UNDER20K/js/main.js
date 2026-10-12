const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

canvas.style.backgroundColor = '#87ceeb';

let showDebug = false;

// Player Rigid Body Properties
const player = {
  x: 100,
  y: 100,
  width: 40,
  height: 40,
  vx: 0,
  vy: 0,
  speed: 4,
  jumpForce: -12,
  gravity: 0.5,
  grounded: false,
  color: '#4f46e5',
  
  // Rotational Physics State
  rotation: 45,            // Angle in radians
  angularVelocity: 0,     // Speed of spin (rad/frame)
  angularDamping: 0.95,   // Rotational friction/air resistance
  isTeetering: false
};

const platforms = [
  { x: 150, y: 380, width: 140, height: 20, color: '#64748b' },
  { x: 350, y: 320, width: 160, height: 20, color: '#64748b' },
  { x: 100, y: 240, width: 120, height: 20, color: '#64748b' }
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

// Helper for Direction string in Debug
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

  // Apply velocities to positions smoothly (No instant positional teleporting)
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
    // Check bounding box intersection
    const overlapsX = player.x < plat.x + plat.width && player.x + player.width > plat.x;
    const overlapsY = player.y < plat.y + plat.height && player.y + player.height > plat.y;

    if (overlapsX && overlapsY) {
      const playerCenter = player.x + player.width / 2;

      // Top surface collision
      if (player.vy > 0 && player.y + player.height - player.vy <= plat.y + 10) {
        player.y = plat.y - player.height;
        player.vy = 0;

        // Check Center of Gravity overhang
        const overhangRight = playerCenter - (plat.x + plat.width);
        const overhangLeft = plat.x - playerCenter;

        if (overhangRight > 0) {
          // Teetering off Right Edge: Apply rotational torque and outward impulse
          player.isTeetering = true;
          const torque = overhangRight * 0.002;
          player.angularVelocity += torque;
          player.vx += overhangRight * 0.1; // Smooth push sideways
        } else if (overhangLeft > 0) {
          // Teetering off Left Edge
          player.isTeetering = true;
          const torque = overhangLeft * 0.002;
          player.angularVelocity -= torque;
          player.vx -= overhangLeft * 0.1; // Smooth push sideways
        } else {
          // Fully supported
          player.grounded = true;
          player.angularVelocity = 0;
          player.rotation = 0;
        }
      } 
      // Bottom surface collision
      else if (player.vy < 0 && player.y - player.vy >= plat.y + plat.height - 10) {
        player.y = plat.y + plat.height;
        player.vy = 0;
      }
      // Side collisions
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
      // Mid-air flip based on horizontal speed
      player.angularVelocity = player.vx * 0.03;
    }
    player.rotation += player.angularVelocity;
    player.angularVelocity *= player.angularDamping; // Air resistance dampening
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

  // Draw Player
  ctx.save();
  const centerX = player.x + player.width / 2;
  const centerY = player.y + player.height / 2;
  ctx.translate(centerX, centerY);
  ctx.rotate(player.rotation);

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

  ctx.restore();

  // Debug HUD
  if (showDebug) {
    const totalSpeed = Math.hypot(player.vx, player.vy);

    // Velocity Vector Line
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

    // HUD Text Box
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