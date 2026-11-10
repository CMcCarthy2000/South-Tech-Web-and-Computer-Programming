const planets = [
  { name: "Mercury", key: "mercury", kind: "TERRESTRIAL PLANET", color: "#b9a58b", radius: 2.4, a: 0.387, period: 87.969, e: 0.2056, inc: 7.00, node: 48.3, phase: 3.05, diameter: "4,879 km", moons: 0, velocity: 47.36, description: "The smallest planet, racing around the Sun in just 88 Earth days. Its cratered surface swings between scorching days and freezing nights." },
  { name: "Venus", key: "venus", kind: "TERRESTRIAL PLANET", color: "#e5bd83", radius: 4.1, a: 0.723, period: 224.701, e: 0.0068, inc: 3.39, node: 76.7, phase: 0.3, diameter: "12,104 km", moons: 0, velocity: 35.02, description: "A world wrapped in thick clouds. Venus rotates slowly in the opposite direction to most planets and has a surface hot enough to melt lead." },
  { name: "Earth", key: "earth", kind: "TERRESTRIAL PLANET", color: "#63a9ff", radius: 4.5, a: 1, period: 365.256, e: 0.0167, inc: 0, node: 0, phase: 1.75, diameter: "12,742 km", moons: 1, velocity: 29.78, description: "Our pale blue home. The only world we know of with liquid oceans on its surface and an abundance of life." },
  { name: "Mars", key: "mars", kind: "TERRESTRIAL PLANET", color: "#e77d5e", radius: 3.2, a: 1.524, period: 686.98, e: 0.0934, inc: 1.85, node: 49.6, phase: 5.2, diameter: "6,779 km", moons: 2, velocity: 24.07, description: "A cold desert world with giant volcanoes, ancient river valleys, and two tiny moons. Robotic explorers are mapping its surface." },
  { name: "Jupiter", key: "jupiter", kind: "GAS GIANT", color: "#e8bd91", radius: 9.2, a: 5.203, period: 4332.59, e: 0.0489, inc: 1.30, node: 100.5, phase: 2.1, diameter: "139,820 km", moons: 95, velocity: 13.07, description: "King of the planets: a gas giant with swirling cloud bands, a powerful magnetic field, and a storm larger than Earth." },
  { name: "Saturn", key: "saturn", kind: "GAS GIANT", color: "#e2cf9a", radius: 7.8, a: 9.537, period: 10759.2, e: 0.0565, inc: 2.49, node: 113.7, phase: 5.8, diameter: "116,460 km", moons: 146, velocity: 9.69, rings: true, description: "A gas giant encircled by spectacular rings of ice and rock. Its moon Titan has lakes and seas made of liquid methane." },
  { name: "Uranus", key: "uranus", kind: "ICE GIANT", color: "#83d4db", radius: 6.1, a: 19.191, period: 30688.5, e: 0.0472, inc: 0.77, node: 74.0, phase: 0.9, diameter: "50,724 km", moons: 28, velocity: 6.81, description: "An ice giant with a blue-green atmosphere. Uranus spins tipped dramatically onto its side, giving it some of the most extreme seasons." },
  { name: "Neptune", key: "neptune", kind: "ICE GIANT", color: "#577cf5", radius: 5.9, a: 30.07, period: 60182, e: 0.0086, inc: 1.77, node: 131.8, phase: 4.3, diameter: "49,244 km", moons: 16, velocity: 5.43, description: "A distant, deep-blue world swept by supersonic winds. It takes Neptune about 165 Earth years to complete a trip around the Sun." },
  { name: "Pluto", key: "pluto", kind: "DWARF PLANET", color: "#bd9e82", radius: 2, a: 39.482, period: 90560, e: 0.2488, inc: 17.16, node: 110.3, phase: 5.4, diameter: "2,377 km", moons: 5, velocity: 4.74, description: "A small, icy dwarf planet with a heart-shaped glacier and five moons. Pluto's eccentric, tilted orbit sometimes brings it closer than Neptune." }
];

const canvas = document.querySelector("#solar-canvas");
const ctx = canvas.getContext("2d");
const wrap = document.querySelector("#canvas-wrap");
const tooltip = document.querySelector("#canvas-tooltip");
const dateReadout = document.querySelector("#date-readout");
const speedSlider = document.querySelector("#speed-slider");
const speedReadout = document.querySelector("#speed-readout");
const cameraSlider = document.querySelector("#camera-slider");
const cameraReadout = document.querySelector("#camera-readout");
const scaleReadout = document.querySelector("#view-scale");
const coordinateReadout = document.querySelector("#coordinate-readout");
const emptyHint = document.querySelector("#empty-hint");
const planetList = document.querySelector("#planet-list");

const speedValues = [0, 0.25, 0.5, 1, 3, 10, 30];
const speedLabels = ["paused", "¼ day / sec", "½ day / sec", "1 day / sec", "3 days / sec", "10 days / sec", "30 days / sec"];
const DAY_MS = 86400000;
const baseDate = Date.UTC(2025, 0, 1);
let simDays = 0;
let selected = null;
let running = true;
let showLabels = true;
let showOrbits = true;
let showTrails = false;
let zoom = 1;
let panX = 0;
let panY = 0;
let lastFrame = 0;
let lastSpeed = 2;
let canvasWidth = 0;
let canvasHeight = 0;
let dpr = 1;
let drag = null;
let hovered = null;
let stars = [];
let trailPoints = new Map(planets.map(body => [body.key, []]));
let animFrame;
let resizeObserver;

const rad = degrees => degrees * Math.PI / 180;
const formatDate = days => new Intl.DateTimeFormat("en-US", { month: "short", day: "2-digit", year: "numeric", timeZone: "UTC" }).format(new Date(baseDate + days * DAY_MS)).toUpperCase();
const orbitRadius = a => maxOrbitRadius() * Math.log1p(a) / Math.log1p(40);
function maxOrbitRadius() { return Math.min(canvasWidth, canvasHeight) * 0.465; }

function resize() {
  const rect = wrap.getBoundingClientRect();
  dpr = Math.min(window.devicePixelRatio || 1, 2);
  canvasWidth = rect.width;
  canvasHeight = rect.height;
  canvas.width = Math.round(canvasWidth * dpr);
  canvas.height = Math.round(canvasHeight * dpr);
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  stars = Array.from({ length: Math.floor(canvasWidth * canvasHeight / 2200) }, (_, i) => {
    const seed = Math.sin(i * 127.1 + 311.7) * 43758.5453;
    const seed2 = Math.sin(i * 269.5 + 183.3) * 12741.337;
    return { x: (seed - Math.floor(seed)) * canvasWidth, y: (seed2 - Math.floor(seed2)) * canvasHeight, alpha: 0.18 + (i % 7) * 0.07, size: i % 19 === 0 ? 1.35 : 0.7 };
  });
}

function solveOrbit(body, days) {
  const meanAnomaly = body.phase + (Math.PI * 2 * days / body.period);
  let eccentricAnomaly = meanAnomaly;
  for (let i = 0; i < 7; i++) eccentricAnomaly -= (eccentricAnomaly - body.e * Math.sin(eccentricAnomaly) - meanAnomaly) / (1 - body.e * Math.cos(eccentricAnomaly));
  const x = body.a * (Math.cos(eccentricAnomaly) - body.e);
  const y = body.a * Math.sqrt(1 - body.e * body.e) * Math.sin(eccentricAnomaly);
  const node = rad(body.node);
  const inclination = rad(body.inc);
  const rotatedX = x * Math.cos(node) - y * Math.cos(inclination) * Math.sin(node);
  const rotatedY = x * Math.sin(node) + y * Math.cos(inclination) * Math.cos(node);
  const rotatedZ = y * Math.sin(inclination);
  return { x: rotatedX, y: rotatedY, z: rotatedZ, anomaly: eccentricAnomaly };
}

function centerPoint() {
  return { x: canvasWidth / 2 + panX, y: canvasHeight / 2 + panY };
}

function screenPosition(body, center) {
  const pos = solveOrbit(body, simDays);
  return projectWorld(pos.x, pos.y, pos.z, center, orbitRadius(body.a) / body.a);
}

function projectWorld(x, y, z, center, scale) {
  const yaw = rad(-24);
  const pitch = rad(90 - Number(cameraSlider.value));
  const yawX = x * Math.cos(yaw) - y * Math.sin(yaw);
  const yawY = x * Math.sin(yaw) + y * Math.cos(yaw);
  const cameraY = yawY * Math.cos(pitch) - z * Math.sin(pitch);
  const depth = yawY * Math.sin(pitch) + z * Math.cos(pitch);
  const focalLength = maxOrbitRadius() * 2.4;
  const perspective = Math.max(.58, Math.min(1.7, focalLength / (focalLength - depth * scale * zoom)));
  const screenScale = scale * zoom * perspective;
  return {
    x: center.x + yawX * screenScale,
    y: center.y - cameraY * screenScale,
    depth: depth * scale * zoom,
    perspective
  };
}

function drawStars() {
  stars.forEach(star => {
    ctx.globalAlpha = star.alpha;
    ctx.fillStyle = "#dce9ff";
    ctx.fillRect(star.x, star.y, star.size, star.size);
  });
  ctx.globalAlpha = 1;
}

function drawOrbit(body, center) {
  const baseRadius = orbitRadius(body.a) * zoom;
  if (baseRadius < 2 || baseRadius > Math.max(canvasWidth, canvasHeight) * 3) return;
  const inclination = rad(body.inc);
  const node = rad(body.node);
  const scale = orbitRadius(body.a) / body.a;
  ctx.beginPath();
  for (let i = 0; i <= 144; i++) {
    const anomaly = i / 144 * Math.PI * 2;
    const orbitX = body.a * (Math.cos(anomaly) - body.e);
    const orbitY = body.a * Math.sqrt(1 - body.e * body.e) * Math.sin(anomaly);
    const point = projectWorld(
      orbitX * Math.cos(node) - orbitY * Math.cos(inclination) * Math.sin(node),
      orbitX * Math.sin(node) + orbitY * Math.cos(inclination) * Math.cos(node),
      orbitY * Math.sin(inclination),
      center,
      scale
    );
    if (i === 0) ctx.moveTo(point.x, point.y); else ctx.lineTo(point.x, point.y);
  }
  ctx.closePath();
  ctx.strokeStyle = body === selected ? `${body.color}92` : "#283447";
  ctx.lineWidth = body === selected ? 1.2 : 0.7;
  ctx.setLineDash(body === selected ? [] : [2, 4]);
  ctx.stroke();
  ctx.setLineDash([]);
}

function drawSun(center) {
  const radius = Math.max(5, 9 * Math.sqrt(zoom));
  const glow = ctx.createRadialGradient(center.x, center.y, 0, center.x, center.y, radius * 6);
  glow.addColorStop(0, "#ffe9a8b8");
  glow.addColorStop(.15, "#f5b94642");
  glow.addColorStop(1, "#f5b90000");
  ctx.fillStyle = glow;
  ctx.beginPath();
  ctx.arc(center.x, center.y, radius * 6, 0, Math.PI * 2);
  ctx.fill();
  ctx.beginPath();
  ctx.arc(center.x, center.y, radius, 0, Math.PI * 2);
  const surface = ctx.createRadialGradient(center.x - radius * .3, center.y - radius * .35, 0, center.x, center.y, radius);
  surface.addColorStop(0, "#fff9db");
  surface.addColorStop(.55, "#ffe4a0");
  surface.addColorStop(1, "#d88935");
  ctx.fillStyle = surface;
  ctx.shadowColor = "#ffca62";
  ctx.shadowBlur = 20;
  ctx.fill();
  ctx.shadowBlur = 0;
  if (showLabels) drawLabel("SUN", center.x, center.y, radius);
}

function drawPlanet(body, position) {
  const radius = Math.max(body.radius * Math.pow(zoom, 0.18) * position.perspective, 1.5);
  if (body.rings) {
    ctx.save();
    ctx.translate(position.x, position.y);
    ctx.rotate(-0.2 - rad(Number(cameraSlider.value) - 32) * .14);
    ctx.beginPath();
    ctx.ellipse(0, 0, radius * 1.95, radius * 0.48, 0, 0, Math.PI * 2);
    ctx.strokeStyle = "#e8d2a3a8";
    ctx.lineWidth = Math.max(2, radius * 0.38);
    ctx.stroke();
    ctx.beginPath();
    ctx.ellipse(0, 0, radius * 1.55, radius * 0.35, 0, 0, Math.PI * 2);
    ctx.strokeStyle = "#80745d";
    ctx.lineWidth = 1;
    ctx.stroke();
    ctx.restore();
  }
  const gradient = ctx.createRadialGradient(position.x - radius * .4, position.y - radius * .38, radius * .04, position.x + radius * .15, position.y + radius * .12, radius * 1.25);
  gradient.addColorStop(0, "#ffffff");
  gradient.addColorStop(.12, lighten(body.color));
  gradient.addColorStop(.62, body.color);
  gradient.addColorStop(1, "#080b13");
  ctx.beginPath();
  ctx.arc(position.x, position.y, radius, 0, Math.PI * 2);
  ctx.fillStyle = gradient;
  ctx.shadowColor = body.color;
  ctx.shadowBlur = body === selected || body === hovered ? 14 : 5;
  ctx.fill();
  ctx.shadowBlur = 0;
  if (body === selected || body === hovered) {
    ctx.beginPath();
    ctx.arc(position.x, position.y, radius + 4, 0, Math.PI * 2);
    ctx.strokeStyle = body === selected ? "#dceeff" : "#91a5bc";
    ctx.lineWidth = 1;
    ctx.stroke();
  }
  if (showLabels) drawLabel(body.name.toUpperCase(), position.x, position.y, radius);
}

function lighten(hex) {
  const value = Number.parseInt(hex.slice(1), 16);
  const r = Math.min(255, ((value >> 16) & 255) + 60);
  const g = Math.min(255, ((value >> 8) & 255) + 60);
  const b = Math.min(255, (value & 255) + 60);
  return `rgb(${r},${g},${b})`;
}

function drawLabel(text, x, y, radius) {
  ctx.font = "8px 'DM Mono', Consolas, monospace";
  ctx.textAlign = "center";
  ctx.textBaseline = "top";
  ctx.fillStyle = "#a9b5c8";
  ctx.fillText(text, x, y + radius + 6);
}

function drawAsteroids(center) {
  const inner = orbitRadius(2.15) * zoom;
  const outer = orbitRadius(3.2) * zoom;
  if (outer < 18 || inner > Math.max(canvasWidth, canvasHeight) * 2) return;
  ctx.fillStyle = "#9c8b6c";
  for (let i = 0; i < 600; i++) {
    const fraction = (i * 0.61803398875) % 1;
    const angle = i * 2.399963;
    const semiMajor = 2.15 + (3.2 - 2.15) * fraction;
    const scale = orbitRadius(semiMajor) / semiMajor;
    const wobble = 1 + .035 * Math.sin(i * 9.7);
    const point = projectWorld(Math.cos(angle) * semiMajor * wobble, Math.sin(angle) * semiMajor * wobble, Math.sin(i * 1.7) * .025, center, scale);
    const x = point.x;
    const y = point.y;
    if (x > 0 && x < canvasWidth && y > 0 && y < canvasHeight) {
      ctx.globalAlpha = .25 + (i % 5) * .1;
      ctx.fillRect(x, y, i % 9 === 0 ? 1.5 : 1, i % 9 === 0 ? 1.5 : 1);
    }
  }
  ctx.globalAlpha = 1;
}

function drawTrails() {
  planets.forEach(body => {
    const points = trailPoints.get(body.key) || [];
    if (points.length < 2) return;
    ctx.beginPath();
    points.forEach((point, index) => {
      if (index === 0) ctx.moveTo(point.x, point.y); else ctx.lineTo(point.x, point.y);
    });
    ctx.strokeStyle = `${body.color}70`;
    ctx.lineWidth = 1.1;
    ctx.stroke();
  });
}

function render(timestamp = 0) {
  const delta = Math.min((timestamp - (lastFrame || timestamp)) / 1000, .1);
  lastFrame = timestamp;
  if (running) simDays += delta * speedValues[Number(speedSlider.value)];
  ctx.clearRect(0, 0, canvasWidth, canvasHeight);
  drawStars();
  const center = centerPoint();
  if (showOrbits) planets.forEach(body => drawOrbit(body, center));
  drawAsteroids(center);
  if (showTrails) drawTrails();
  const positions = planets.map(body => ({ body, ...screenPosition(body, center) }));
  positions.forEach(({ body, x, y }) => {
    if (showTrails && running && timestamp % 3 < 1) {
      const points = trailPoints.get(body.key);
      points.push({ x, y });
      if (points.length > 300) points.shift();
    }
  });
  const renderables = [{ body: null, x: center.x, y: center.y, depth: 0 }, ...positions].sort((a, b) => a.depth - b.depth);
  renderables.forEach(item => {
    if (item.body) drawPlanet(item.body, item);
    else drawSun(center);
  });
  dateReadout.textContent = formatDate(simDays);
  const radius = orbitRadius(39.482) * zoom;
  const allVisible = center.x - radius > 0 && center.x + radius < canvasWidth && center.y - radius > 0 && center.y + radius < canvasHeight;
  emptyHint.hidden = allVisible || zoom < .32;
  scaleReadout.textContent = `SCALE ${zoom.toFixed(1)}×`;
  coordinateReadout.textContent = running ? "SIMULATION ACTIVE" : "SIMULATION PAUSED";
  animFrame = requestAnimationFrame(render);
}

function updateInspector(body) {
  selected = body;
  if (!body) {
    document.querySelector("#object-symbol").textContent = "☉";
    document.querySelector("#object-symbol").style.color = "#f5c46b";
    document.querySelector("#object-kind").textContent = "G2V · MAIN-SEQUENCE STAR";
    document.querySelector("#object-name").textContent = "The Sun";
    document.querySelector("#object-description").textContent = "The star at the center of our solar system. Its gravity keeps the planets in their steady dance.";
    document.querySelector("#data-distance").textContent = "—";
    document.querySelector("#data-period").textContent = "—";
    document.querySelector("#data-diameter").textContent = "1.39 M km";
    document.querySelector("#data-moons").textContent = "—";
    document.querySelector("#data-moons-sub").textContent = "known satellites";
    document.querySelector("#data-ecc").textContent = "—";
    document.querySelector("#data-inc").textContent = "—";
    document.querySelector("#data-velocity").textContent = "—";
  } else {
    document.querySelector("#object-symbol").textContent = "●";
    document.querySelector("#object-symbol").style.color = body.color;
    document.querySelector("#object-kind").textContent = body.kind;
    document.querySelector("#object-name").textContent = body.name;
    document.querySelector("#object-description").textContent = body.description;
    document.querySelector("#data-distance").textContent = `${body.a} AU`;
    document.querySelector("#data-period").textContent = body.period >= 365 ? `${(body.period / 365.256).toFixed(2)} yr` : `${body.period.toFixed(1)} days`;
    document.querySelector("#data-diameter").textContent = body.diameter;
    document.querySelector("#data-moons").textContent = body.moons;
    document.querySelector("#data-moons-sub").textContent = body.moons === 1 ? "known satellite" : "known satellites";
    document.querySelector("#data-ecc").textContent = body.e.toFixed(4);
    document.querySelector("#data-inc").textContent = `${body.inc.toFixed(2)}°`;
    document.querySelector("#data-velocity").textContent = `${body.velocity.toFixed(2)} km/s`;
  }
  document.querySelectorAll(".planet-choice").forEach(button => button.setAttribute("aria-pressed", String(body?.key === button.dataset.planet)));
}

function buildPlanetPicker() {
  planets.forEach(body => {
    const button = document.createElement("button");
    button.className = "planet-choice";
    button.type = "button";
    button.dataset.planet = body.key;
    button.setAttribute("aria-pressed", "false");
    button.setAttribute("aria-label", `Inspect ${body.name}`);
    button.innerHTML = `<span class="planet-dot" style="color:${body.color};background:${body.color}"></span><span>${body.name}</span>`;
    button.addEventListener("click", () => updateInspector(body));
    planetList.append(button);
  });
}

function findBodyAt(x, y) {
  const center = centerPoint();
  const positions = planets.map(body => ({ body, ...screenPosition(body, center) })).reverse();
  for (const point of positions) {
    const hitRadius = Math.max(point.body.radius * Math.pow(zoom, .18) * point.perspective, 8) + 6;
    if (Math.hypot(point.x - x, point.y - y) < hitRadius) return point.body;
  }
  return null;
}

function changeZoom(factor, pointX = canvasWidth / 2, pointY = canvasHeight / 2) {
  const oldZoom = zoom;
  zoom = Math.max(.22, Math.min(6, zoom * factor));
  const multiplier = zoom / oldZoom;
  const c = { x: canvasWidth / 2 + panX, y: canvasHeight / 2 + panY };
  panX = pointX - (pointX - c.x) * multiplier - canvasWidth / 2;
  panY = pointY - (pointY - c.y) * multiplier - canvasHeight / 2;
}

function toggle(button, callback) {
  const enabled = button.getAttribute("aria-pressed") !== "true";
  button.setAttribute("aria-pressed", String(enabled));
  button.classList.toggle("active", enabled);
  button.querySelector("b").textContent = enabled ? "ON" : "OFF";
  callback(enabled);
}

buildPlanetPicker();
updateInspector(null);
resize();
resizeObserver = new ResizeObserver(resize);
resizeObserver.observe(wrap);
requestAnimationFrame(render);

document.querySelector("#play-button").addEventListener("click", event => {
  if (!running && speedSlider.value === "0") {
    speedSlider.value = String(lastSpeed);
    speedReadout.textContent = speedLabels[lastSpeed];
    running = true;
  } else {
    running = !running;
  }
  event.currentTarget.textContent = running ? "Ⅱ" : "▶";
  event.currentTarget.setAttribute("aria-label", running ? "Pause simulation" : "Resume simulation");
  event.currentTarget.title = running ? "Pause" : "Resume";
});
document.querySelector("#step-back").addEventListener("click", () => { simDays -= 1; });
document.querySelector("#step-forward").addEventListener("click", () => { simDays += 1; });
speedSlider.addEventListener("input", () => {
  const index = Number(speedSlider.value);
  speedReadout.textContent = speedLabels[index];
  if (index > 0) lastSpeed = index;
  if (index === 0) running = false;
  else running = true;
  const button = document.querySelector("#play-button");
  button.textContent = running ? "Ⅱ" : "▶";
  button.setAttribute("aria-label", running ? "Pause simulation" : "Resume simulation");
});
document.querySelector("#labels-toggle").addEventListener("click", event => toggle(event.currentTarget, value => { showLabels = value; }));
document.querySelector("#orbits-toggle").addEventListener("click", event => toggle(event.currentTarget, value => { showOrbits = value; }));
document.querySelector("#trails-toggle").addEventListener("click", event => toggle(event.currentTarget, value => {
  showTrails = value;
  if (!value) trailPoints.forEach(points => points.splice(0));
}));
document.querySelector("#reset-button").addEventListener("click", () => {
  simDays = 0;
  zoom = 1;
  panX = 0;
  panY = 0;
  cameraSlider.value = "32";
  cameraReadout.textContent = "32°";
  running = true;
  speedSlider.value = String(lastSpeed);
  speedReadout.textContent = speedLabels[lastSpeed];
  document.querySelector("#play-button").textContent = "Ⅱ";
  document.querySelector("#play-button").setAttribute("aria-label", "Pause simulation");
  updateInspector(null);
  trailPoints.forEach(points => points.splice(0));
});
cameraSlider.addEventListener("input", () => {
  cameraReadout.textContent = `${cameraSlider.value}°`;
  trailPoints.forEach(points => points.splice(0));
});

wrap.addEventListener("wheel", event => {
  event.preventDefault();
  const rect = canvas.getBoundingClientRect();
  changeZoom(event.deltaY < 0 ? 1.12 : 1 / 1.12, event.clientX - rect.left, event.clientY - rect.top);
}, { passive: false });
wrap.addEventListener("pointerdown", event => {
  if (event.button !== 0) return;
  const rect = canvas.getBoundingClientRect();
  drag = { startX: event.clientX, startY: event.clientY, panX, panY, moved: false, pointX: event.clientX - rect.left, pointY: event.clientY - rect.top };
  wrap.setPointerCapture(event.pointerId);
});
wrap.addEventListener("pointermove", event => {
  const rect = canvas.getBoundingClientRect();
  if (drag) {
    const dx = event.clientX - drag.startX;
    const dy = event.clientY - drag.startY;
    if (Math.abs(dx) + Math.abs(dy) > 4) drag.moved = true;
    panX = drag.panX + dx;
    panY = drag.panY + dy;
    canvas.style.cursor = drag.moved ? "grabbing" : "crosshair";
    return;
  }
  hovered = findBodyAt(event.clientX - rect.left, event.clientY - rect.top);
  canvas.style.cursor = hovered ? "pointer" : "grab";
  if (hovered) {
    tooltip.style.display = "block";
    tooltip.textContent = `${hovered.name.toUpperCase()} · ${hovered.a} AU`;
    tooltip.style.left = `${Math.min(event.clientX - rect.left + 12, rect.width - 130)}px`;
    tooltip.style.top = `${Math.min(event.clientY - rect.top + 12, rect.height - 30)}px`;
  } else tooltip.style.display = "none";
});
wrap.addEventListener("pointerup", () => {
  if (drag && !drag.moved) {
    const body = findBodyAt(drag.pointX, drag.pointY);
    if (body) updateInspector(body);
    else if (Math.hypot(drag.pointX - centerPoint().x, drag.pointY - centerPoint().y) < 14) updateInspector(null);
  }
  drag = null;
  canvas.style.cursor = hovered ? "pointer" : "grab";
});
wrap.addEventListener("pointercancel", () => { drag = null; });

const helpModal = document.querySelector("#help-modal");
document.querySelector("#help-button").addEventListener("click", () => { helpModal.hidden = false; document.querySelector("#close-help").focus(); });
document.querySelector("#close-help").addEventListener("click", () => { helpModal.hidden = true; document.querySelector("#help-button").focus(); });
helpModal.addEventListener("click", event => { if (event.target === helpModal) helpModal.hidden = true; });
document.addEventListener("keydown", event => {
  if (event.key === "Escape" && !helpModal.hidden) helpModal.hidden = true;
  if (event.code === "Space" && event.target.tagName !== "BUTTON" && event.target.tagName !== "INPUT" && helpModal.hidden) {
    event.preventDefault();
    document.querySelector("#play-button").click();
  }
});
