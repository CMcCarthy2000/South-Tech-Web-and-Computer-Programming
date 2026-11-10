const hpReadout = document.querySelector("#hp-readout");
const hpBar = document.querySelector("#hp-bar");
const snackCount = document.querySelector("#snack-count");
const dialogue = document.querySelector("#dialogue");
const sceneCaption = document.querySelector("#scene-caption");
const arena = document.querySelector("#arena");
const soul = document.querySelector("#soul");
const arenaMessage = document.querySelector("#arena-message");
const menu = document.querySelector("#battle-menu");
const ending = document.querySelector("#ending");
const enemyName = document.querySelector("#enemy-name");
const enemy = document.querySelector("#enemy");
const mouth = document.querySelector("#enemy-mouth");

const initialState = () => ({ hp: 20, snacks: 2, kindness: 0, enemyHp: 12, busy: false, finished: false, guarding: false, sound: false });
let state = initialState();
let dodgeTimer;
let projectileTimer;
let keyHandler;
let audioContext;

const setText = (element, text) => { element.textContent = text; };

function updateStatus() {
  setText(hpReadout, `${state.hp} / 20`);
  hpBar.style.width = `${state.hp * 5}%`;
  hpBar.style.background = state.hp <= 6 ? "#d96f64" : "#e99363";
  setText(snackCount, state.snacks);
}

function speak(text, caption = text) {
  setText(dialogue, text);
  setText(sceneCaption, caption);
}

function playTone(frequency, duration = 0.08) {
  if (!state.sound) return;
  audioContext ??= new AudioContext();
  const oscillator = audioContext.createOscillator();
  const gain = audioContext.createGain();
  oscillator.type = "square";
  oscillator.frequency.value = frequency;
  gain.gain.setValueAtTime(0.035, audioContext.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, audioContext.currentTime + duration);
  oscillator.connect(gain).connect(audioContext.destination);
  oscillator.start();
  oscillator.stop(audioContext.currentTime + duration);
}

function setBusy(busy) {
  state.busy = busy;
  document.querySelectorAll(".action").forEach(button => { button.disabled = busy || state.finished; });
}

function finish(wasSpared) {
  state.finished = true;
  setBusy(true);
  arena.classList.remove("active");
  clearInterval(projectileTimer);
  clearTimeout(dodgeTimer);
  window.removeEventListener("keydown", keyHandler);
  menu.hidden = true;
  ending.hidden = false;
  if (wasSpared) {
    setText(enemyName, "MUENSTER MOTH · PAL");
    setText(document.querySelector("#ending-title"), "A FRIEND, NOT A FIGHT");
    setText(document.querySelector("#ending-copy"), "The Moth shows you a shortcut through the cave.");
    speak("The Moth gives a happy little flutter. The cave feels warmer already.", "THE MUENSTER MOTH IS HAPPY TO BE YOUR FRIEND.");
    playTone(660, 0.15);
  } else {
    setText(document.querySelector("#ending-title"), "A QUIETER KIND OF BRAVE");
    setText(document.querySelector("#ending-copy"), "The Moth retreats, leaving a snack and a map behind.");
    speak("The Moth flutters away. Maybe next time, you'll get to know each other.", "THE MUENSTER MOTH FLUTTERS INTO THE DARK.");
  }
}

function moveSoul(event) {
  if (!arena.classList.contains("active")) return;
  const keys = ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown", "w", "a", "s", "d"];
  if (!keys.includes(event.key)) return;
  event.preventDefault();
  const rect = arena.getBoundingClientRect();
  const soulRect = soul.getBoundingClientRect();
  const currentX = soulRect.left - rect.left + soulRect.width / 2;
  const currentY = soulRect.top - rect.top + soulRect.height / 2;
  const step = 9;
  const direction = event.key.toLowerCase();
  const x = currentX + (direction === "arrowleft" || direction === "a" ? -step : direction === "arrowright" || direction === "d" ? step : 0);
  const y = currentY + (direction === "arrowup" || direction === "w" ? -step : direction === "arrowdown" || direction === "s" ? step : 0);
  soul.style.left = `${Math.max(10, Math.min(rect.width - 10, x))}px`;
  soul.style.bottom = "auto";
  soul.style.top = `${Math.max(27, Math.min(rect.height - 11, y))}px`;
}

function launchDodge() {
  setBusy(true);
  arena.classList.add("active");
  arenaMessage.textContent = "";
  soul.style.left = "50%";
  soul.style.top = "auto";
  soul.style.bottom = "13px";
  speak("Curds are flying! Dodge with the arrow keys or WASD.", "DODGE THE FLYING CURDS!");
  let remaining = 3;
  const projectiles = [];
  keyHandler = moveSoul;
  window.addEventListener("keydown", keyHandler);
  projectileTimer = window.setInterval(() => {
    const curd = document.createElement("span");
    curd.className = "curd";
    curd.style.left = `${8 + Math.random() * 84}%`;
    curd.style.top = "-10px";
    arena.append(curd);
    projectiles.push(curd);
    const animate = () => {
      if (!arena.classList.contains("active")) return;
      const top = parseFloat(curd.style.top) || 0;
      curd.style.top = `${top + 3.2}px`;
      const curdRect = curd.getBoundingClientRect();
      const soulRect = soul.getBoundingClientRect();
      if (curdRect.left < soulRect.right && curdRect.right > soulRect.left && curdRect.top < soulRect.bottom && curdRect.bottom > soulRect.top) {
        curd.remove();
        const index = projectiles.indexOf(curd);
        if (index >= 0) projectiles.splice(index, 1);
        damage(2);
      } else if (top < arena.clientHeight) {
        requestAnimationFrame(animate);
      } else {
        curd.remove();
        const index = projectiles.indexOf(curd);
        if (index >= 0) projectiles.splice(index, 1);
      }
    };
    requestAnimationFrame(animate);
  }, 370);
  dodgeTimer = window.setInterval(() => {
    remaining -= 1;
    if (remaining <= 0) {
      clearInterval(dodgeTimer);
      clearInterval(projectileTimer);
      window.removeEventListener("keydown", keyHandler);
      projectiles.forEach(curd => curd.remove());
      arena.classList.remove("active");
      if (state.hp <= 0) {
        state.hp = 1;
        updateStatus();
        speak("A stray curd bonks your backpack. You hang on by a thread!", "YOU HANG ON!");
      } else {
        speak("You weave between the curds. The Moth looks impressed.", "THE MOTH'S CURD STORM FIZZLES OUT.");
      }
      setBusy(false);
    }
  }, 1000);
}

function damage(amount) {
  if (state.guarding) amount = Math.max(1, amount - 1);
  state.hp = Math.max(0, state.hp - amount);
  updateStatus();
  playTone(140, 0.07);
  arenaMessage.textContent = `-${amount} HP`;
}

function enemyTurn(text) {
  speak(text, "THE MUENSTER MOTH FLAPS ITS WINGS!");
  window.setTimeout(launchDodge, 650);
}

function takeAction(action) {
  if (state.busy || state.finished) return;
  setBusy(true);
  state.guarding = false;
  playTone(360);

  if (action === "talk") {
    state.kindness += 1;
    const lines = [
      "You ask the Moth about its sparkly wings. It blushes a little.",
      "You tell the Moth its wings look like moonlight on milk.",
      "You and the Moth share a very serious nod about cave snacks."
    ];
    const line = lines[Math.min(state.kindness - 1, lines.length - 1)];
    mouth.style.height = "2px";
    speak(line, "THE MUENSTER MOTH SEEMS A LITTLE LESS SHY.");
    if (state.kindness >= 3) {
      window.setTimeout(() => {
        setBusy(false);
        speak("The Moth is smiling now. Maybe it doesn't want to fight.", "THE MUENSTER MOTH IS READY TO BE SPARED.");
      }, 450);
      return;
    }
    window.setTimeout(() => enemyTurn("The Moth flutters in a small, hopeful circle."), 450);
  } else if (action === "taste") {
    if (state.snacks <= 0) {
      setBusy(false);
      speak("Your snack pocket is empty. Just crumbs in there.", "NO POCKET SNACKS LEFT.");
      return;
    }
    state.snacks -= 1;
    state.hp = Math.min(20, state.hp + 7);
    updateStatus();
    speak("You munch a pocket cheddar. Comforting, with notes of adventure.", "POCKET CHEDDAR RESTORES 7 HP.");
    window.setTimeout(() => enemyTurn("The Moth politely waits for you to finish chewing."), 500);
  } else if (action === "brace") {
    state.guarding = true;
    speak("You tuck behind your sturdy snack satchel. Very sensible.", "BRACE: THE NEXT HIT WILL BE SOFTER.");
    window.setTimeout(() => enemyTurn("The Moth sends a gentle flurry of flying curds."), 450);
  } else if (action === "spare") {
    if (state.kindness < 3) {
      setBusy(false);
      speak("The Moth isn't ready yet. Maybe try talking a little more?", "THE MUENSTER MOTH STILL LOOKS UNCERTAIN.");
      return;
    }
    finish(true);
  }
}

document.querySelectorAll(".action").forEach(button => {
  button.addEventListener("click", () => takeAction(button.dataset.action));
});

document.querySelector(".sound-toggle").addEventListener("click", event => {
  state.sound = !state.sound;
  event.currentTarget.setAttribute("aria-pressed", String(state.sound));
  event.currentTarget.textContent = `SOUND: ${state.sound ? "ON" : "OFF"}`;
  if (state.sound) playTone(520);
});

document.querySelector("#restart").addEventListener("click", () => {
  clearInterval(projectileTimer);
  clearInterval(dodgeTimer);
  window.removeEventListener("keydown", keyHandler);
  state = { ...initialState(), sound: state.sound };
  menu.hidden = false;
  ending.hidden = true;
  enemyName.textContent = "MUENSTER MOTH";
  mouth.style.height = "4px";
  updateStatus();
  setBusy(false);
  speak("The Muenster Moth flutters down from the cave ceiling.");
});

document.addEventListener("keydown", event => {
  if (event.code === "Space" && !state.busy && !state.finished && document.activeElement.tagName !== "BUTTON") {
    event.preventDefault();
    document.querySelector(".action:not(:disabled)")?.focus();
  }
});

updateStatus();
