const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

// Player properties including velocity and jump states
const player = {
  x: 100,
  y: 100,
  width: 40,
  height: 40,
  vx: 0,              // Horizontal velocity
  vy: 0,              // Vertical velocity
  speed: 5,           // Horizontal movement speed
  jumpForce: -12,     // Initial jump thrust (negative goes UP)
  gravity: 0.5,       // Downward acceleration
  grounded: false,    // Tracks whether player is touching a floor
  color: '#4f46e5'
};

// Key controls tracking
const keys = {
  ArrowLeft: false,
  ArrowRight: false,
  ArrowUp: false,
  KeyA: false,
  KeyD: false,
  KeyW: false,
  Space: false
};

window.addEventListener('keydown', (e) => {
  if (e.code in keys) {
    keys[e.code] = true;
  }
});

window.addEventListener('keyup', (e) => {
  if (e.code in keys) {
    keys[e.code] = false;
  }
});

function update() {
  // 1. Horizontal Movement
  player.vx = 0; // Reset horizontal velocity
  if (keys.ArrowRight || keys.KeyD) player.vx = player.speed;
  if (keys.ArrowLeft || keys.KeyA) player.vx = -player.speed;

  // 2. Jumping (only allowed if currently touching the floor)
  if ((keys.ArrowUp || keys.KeyW || keys.Space) && player.grounded) {
    player.vy = player.jumpForce;
    player.grounded = false; // Player is now airborne
  }

  // 3. Apply Gravity
  player.vy += player.gravity;

  // 4. Update Position
  player.x += player.vx;
  player.y += player.vy;

  // 5. Canvas Boundary Collision (Left and Right Walls)
  if (player.x < 0) player.x = 0;
  if (player.x + player.width > canvas.width) {
    player.x = canvas.width - player.width;
  }

  // 6. Floor Collision (Canvas Bottom Surface)
  if (player.y + player.height >= canvas.height) {
    player.y = canvas.height - player.height; // Snap player to floor surface
    player.vy = 0;                            // Stop downward motion
    player.grounded = true;                   // Allow jumping again
  }
}

function draw() {
  // Clear previous frame
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  // Draw floor line indicator
  ctx.strokeStyle = '#334155';
  ctx.lineWidth = 4;
  ctx.beginPath();
  ctx.moveTo(0, canvas.height);
  ctx.lineTo(canvas.width, canvas.height);
  ctx.stroke();

  // Draw Player
  ctx.fillStyle = player.color;
  ctx.fillRect(player.x, player.y, player.width, player.height);
}

function gameLoop() {
  update();
  draw();
  requestAnimationFrame(gameLoop);
}

gameLoop();