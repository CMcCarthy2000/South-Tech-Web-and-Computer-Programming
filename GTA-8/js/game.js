(() => {
  "use strict";

  const canvas = document.querySelector("#game");
  const gl = canvas.getContext("webgl", { antialias: true, alpha: false });
  const errorMessage = document.querySelector("#error-message");

  if (!gl) {
    errorMessage.classList.remove("hidden");
    return;
  }

  const vertexSource = `
    attribute vec3 aPosition;
    attribute vec3 aNormal;
    attribute vec3 aColor;
    uniform mat4 uProjection;
    uniform mat4 uView;
    uniform mat4 uModel;
    varying float vLight;
    varying vec3 vColor;
    void main() {
      vec3 normal = normalize(mat3(uModel) * aNormal);
      vLight = 0.62 + 0.38 * max(dot(normal, normalize(vec3(-0.45, 0.82, 0.34))), 0.0);
      vColor = aColor;
      gl_Position = uProjection * uView * uModel * vec4(aPosition, 1.0);
    }
  `;

  const fragmentSource = `
    precision mediump float;
    varying float vLight;
    varying vec3 vColor;
    void main() {
      gl_FragColor = vec4(vColor * vLight, 1.0);
    }
  `;

  function makeShader(type, source) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
      const error = gl.getShaderInfoLog(shader);
      gl.deleteShader(shader);
      throw new Error(`Could not compile the 3D game shader: ${error}`);
    }
    return shader;
  }

  function makeProgram() {
    const program = gl.createProgram();
    gl.attachShader(program, makeShader(gl.VERTEX_SHADER, vertexSource));
    gl.attachShader(program, makeShader(gl.FRAGMENT_SHADER, fragmentSource));
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      throw new Error(`Could not start the 3D game: ${gl.getProgramInfoLog(program)}`);
    }
    return program;
  }

  let program;
  try {
    program = makeProgram();
  } catch (error) {
    console.error(error);
    errorMessage.textContent = error.message;
    errorMessage.classList.remove("hidden");
    return;
  }

  const cubeVertices = [];
  const faces = [
    { normal: [0, 0, 1], corners: [[-1, -1, 1], [1, -1, 1], [1, 1, 1], [-1, 1, 1]] },
    { normal: [0, 0, -1], corners: [[1, -1, -1], [-1, -1, -1], [-1, 1, -1], [1, 1, -1]] },
    { normal: [1, 0, 0], corners: [[1, -1, 1], [1, -1, -1], [1, 1, -1], [1, 1, 1]] },
    { normal: [-1, 0, 0], corners: [[-1, -1, -1], [-1, -1, 1], [-1, 1, 1], [-1, 1, -1]] },
    { normal: [0, 1, 0], corners: [[-1, 1, 1], [1, 1, 1], [1, 1, -1], [-1, 1, -1]] },
    { normal: [0, -1, 0], corners: [[-1, -1, -1], [1, -1, -1], [1, -1, 1], [-1, -1, 1]] }
  ];

  for (const face of faces) {
    const order = [0, 1, 2, 0, 2, 3];
    for (const index of order) cubeVertices.push(...face.corners[index], ...face.normal);
  }

  const vertexBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(cubeVertices), gl.STATIC_DRAW);
  gl.useProgram(program);

  const positionAttribute = gl.getAttribLocation(program, "aPosition");
  const normalAttribute = gl.getAttribLocation(program, "aNormal");
  const colorAttribute = gl.getAttribLocation(program, "aColor");
  const projectionUniform = gl.getUniformLocation(program, "uProjection");
  const viewUniform = gl.getUniformLocation(program, "uView");
  const modelUniform = gl.getUniformLocation(program, "uModel");
  gl.enableVertexAttribArray(positionAttribute);
  gl.enableVertexAttribArray(normalAttribute);
  gl.enableVertexAttribArray(colorAttribute);
  gl.vertexAttribPointer(positionAttribute, 3, gl.FLOAT, false, 24, 0);
  gl.vertexAttribPointer(normalAttribute, 3, gl.FLOAT, false, 24, 12);
  gl.enable(gl.DEPTH_TEST);
  gl.enable(gl.CULL_FACE);
  gl.cullFace(gl.BACK);

  const objects = [];
  const buildings = [];
  let staticWorld;
  const packages = [
    { x: -270, z: -270 }, { x: -90, z: -270 }, { x: 90, z: -180 }, { x: 270, z: -90 },
    { x: 270, z: 90 }, { x: 90, z: 180 }, { x: -90, z: 270 }, { x: -270, z: 180 }
  ].map(item => ({ ...item, collected: false }));
  const start = { x: 0, z: 0 };
  const car = { x: 0, z: -6, yaw: 0, speed: 0 };
  const keys = new Set();
  const mobileControls = new Set();
  let phase = "intro";
  let lastFrame = 0;
  let elapsed = 0;
  let toastTimer = 0;
  let toastElement;
  let crashCooldown = 0;

  const locations = [
    "SOUTH BOHAN", "DOWNTOWN", "BROKER HEIGHTS", "CHINATOWN", "EAST ISLAND",
    "HOVE BEACH", "LIBERTY CITY", "STAR JUNCTION", "ALDERNEY"
  ];

  function addBox(x, y, z, sx, sy, sz, color, yaw = 0, extra = {}) {
    const object = { x, y, z, sx, sy, sz, color, yaw, ...extra };
    objects.push(object);
    return object;
  }

  function seededRandom(seed) {
    let value = seed >>> 0;
    return () => {
      value = (value * 1664525 + 1013904223) >>> 0;
      return value / 4294967296;
    };
  }

  const random = seededRandom(808);
  const roadColor = [0.19, 0.22, 0.22];
  const sidewalkColor = [0.49, 0.52, 0.48];
  const grassColor = [0.27, 0.36, 0.29];
  addBox(0, -0.45, 0, 780, 0.4, 780, grassColor);

  for (let grid = -360; grid <= 360; grid += 90) {
    addBox(grid, -0.08, 0, 21, 0.12, 780, roadColor);
    addBox(0, -0.08, grid, 780, 0.12, 21, roadColor);
    addBox(grid - 12, 0, 0, 2.7, 0.16, 780, sidewalkColor);
    addBox(grid + 12, 0, 0, 2.7, 0.16, 780, sidewalkColor);
    addBox(0, 0, grid - 12, 780, 0.16, 2.7, sidewalkColor);
    addBox(0, 0, grid + 12, 780, 0.16, 2.7, sidewalkColor);

    for (let position = -350; position < 350; position += 28) {
      addBox(grid, 0.012, position, 0.18, 0.025, 8, [0.67, 0.65, 0.55]);
      addBox(position, 0.012, grid, 8, 0.025, 0.18, [0.67, 0.65, 0.55]);
    }
  }

  const buildingColors = [
    [0.49, 0.47, 0.42], [0.55, 0.50, 0.42], [0.38, 0.45, 0.44],
    [0.52, 0.43, 0.38], [0.44, 0.47, 0.46], [0.58, 0.53, 0.43]
  ];

  for (let gx = -360; gx < 360; gx += 90) {
    for (let gz = -360; gz < 360; gz += 90) {
      for (const dx of [21, 64]) {
        for (const dz of [21, 64]) {
          const x = gx + dx;
          const z = gz + dz;
          const width = 15 + random() * 6;
          const depth = 15 + random() * 6;
          const height = 13 + random() * 43;
          const color = buildingColors[Math.floor(random() * buildingColors.length)];
          const building = { x, z, width, depth };
          buildings.push(building);

          addBox(x, height / 2, z, width, height / 2, depth, color);
          addBox(x, height + 0.16, z, width * 0.91, 0.22, depth * 0.91, [0.31, 0.34, 0.33]);

          const windowColor = random() > 0.45 ? [0.56, 0.67, 0.67] : [0.68, 0.57, 0.39];
          for (let row = 1; row < Math.min(5, Math.floor(height / 5)); row++) {
            for (const side of [-1, 1]) {
              const windowWidth = 1.35;
              addBox(x + side * (width / 2 + 0.025), row * 4.1, z, 0.08, 0.85, windowWidth, windowColor);
              addBox(x, row * 4.1, z + side * (depth / 2 + 0.025), windowWidth, 0.85, 0.08, windowColor);
            }
          }

          staticWorld = buildStaticWorld(objects);
          objects.length = 0;

          if (random() > 0.56) {
            addBox(x - 2, height + 0.8, z, 1.5, 0.55, 1.5, [0.35, 0.38, 0.36]);
          }
        }
      }
    }
  }

  const carParts = [
    { x: 0, y: 1.05, z: 0, sx: 1.3, sy: 0.52, sz: 2.35, color: [0.78, 0.16, 0.12] },
    { x: 0, y: 1.62, z: -0.25, sx: 1.03, sy: 0.52, sz: 1.08, color: [0.62, 0.68, 0.63] },
    { x: 0, y: 1.07, z: 2.15, sx: 1.2, sy: 0.28, sz: 0.2, color: [0.8, 0.79, 0.68] },
    { x: 0, y: 0.79, z: -2.13, sx: 1.2, sy: 0.23, sz: 0.18, color: [0.24, 0.25, 0.25] }
  ];
  for (const side of [-1, 1]) {
    for (const front of [-1, 1]) {
      carParts.push({ x: side * 1.22, y: 0.57, z: front * 1.45, sx: 0.24, sy: 0.48, sz: 0.52, color: [0.12, 0.13, 0.13] });
    }
  }

  function resize() {
    const pixelRatio = Math.min(window.devicePixelRatio || 1, 2);
    const width = Math.floor(canvas.clientWidth * pixelRatio);
    const height = Math.floor(canvas.clientHeight * pixelRatio);
    if (canvas.width !== width || canvas.height !== height) {
      canvas.width = width;
      canvas.height = height;
      gl.viewport(0, 0, width, height);
    }
  }

  function perspective(fov, aspect, near, far) {
    const f = 1 / Math.tan(fov / 2);
    const range = 1 / (near - far);
    return new Float32Array([
      f / aspect, 0, 0, 0,
      0, f, 0, 0,
      0, 0, (near + far) * range, -1,
      0, 0, near * far * range * 2, 0
    ]);
  }

  function subtract(a, b) { return [a[0] - b[0], a[1] - b[1], a[2] - b[2]]; }
  function cross(a, b) { return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]; }
  function normalize(vector) {
    const length = Math.hypot(vector[0], vector[1], vector[2]) || 1;
    return [vector[0] / length, vector[1] / length, vector[2] / length];
  }
  function dot(a, b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }

  function lookAt(eye, center) {
    const z = normalize(subtract(eye, center));
    const x = normalize(cross([0, 1, 0], z));
    const y = cross(z, x);
    return new Float32Array([
      x[0], y[0], z[0], 0,
      x[1], y[1], z[1], 0,
      x[2], y[2], z[2], 0,
      -dot(x, eye), -dot(y, eye), -dot(z, eye), 1
    ]);
  }

  function modelMatrix(item, cameraTime = 0) {
    const angle = item.yaw + (item.spin ? cameraTime * item.spin : 0);
    const cosine = Math.cos(angle);
    const sine = Math.sin(angle);
    return new Float32Array([
      cosine * item.sx, 0, -sine * item.sx, 0,
      0, item.sy, 0, 0,
      sine * item.sz, 0, cosine * item.sz, 0,
      item.x, item.y, item.z, 1
    ]);
  }

  function buildStaticWorld(items) {
    const data = [];
    for (const item of items) {
      const cosine = Math.cos(item.yaw);
      const sine = Math.sin(item.yaw);
      for (let index = 0; index < cubeVertices.length; index += 6) {
        const px = cubeVertices[index] * item.sx;
        const py = cubeVertices[index + 1] * item.sy;
        const pz = cubeVertices[index + 2] * item.sz;
        const nx = cubeVertices[index + 3];
        const ny = cubeVertices[index + 4];
        const nz = cubeVertices[index + 5];
        data.push(
          item.x + cosine * px + sine * pz,
          item.y + py,
          item.z - sine * px + cosine * pz,
          cosine * nx + sine * nz,
          ny,
          -sine * nx + cosine * nz,
          item.color[0], item.color[1], item.color[2]
        );
      }
    }

    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(data), gl.STATIC_DRAW);
    return { buffer, count: data.length / 9 };
  }

  function drawStaticWorld() {
    gl.bindBuffer(gl.ARRAY_BUFFER, staticWorld.buffer);
    gl.enableVertexAttribArray(positionAttribute);
    gl.enableVertexAttribArray(normalAttribute);
    gl.enableVertexAttribArray(colorAttribute);
    gl.vertexAttribPointer(positionAttribute, 3, gl.FLOAT, false, 36, 0);
    gl.vertexAttribPointer(normalAttribute, 3, gl.FLOAT, false, 36, 12);
    gl.vertexAttribPointer(colorAttribute, 3, gl.FLOAT, false, 36, 24);
    gl.uniformMatrix4fv(modelUniform, false, new Float32Array([
      1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1
    ]));
    gl.drawArrays(gl.TRIANGLES, 0, staticWorld.count);
  }

  function drawBox(item, cameraTime = 0) {
    gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    gl.enableVertexAttribArray(positionAttribute);
    gl.enableVertexAttribArray(normalAttribute);
    gl.disableVertexAttribArray(colorAttribute);
    gl.vertexAttribPointer(positionAttribute, 3, gl.FLOAT, false, 24, 0);
    gl.vertexAttribPointer(normalAttribute, 3, gl.FLOAT, false, 24, 12);
    gl.vertexAttrib3fv(colorAttribute, item.color);
    gl.uniformMatrix4fv(modelUniform, false, modelMatrix(item, cameraTime));
    gl.drawArrays(gl.TRIANGLES, 0, 36);
  }

  function nearestTarget() {
    const remaining = packages.filter(item => !item.collected);
    if (!remaining.length) return { x: start.x, z: start.z, home: true };
    return remaining.reduce((nearest, item) => {
      const distance = Math.hypot(item.x - car.x, item.z - car.z);
      return distance < nearest.distance ? { ...item, distance } : nearest;
    }, { distance: Infinity });
  }

  function showToast(message) {
    toastElement.textContent = message;
    toastElement.classList.add("visible");
    window.clearTimeout(toastTimer);
    toastTimer = window.setTimeout(() => toastElement.classList.remove("visible"), 2600);
  }

  function updateHud() {
    const collected = packages.filter(item => item.collected).length;
    document.querySelector("#package-count").textContent = collected;
    document.querySelector("#progress-bar").style.width = `${collected / packages.length * 100}%`;
    document.querySelector("#speed").textContent = String(Math.round(Math.abs(car.speed) * 2.1)).padStart(3, "0");

    const target = nearestTarget();
    const distance = Math.round(Math.hypot(target.x - car.x, target.z - car.z));
    document.querySelector("#objective-text").textContent = target.home ? "Meet your contact downtown" : `Find package ${collected + 1}`;
    document.querySelector("#objective-distance").textContent = `${distance} m`;
    document.querySelector("#mission-title").innerHTML = target.home ? "Meet me <em>downtown</em>" : "A little <em>pickup</em> work";
    document.querySelector("#mission-copy").textContent = target.home
      ? "All 8 packages are in. Head back to your contact."
      : "Grab the 8 packages, then meet your contact downtown.";
    document.querySelector("#progress-text").textContent = target.home ? "DELIVERY" : "PACKAGES";
    document.querySelector("#district").textContent = locations[Math.min(8, Math.floor((car.x + 390) / 90))];
    drawMinimap(target);

    if (target.home && distance < 10 && phase === "playing") {
      phase = "complete";
      document.querySelector("#complete-screen").classList.remove("hidden");
      showToast("Job complete — nice work.");
    }
  }

  function drawMinimap(target) {
    const map = document.querySelector("#minimap");
    const ctx = map.getContext("2d");
    const scale = map.width / 780;
    const centerX = map.width / 2;
    const centerY = map.height / 2;
    ctx.clearRect(0, 0, map.width, map.height);
    ctx.fillStyle = "#29342f";
    ctx.fillRect(0, 0, map.width, map.height);
    ctx.strokeStyle = "#859087";
    ctx.lineWidth = Math.max(2.4, scale * 17);
    for (let road = -360; road <= 360; road += 90) {
      const pixel = centerX + road * scale;
      ctx.beginPath(); ctx.moveTo(pixel, 0); ctx.lineTo(pixel, map.height); ctx.stroke();
      const horizontal = centerY + road * scale;
      ctx.beginPath(); ctx.moveTo(0, horizontal); ctx.lineTo(map.width, horizontal); ctx.stroke();
    }

    for (const item of packages) {
      if (item.collected) continue;
      ctx.fillStyle = "#f05a43";
      ctx.beginPath();
      ctx.arc(centerX + item.x * scale, centerY + item.z * scale, 2.8, 0, Math.PI * 2);
      ctx.fill();
    }

    if (target.home) {
      ctx.fillStyle = "#f05a43";
      ctx.beginPath();
      ctx.arc(centerX + start.x * scale, centerY + start.z * scale, 3.2, 0, Math.PI * 2);
      ctx.fill();
    }

    const px = centerX + car.x * scale;
    const pz = centerY + car.z * scale;
    ctx.save();
    ctx.translate(px, pz);
    ctx.rotate(car.yaw);
    ctx.fillStyle = "#f6f2de";
    ctx.beginPath();
    ctx.moveTo(0, -6);
    ctx.lineTo(4, 5);
    ctx.lineTo(0, 3);
    ctx.lineTo(-4, 5);
    ctx.closePath();
    ctx.fill();
    ctx.restore();
  }

  function collidesAt(x, z) {
    if (Math.abs(x) > 377 || Math.abs(z) > 377) return true;
    for (const building of buildings) {
      if (Math.abs(x - building.x) < building.width / 2 + 2.2 &&
          Math.abs(z - building.z) < building.depth / 2 + 2.2) return true;
    }
    return false;
  }

  function update(dt) {
    if (phase !== "playing") return;
    const gas = keys.has("w") || keys.has("arrowup") || mobileControls.has("gas");
    const reverse = keys.has("s") || keys.has("arrowdown") || mobileControls.has("brake");
    const left = keys.has("a") || keys.has("arrowleft") || mobileControls.has("left");
    const right = keys.has("d") || keys.has("arrowright") || mobileControls.has("right");
    const handbrake = keys.has(" ") || keys.has("space");

    if (gas) car.speed += 19 * dt;
    if (reverse) car.speed -= 25 * dt;
    if (handbrake) car.speed *= Math.max(0, 1 - 4.2 * dt);
    car.speed = Math.max(-11, Math.min(35, car.speed));
    car.speed *= Math.max(0, 1 - (gas || reverse ? 0.18 : 0.78) * dt);

    if (Math.abs(car.speed) > 0.15) {
      const steer = (right ? 1 : 0) - (left ? 1 : 0);
      const steeringSpeed = (0.32 + Math.min(Math.abs(car.speed) / 20, 1)) * (handbrake ? 1.6 : 1);
      car.yaw += steer * steeringSpeed * dt * Math.sign(car.speed);
    }

    const forwardX = Math.sin(car.yaw);
    const forwardZ = -Math.cos(car.yaw);
    const nextX = car.x + forwardX * car.speed * dt;
    const nextZ = car.z + forwardZ * car.speed * dt;

    if (!collidesAt(nextX, nextZ)) {
      car.x = nextX;
      car.z = nextZ;
    } else {
      car.speed = 0;
      if (elapsed - crashCooldown > 2) {
        showToast("Easy there — watch the buildings.");
        crashCooldown = elapsed;
      }
    }

    for (const item of packages) {
      if (!item.collected && Math.hypot(item.x - car.x, item.z - car.z) < 8) {
        item.collected = true;
        showToast(`Package ${packages.filter(entry => entry.collected).length} of 8 collected.`);
      }
    }
  }

  function render(time) {
    resize();
    const aspect = canvas.width / canvas.height;
    const forwardX = Math.sin(car.yaw);
    const forwardZ = -Math.cos(car.yaw);
    const eye = [car.x - forwardX * 28, 19, car.z - forwardZ * 28];
    const center = [car.x + forwardX * 8, 2.5, car.z + forwardZ * 8];
    gl.clearColor(0.56, 0.66, 0.68, 1);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.uniformMatrix4fv(projectionUniform, false, perspective(0.77, aspect, 0.1, 900));
    gl.uniformMatrix4fv(viewUniform, false, lookAt(eye, center));

    drawStaticWorld();

    if (packages.some(item => !item.collected)) {
      for (const item of packages) {
        if (item.collected) continue;
        drawBox({ x: item.x, y: 0.55, z: item.z, sx: 3.7, sy: 0.12, sz: 3.7, color: [0.8, 0.29, 0.12] });
        drawBox({ x: item.x, y: 1.6 + Math.sin(time * 2 + item.x) * 0.22, z: item.z, sx: 0.8, sy: 0.8, sz: 0.8, color: [0.98, 0.67, 0.25], yaw: time * 0.65, spin: 0.65 });
      }
    } else {
      drawBox({ x: start.x, y: 0.55, z: start.z, sx: 5.2, sy: 0.12, sz: 5.2, color: [0.2, 0.74, 0.56] });
      drawBox({ x: start.x, y: 1.5 + Math.sin(time * 2) * 0.2, z: start.z, sx: 0.9, sy: 1.1, sz: 0.9, color: [0.27, 0.95, 0.65], yaw: time });
    }

    for (const part of carParts) {
      const local = { ...part, x: part.x, y: part.y, z: part.z, yaw: car.yaw };
      const cosine = Math.cos(car.yaw);
      const sine = Math.sin(car.yaw);
      local.x = car.x + cosine * part.x + sine * part.z;
      local.z = car.z - sine * part.x + cosine * part.z;
      local.yaw = car.yaw;
      drawBox(local, time);
    }
  }

  function frame(timestamp) {
    const dt = Math.min((timestamp - (lastFrame || timestamp)) / 1000, 0.04);
    lastFrame = timestamp;
    elapsed += dt;
    if (phase === "playing") update(dt);
    render(elapsed);
    if (phase === "playing") {
      updateHud();
      const totalMinutes = Math.floor(elapsed / 6) + 9 * 60 + 41;
      const hour = String(Math.floor(totalMinutes / 60) % 12 || 12).padStart(2, "0");
      const minute = String(totalMinutes % 60).padStart(2, "0");
      document.querySelector("#clock").textContent = `${hour}:${minute} AM`;
    }
    requestAnimationFrame(frame);
  }

  function startGame() {
    phase = "playing";
    document.querySelector("#start-screen").classList.add("hidden");
    document.querySelector("#pause-screen").classList.add("hidden");
    document.querySelector("#complete-screen").classList.add("hidden");
    showToast("Job's simple: grab eight packages.");
  }

  function togglePause() {
    if (phase === "playing") {
      phase = "paused";
      document.querySelector("#pause-screen").classList.remove("hidden");
    } else if (phase === "paused") {
      startGame();
    }
  }

  function restartGame() {
    for (const item of packages) item.collected = false;
    car.x = 0;
    car.z = -6;
    car.yaw = 0;
    car.speed = 0;
    elapsed = 0;
    phase = "intro";
    document.querySelector("#pause-screen").classList.add("hidden");
    document.querySelector("#complete-screen").classList.add("hidden");
    document.querySelector("#start-screen").classList.remove("hidden");
    updateHud();
  }

  document.querySelector("#start-button").addEventListener("click", startGame);
  document.querySelector("#resume-button").addEventListener("click", startGame);
  document.querySelector("#pause-button").addEventListener("click", togglePause);
  document.querySelector("#restart-button").addEventListener("click", restartGame);
  document.querySelector("#play-again-button").addEventListener("click", restartGame);
  toastElement = document.querySelector("#toast");

  window.addEventListener("keydown", event => {
    const key = event.key.toLowerCase();
    if (["arrowup", "arrowdown", "arrowleft", "arrowright", " "].includes(key)) event.preventDefault();
    keys.add(key);
    if (!event.repeat && (key === "p" || key === "escape")) togglePause();
    if ((key === "enter" || key === " ") && (phase === "intro" || phase === "paused")) {
      if (event.target.tagName !== "BUTTON") startGame();
    }
  });

  window.addEventListener("keyup", event => keys.delete(event.key.toLowerCase()));
  window.addEventListener("blur", () => { keys.clear(); mobileControls.clear(); });

  document.querySelectorAll("[data-control]").forEach(button => {
    const control = button.dataset.control;
    button.addEventListener("pointerdown", event => {
      event.preventDefault();
      mobileControls.add(control);
      button.setPointerCapture(event.pointerId);
    });
    const release = () => mobileControls.delete(control);
    button.addEventListener("pointerup", release);
    button.addEventListener("pointercancel", release);
    button.addEventListener("lostpointercapture", release);
  });

  updateHud();
  requestAnimationFrame(frame);
})();
