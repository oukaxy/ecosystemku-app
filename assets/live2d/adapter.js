(function () {
  'use strict';

  var MODEL_URL = 'rem/Character.model3.json';
  var AUDIO_BASE = 'rem/audio/';

  // Parameter Rem — sama dengan params di rem/character.json.
  var P = {
    eyeL: 'PARAM_EYE_L_OPEN',
    eyeR: 'PARAM_EYE_R_OPEN',
    mouthY: 'PARAM_MOUTH_OPEN_Y',
    mouthF: 'PARAM_MOUTH_FORM',
    angleX: 'PARAM_ANGLE_X',
    angleY: 'PARAM_ANGLE_Y',
    angleZ: 'PARAM_ANGLE_Z',
    bodyX: 'PARAM_BODY_ANGLE_X',
    eyeX: 'PARAM_EYE_BALL_X',
    eyeY: 'PARAM_EYE_BALL_Y',
    breath: 'PARAM_BREATH',
  };

  var app = null;
  var model = null;
  var ready = false;
  var starting = false;
  var speaking = false;
  var muted = false;
  var currentExpr = 'none';
  var expressionTimer = null;
  var audio = null;
  var audioUrl = null;
  var audioContext = null;
  var analyser = null;
  var gain = null;
  var source = null;
  var freqData = null;

  var blinkTimer = 0;
  var blinkState = 'open';
  var blinkT = 0;
  var idleBreath = 0;
  var idleHead = 0;
  var idleAngleZ = 0;
  var cursorX = 0.5;
  var cursorY = 0.5;
  var smoothCX = 0.5;
  var smoothCY = 0.5;
  var smoothMouth = 0;
  var paused = false;
  var pointerDown = false;
  var pointerMoved = false;
  var pointerStartX = 0;
  var pointerStartY = 0;
  var tapCooldown = 0;
  var TAP_COOLDOWN_MS = 900;

  function send(type, payload) {
    var message = Object.assign({ type: type }, payload || {});
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler('remEvent', JSON.stringify(message));
    }
  }

  function reportError(message) {
    send('modelError', { message: message });
  }

  function ensureRuntime() {
    if (!window.PIXI) {
      reportError('Runtime PIXI gagal dimuat.');
      return false;
    }
    if (!window.Live2DCubismCore) {
      reportError('Cubism Core gagal dimuat.');
      return false;
    }
    if (!window.PIXI.live2d) {
      var display = window.PixiLive2dDisplay || window.PixiLive2dDisplayCubism4;
      if (display) {
        window.PIXI.live2d = display;
      }
    }
    if (!window.PIXI.live2d || !window.PIXI.live2d.Live2DModel) {
      reportError('pixi-live2d-display gagal dimuat.');
      return false;
    }
    return true;
  }

  // Penempatan model — sama dengan positionModel() di assistant lama:
  // skala 1.40x tinggi panel, digeser ke bawah supaya hanya torso ke atas
  // yang tampil (full body Rem tidak muat di panel).
  function fitModel() {
    if (!model) return;
    var W = window.innerWidth;
    var H = window.innerHeight;
    var isMobile = W < 700;
    var modelH = (model.internalModel && model.internalModel.height) || 800;

    var scale = (H * 1.40) / modelH;
    model.scale.set(scale);
    model.anchor.set(0.5, 1);
    model.x = W * 0.5;
    model.y = H * (isMobile ? 1.45 : 1.38);
  }

  function setCoreParam(name, value) {
    try {
      var core = model && model.internalModel && model.internalModel.coreModel;
      if (!core || !core.getParameterIndex) return;
      var idx = core.getParameterIndex(name);
      if (idx < 0) return;
      core.setParameterValueByIndex(idx, value, 1.0);
    } catch (_) {}
  }

  /* ── Blink ──────────────────────────────────────────────────── */
  function scheduleNextBlink() {
    blinkTimer = 2.5 + Math.random() * 3.5;
    blinkState = 'open';
    blinkT = 0;
  }
  scheduleNextBlink();

  function tickBlink(delta) {
    var dt = delta / 60;
    blinkTimer -= dt;

    if (blinkState === 'open' && blinkTimer <= 0) {
      blinkState = 'closing';
      blinkT = 0;
    }

    var eyeVal = 1;
    if (blinkState === 'closing') {
      blinkT += dt / 0.08;
      eyeVal = Math.max(0, 1 - blinkT);
      if (blinkT >= 1) {
        blinkState = 'closed';
        blinkT = 0;
      }
    } else if (blinkState === 'closed') {
      blinkT += dt / 0.05;
      eyeVal = 0;
      if (blinkT >= 1) {
        blinkState = 'opening';
        blinkT = 0;
      }
    } else if (blinkState === 'opening') {
      blinkT += dt / 0.10;
      eyeVal = Math.min(1, blinkT);
      if (blinkT >= 1) {
        scheduleNextBlink();
        eyeVal = 1;
      }
    }

    setCoreParam(P.eyeR, eyeVal);
    setCoreParam(P.eyeL, eyeVal);
  }

  /* ── Idle breath ────────────────────────────────────────────── */
  function tickIdle(delta) {
    var dt = delta / 60;
    idleBreath += dt;
    idleHead += dt;
    var breathVal = Math.sin(idleBreath * (Math.PI * 2 / 4)) * 0.4;
    setCoreParam(P.breath, breathVal);
    idleAngleZ = Math.sin(idleHead * (Math.PI * 2 / 7)) * 4;
    setCoreParam(P.angleZ, idleAngleZ);
  }

  /* ── Cursor follow ──────────────────────────────────────────── */
  function updateCursor(clientX, clientY) {
    cursorX = Math.max(0, Math.min(1, clientX / window.innerWidth));
    cursorY = Math.max(0, Math.min(1, clientY / window.innerHeight));
  }

  function tickFollow(delta) {
    var dt = delta / 60;
    var lerpSpeed = 3.5 * dt;
    smoothCX += (cursorX - smoothCX) * lerpSpeed;
    smoothCY += (cursorY - smoothCY) * lerpSpeed;
    var angleX = (smoothCX - 0.5) * 2 * 20;
    var angleY = (0.5 - smoothCY) * 2 * 15;
    setCoreParam(P.angleX, angleX);
    setCoreParam(P.angleY, angleY);
    setCoreParam(P.eyeX, (smoothCX - 0.5) * 2);
    setCoreParam(P.eyeY, (0.5 - smoothCY) * 2 * 0.6);
    setCoreParam(P.bodyX, angleX * 0.12);
  }

  /* ── Lip sync ───────────────────────────────────────────────── */
  function tickLipSync() {
    var targetMouth = 0;
    if (speaking && analyser && freqData && audio && !audio.paused) {
      analyser.getByteFrequencyData(freqData);
      var start = 2;
      var end = Math.min(18, freqData.length - 1);
      var sum = 0;
      for (var i = start; i <= end; i++) sum += freqData[i];
      targetMouth = Math.min(1, (sum / (end - start + 1) / 255) * 2.2);
    } else if (speaking) {
      targetMouth = 0.35 + 0.3 * Math.abs(Math.sin(performance.now() / 110));
    }
    var speed = targetMouth > smoothMouth ? 0.35 : 0.12;
    smoothMouth += (targetMouth - smoothMouth) * speed;
    setCoreParam(P.mouthY, smoothMouth);
    setCoreParam(P.mouthF, speaking ? 0.3 : 0);
  }

  /* ── Face expressions ───────────────────────────────────────── */
  var remFaceParams = {
    PARAM_MOUTH_FORM_01: { current: 0, target: 0, fadeIn: 0.06, fadeOut: 0.04 },
    PARAM_BROW_R_FORM: { current: 0, target: 0, fadeIn: 0.06, fadeOut: 0.04 },
    PARAM_BROW_L_FORM: { current: 0, target: 0, fadeIn: 0.06, fadeOut: 0.04 },
    PARAM_EYE_R_SMILE: { current: 0, target: 0, fadeIn: 0.05, fadeOut: 0.04 },
    PARAM_EYE_L_SMILE: { current: 0, target: 0, fadeIn: 0.05, fadeOut: 0.04 },
    PARAM_EYE_FORM: { current: 0, target: 0, fadeIn: 0.05, fadeOut: 0.04 },
    PARAM_CHEEK_01: { current: 0, target: 0, fadeIn: 0.04, fadeOut: 0.03 },
    PARAM_TEAR_01: { current: 0, target: 0, fadeIn: 0.03, fadeOut: 0.02 },
  };

  // Nilai target per ekspresi — dari file .motion3.json asli.
  var REM_FACE_MAP = {
    none: { PARAM_MOUTH_FORM_01: 0, PARAM_BROW_R_FORM: 0, PARAM_BROW_L_FORM: 0, PARAM_EYE_R_SMILE: 0, PARAM_EYE_L_SMILE: 0, PARAM_EYE_FORM: 0, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 0 },
    happy: { PARAM_MOUTH_FORM_01: 1, PARAM_BROW_R_FORM: 0, PARAM_BROW_L_FORM: 0, PARAM_EYE_R_SMILE: 0, PARAM_EYE_L_SMILE: 0, PARAM_EYE_FORM: 0, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 0 },
    smile: { PARAM_MOUTH_FORM_01: 1, PARAM_BROW_R_FORM: 1, PARAM_BROW_L_FORM: 1, PARAM_EYE_R_SMILE: 0, PARAM_EYE_L_SMILE: 0, PARAM_EYE_FORM: 1, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 0 },
    appeal: { PARAM_MOUTH_FORM_01: 1, PARAM_BROW_R_FORM: 0, PARAM_BROW_L_FORM: 0, PARAM_EYE_R_SMILE: 1, PARAM_EYE_L_SMILE: 1, PARAM_EYE_FORM: 0, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 0 },
    proud: { PARAM_MOUTH_FORM_01: 0, PARAM_BROW_R_FORM: 0, PARAM_BROW_L_FORM: 0, PARAM_EYE_R_SMILE: 0, PARAM_EYE_L_SMILE: 0, PARAM_EYE_FORM: 0, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 0 },
    shame: { PARAM_MOUTH_FORM_01: -0.8, PARAM_BROW_R_FORM: -0.8, PARAM_BROW_L_FORM: -0.8, PARAM_EYE_R_SMILE: 0, PARAM_EYE_L_SMILE: 0, PARAM_EYE_FORM: 1, PARAM_CHEEK_01: 1, PARAM_TEAR_01: 0 },
    sad: { PARAM_MOUTH_FORM_01: -0.8, PARAM_BROW_R_FORM: -0.5, PARAM_BROW_L_FORM: -0.5, PARAM_EYE_R_SMILE: -1, PARAM_EYE_L_SMILE: -1, PARAM_EYE_FORM: 1, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 0 },
    cry: { PARAM_MOUTH_FORM_01: -0.8, PARAM_BROW_R_FORM: -0.5, PARAM_BROW_L_FORM: -0.5, PARAM_EYE_R_SMILE: -1, PARAM_EYE_L_SMILE: -1, PARAM_EYE_FORM: 1, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 1 },
    angry: { PARAM_MOUTH_FORM_01: -1, PARAM_BROW_R_FORM: -1, PARAM_BROW_L_FORM: -1, PARAM_EYE_R_SMILE: -0.7, PARAM_EYE_L_SMILE: -0.7, PARAM_EYE_FORM: -0.6, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 0 },
    upset: { PARAM_MOUTH_FORM_01: -2, PARAM_BROW_R_FORM: -0.8, PARAM_BROW_L_FORM: -0.8, PARAM_EYE_R_SMILE: -0.5, PARAM_EYE_L_SMILE: -0.5, PARAM_EYE_FORM: 1, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 0 },
    serious: { PARAM_MOUTH_FORM_01: -0.6, PARAM_BROW_R_FORM: -0.5, PARAM_BROW_L_FORM: -0.5, PARAM_EYE_R_SMILE: 0, PARAM_EYE_L_SMILE: 0, PARAM_EYE_FORM: -1, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 0 },
    surprise: { PARAM_MOUTH_FORM_01: -0.6, PARAM_BROW_R_FORM: -0.7, PARAM_BROW_L_FORM: -0.7, PARAM_EYE_R_SMILE: 0, PARAM_EYE_L_SMILE: 0, PARAM_EYE_FORM: 0, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 0 },
    doubt: { PARAM_MOUTH_FORM_01: -0.8, PARAM_BROW_R_FORM: -0.5, PARAM_BROW_L_FORM: -0.5, PARAM_EYE_R_SMILE: 0, PARAM_EYE_L_SMILE: 0, PARAM_EYE_FORM: 0, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 0 },
    puzzle: { PARAM_MOUTH_FORM_01: -0.5, PARAM_BROW_R_FORM: -0.6, PARAM_BROW_L_FORM: -0.6, PARAM_EYE_R_SMILE: 0, PARAM_EYE_L_SMILE: 0, PARAM_EYE_FORM: 1, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 0 },
    idle: { PARAM_MOUTH_FORM_01: 0, PARAM_BROW_R_FORM: 0, PARAM_BROW_L_FORM: 0, PARAM_EYE_R_SMILE: 0, PARAM_EYE_L_SMILE: 0, PARAM_EYE_FORM: 0, PARAM_CHEEK_01: 0, PARAM_TEAR_01: 0 },
  };

  function setRemFace(exprName) {
    var map = REM_FACE_MAP[exprName] || REM_FACE_MAP.none;
    var noneMap = REM_FACE_MAP.none;
    for (var param in remFaceParams) {
      if (!Object.prototype.hasOwnProperty.call(remFaceParams, param)) continue;
      remFaceParams[param].target =
        map[param] !== undefined ? map[param] : (noneMap[param] || 0);
    }
  }

  function tickExpression() {
    for (var paramId in remFaceParams) {
      if (!Object.prototype.hasOwnProperty.call(remFaceParams, paramId)) continue;
      var s = remFaceParams[paramId];
      if (s.current !== s.target) {
        var speed = Math.abs(s.target) > Math.abs(s.current) ? s.fadeIn : s.fadeOut;
        s.current += (s.target - s.current) * speed;
        if (Math.abs(s.current - s.target) < 0.001) s.current = s.target;
      }
      // Re-apply tiap frame setelah motion engine, supaya wajah tidak di-reset.
      setCoreParam(paramId, s.current);
    }
  }

  /* ── Hand & arm params ──────────────────────────────────────── */
  var REM_HAND_MAP = {
    happy: [
      { PARAM_HAND_R_08: 1, PARAM_HAND_L_01: 1 },
      { PARAM_HAND_R_08: 1, PARAM_HAND_L_08: 1 },
    ],
    sad: [
      { PARAM_HAND_R_08: 1, PARAM_HAND_L_08: 1 },
      { PARAM_HAND_R_08: 1, PARAM_HAND_L_08: 1 },
    ],
    cry: [{ PARAM_HAND_R_08: 1, PARAM_HAND_L_04: 1 }],
    angry: [
      { PARAM_HAND_R_07: 1, PARAM_HAND_L_07: 1 },
      { PARAM_HAND_R_07: 1, PARAM_HAND_L_07: 1 },
    ],
    surprise: [{ PARAM_HAND_R_04: 1, PARAM_HAND_L_04: 1 }],
    shame: [
      { PARAM_HAND_R_05: 1, PARAM_HAND_L_05: 1 },
      { PARAM_HAND_R_05: 1, PARAM_HAND_L_05: 1 },
    ],
    upset: [{ PARAM_HAND_R_05: 1, PARAM_HAND_L_07: 1 }],
    serious: [
      { PARAM_HAND_R_04: 1, PARAM_HAND_L_04: 1 },
      { PARAM_HAND_R_04: 1, PARAM_HAND_L_04: 1 },
    ],
    proud: [{ PARAM_HAND_R_05: 1, PARAM_HAND_L_01: 1 }],
    doubt: [{ PARAM_HAND_R_07: 1, PARAM_HAND_L_07: 1 }],
    puzzle: [
      { PARAM_HAND_R_08: 1, PARAM_HAND_L_01: 1 },
      { PARAM_HAND_R_08: 1, PARAM_HAND_L_01: 1 },
      { PARAM_HAND_R_08: 1, PARAM_HAND_L_01: 1 },
    ],
    appeal: [
      { PARAM_HAND_R_04: 1, PARAM_HAND_L_04: 1 },
      { PARAM_HAND_R_05: 1, PARAM_HAND_L_05: 1 },
      { PARAM_HAND_R_05: 1, PARAM_HAND_L_05: 1 },
    ],
    smile: [{ PARAM_HAND_R_05: 1, PARAM_HAND_L_07: 1 }],
    idle: [
      { PARAM_HAND_R_05: 1, PARAM_HAND_L_07: 1 },
      { PARAM_HAND_R_02: 1, PARAM_HAND_L_07: 1 },
      { PARAM_HAND_R_05: 1, PARAM_HAND_L_07: 1 },
      { PARAM_HAND_R_05: 1, PARAM_HAND_L_07: 1 },
      { PARAM_HAND_R_05: 1, PARAM_HAND_L_07: 1 },
    ],
  };

  var REM_ARM_ORDER_MAP = {
    happy: [{ r: 1, l: 1 }, { r: 1, l: 1 }],
    sad: [{ r: 1, l: 1 }, { r: 1, l: 1 }],
    cry: [{ r: 1, l: 1 }],
    angry: [{ r: 0, l: 0 }, { r: 0, l: 0 }],
    surprise: [{ r: 1, l: 1 }],
    shame: [{ r: 1, l: 1 }, { r: 1, l: 1 }],
    upset: [{ r: 1, l: 0 }],
    serious: [{ r: 1, l: 1 }, { r: 1, l: 1 }],
    proud: [{ r: 1, l: 1 }],
    doubt: [{ r: 1, l: 1 }],
    puzzle: [{ r: 1, l: 1 }, { r: 1, l: 1 }, { r: 1, l: 1 }],
    appeal: [{ r: 1, l: 1 }, { r: 1, l: 1 }, { r: 1, l: 1 }],
    smile: [{ r: 1, l: 1 }],
    idle: [{ r: 1, l: 1 }, { r: 1, l: 1 }, { r: 1, l: 1 }, { r: 1, l: 1 }, { r: 1, l: 1 }],
  };

  var REM_MOTION_MAP = {
    happy: 2, sad: 2, cry: 1, angry: 2, surprise: 1, shame: 2, upset: 1,
    serious: 2, proud: 1, doubt: 1, puzzle: 3, appeal: 3, smile: 1, idle: 5,
  };

  var ZONE_REACTIONS = {
    head: {
      expression: 'shame',
      sounds: ['head_1.mp3', 'head_2.mp3', 'head_3.mp3', 'head_4.mp3', 'head_5.mp3'],
    },
    body: {
      expression: 'surprise',
      sounds: ['body_1.mp3', 'body_2.mp3', 'body_3.mp3', 'body_4.mp3'],
    },
    leg: {
      expression: 'appeal',
      sounds: ['leg_1.mp3', 'leg_2.mp3', 'leg_3.mp3'],
    },
  };

  var ALL_HAND_PARAMS = [
    'PARAM_HAND_R_01', 'PARAM_HAND_R_02', 'PARAM_HAND_R_03', 'PARAM_HAND_R_04',
    'PARAM_HAND_R_05', 'PARAM_HAND_R_06', 'PARAM_HAND_R_07', 'PARAM_HAND_R_08',
    'PARAM_HAND_R_09', 'PARAM_HAND_R_10', 'PARAM_HAND_R_11',
    'PARAM_HAND_L_01', 'PARAM_HAND_L_02', 'PARAM_HAND_L_03', 'PARAM_HAND_L_04',
    'PARAM_HAND_L_05', 'PARAM_HAND_L_06', 'PARAM_HAND_L_07', 'PARAM_HAND_L_08',
    'PARAM_HAND_L_09', 'PARAM_HAND_L_10', 'PARAM_HAND_L_11',
  ];

  var remCurrentHandMap = {};
  var remCurrentArmOrder = { r: 1, l: 1 };

  function applyRemHandState() {
    for (var i = 0; i < ALL_HAND_PARAMS.length; i++) {
      setCoreParam(ALL_HAND_PARAMS[i], 0);
    }
    for (var p in remCurrentHandMap) {
      if (Object.prototype.hasOwnProperty.call(remCurrentHandMap, p)) {
        setCoreParam(p, remCurrentHandMap[p]);
      }
    }
    setCoreParam('PARAM_ARM_R_ORDER', remCurrentArmOrder.r);
    setCoreParam('PARAM_ARM_L_ORDER', remCurrentArmOrder.l);
  }

  function tickRemHand() {
    applyRemHandState();
  }

  function playRemMotion(name) {
    if (!model) return;
    var count = REM_MOTION_MAP[name];
    if (!count) return;
    var index = Math.floor(Math.random() * count);

    remCurrentHandMap = REM_HAND_MAP[name] ? (REM_HAND_MAP[name][index] || {}) : {};
    remCurrentArmOrder = REM_ARM_ORDER_MAP[name]
      ? (REM_ARM_ORDER_MAP[name][index] || { r: 1, l: 1 })
      : { r: 1, l: 1 };
    applyRemHandState();

    try {
      model.motion(name, index, 2);
    } catch (_) {
      try {
        model.internalModel.motionManager.startMotion(name, index, 2);
      } catch (_2) {}
    }
  }

  /* ── Tick utama ─────────────────────────────────────────────── */
  function tick(delta) {
    if (!model) return;
    tickBlink(delta);
    tickIdle(delta);
    tickFollow(delta);
    tickLipSync();
    tickExpression();
  }

  /* ── Audio ──────────────────────────────────────────────────── */
  function ensureAudioContext() {
    if (audioContext) return;
    var Ctx = window.AudioContext || window.webkitAudioContext;
    if (!Ctx) return;
    audioContext = new Ctx();
    analyser = audioContext.createAnalyser();
    analyser.fftSize = 256;
    gain = audioContext.createGain();
    gain.gain.value = muted ? 0 : 1;
    analyser.connect(gain);
    gain.connect(audioContext.destination);
    freqData = new Uint8Array(analyser.frequencyBinCount);
  }

  function stopAudio() {
    if (audio) {
      audio.pause();
      audio.currentTime = 0;
    }
    if (audioUrl) {
      URL.revokeObjectURL(audioUrl);
      audioUrl = null;
    }
    audio = null;
    source = null;
    speaking = false;
    smoothMouth = 0;
    send('audioEnded', {});
  }

  function playAudio(base64, mime) {
    ensureAudioContext();
    stopAudio();
    try {
      var binary = atob(base64);
      var bytes = new Uint8Array(binary.length);
      for (var i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
      var blob = new Blob([bytes], { type: mime || 'audio/mpeg' });
      audioUrl = URL.createObjectURL(blob);
      audio = new Audio(audioUrl);
      if (audioContext && analyser) {
        source = audioContext.createMediaElementSource(audio);
        source.connect(analyser);
      }
      audio.onended = function () {
        speaking = false;
        send('audioEnded', {});
      };
      audio.onerror = function () {
        speaking = false;
        send('audioEnded', {});
      };
      if (audioContext && audioContext.state === 'suspended') {
        audioContext.resume();
      }
      speaking = true;
      audio.play();
      send('audioStarted', {});
    } catch (error) {
      reportError('Audio gagal: ' + (error && error.message ? error.message : error));
    }
  }

  function playAssetAudio(file) {
    if (!file || muted) return;
    ensureAudioContext();
    stopAudio();
    try {
      audio = new Audio(AUDIO_BASE + file);
      audio.crossOrigin = 'anonymous';
      if (audioContext && analyser) {
        source = audioContext.createMediaElementSource(audio);
        source.connect(analyser);
      }
      audio.onended = function () {
        speaking = false;
        send('audioEnded', {});
      };
      audio.onerror = function () {
        speaking = false;
        send('audioEnded', {});
      };
      if (audioContext && audioContext.state === 'suspended') {
        audioContext.resume();
      }
      speaking = true;
      var played = audio.play();
      if (played && played.catch) {
        played.catch(function () {
          speaking = false;
          send('audioEnded', {});
        });
      }
      send('audioStarted', {});
    } catch (error) {
      speaking = false;
    }
  }

  function pickRandom(list) {
    return list[Math.floor(Math.random() * list.length)];
  }

  function zoneAt(clientX, clientY) {
    var x = clientX / window.innerWidth;
    var y = clientY / window.innerHeight;
    if (y < 0.48 && x > 0.12 && x < 0.88) return 'head';
    if (y >= 0.48 && y < 0.75 && x > 0.15 && x < 0.85) return 'body';
    if (y >= 0.75 && y < 0.95 && x > 0.20 && x < 0.80) return 'leg';
    return null;
  }

  function reactToZone(zone) {
    if (!model || paused || speaking) return;
    var reaction = ZONE_REACTIONS[zone] || ZONE_REACTIONS.body;
    setExpression(reaction.expression, 4000);
    playAssetAudio(pickRandom(reaction.sounds));
    send('tapZone', { zone: zone, expression: reaction.expression });
  }

  /* ── Public API ─────────────────────────────────────────────── */
  function init(options) {
    if (ready) {
      send('ready', {});
      return;
    }
    // Halaman memanggil init() sekali, lalu Flutter memanggilnya lagi saat
    // onLoadStop — jangan sampai dua PIXI app/model dibuat di canvas yang sama.
    if (starting) return;
    starting = true;
    muted = !!(options && options.muted);
    if (!ensureRuntime()) {
      starting = false;
      return;
    }

    var canvas = document.getElementById('live2d-canvas');
    app = new PIXI.Application({
      view: canvas,
      width: window.innerWidth,
      height: window.innerHeight,
      backgroundAlpha: 0,
      antialias: true,
      resolution: window.devicePixelRatio || 1,
      autoDensity: true,
      powerPreference: 'default',
      sharedTicker: false,
    });
    if (app.renderer.gl) {
      app.renderer.gl.pixelStorei(app.renderer.gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, false);
    }
    app.ticker.maxFPS = 60;
    app.ticker.minFPS = 30;

    PIXI.live2d.Live2DModel.from(MODEL_URL, {
      autoInteract: false,
      idleMotionGroup: 'idle',
    }).then(function (loaded) {
      model = loaded;
      app.stage.addChild(model);
      fitModel();

      remCurrentHandMap = REM_HAND_MAP.idle[0];
      remCurrentArmOrder = REM_ARM_ORDER_MAP.idle[0];

      app.ticker.add(tick, null, -50);
      app.ticker.add(tickRemHand, null, -100);

      window.addEventListener('resize', function () {
        app.renderer.resize(window.innerWidth, window.innerHeight);
        fitModel();
      });
      window.addEventListener('mousemove', function (e) {
        updateCursor(e.clientX, e.clientY);
      });
      window.addEventListener('touchmove', function (e) {
        var t = e.touches && e.touches[0];
        if (t) updateCursor(t.clientX, t.clientY);
      }, { passive: true });
      window.addEventListener('touchstart', function (e) {
        var t = e.touches && e.touches[0];
        if (t) updateCursor(t.clientX, t.clientY);
      }, { passive: true });

      canvas.addEventListener('pointerdown', function (e) {
        pointerDown = true;
        pointerMoved = false;
        pointerStartX = e.clientX;
        pointerStartY = e.clientY;
        updateCursor(e.clientX, e.clientY);
        ensureAudioContext();
        if (audioContext && audioContext.state === 'suspended') {
          audioContext.resume();
        }
      });

      canvas.addEventListener('pointermove', function (e) {
        if (pointerDown &&
            (Math.abs(e.clientX - pointerStartX) > 10 ||
             Math.abs(e.clientY - pointerStartY) > 10)) {
          pointerMoved = true;
        }
        updateCursor(e.clientX, e.clientY);
      });

      canvas.addEventListener('pointerup', function (e) {
        if (!pointerDown) return;
        pointerDown = false;
        if (pointerMoved || Date.now() < tapCooldown) return;
        var zone = zoneAt(e.clientX, e.clientY);
        if (!zone) return;
        tapCooldown = Date.now() + TAP_COOLDOWN_MS;
        reactToZone(zone);
      });

      canvas.addEventListener('pointercancel', function () {
        pointerDown = false;
      });

      canvas.addEventListener('pointerleave', function () {
        pointerDown = false;
      });

      try {
        model.motion('idle', 0, 2);
      } catch (_) {}

      ready = true;
      starting = false;
      send('ready', {});
    }).catch(function (error) {
      starting = false;
      var detail = error && error.message ? error.message : String(error);
      reportError('Model gagal dimuat: ' + detail);
    });
  }

  function setExpression(name, revertMs) {
    if (!model) return;
    var expression = name || 'none';
    currentExpr = expression;

    playRemMotion(expression === 'none' ? 'idle' : expression);
    setRemFace(expression);
    send('expressionChanged', { name: expression });

    if (expressionTimer) clearTimeout(expressionTimer);
    if (expression !== 'none') {
      expressionTimer = setTimeout(function () {
        if (currentExpr === expression) setExpression('none');
      }, revertMs || 6000);
    }
  }

  function setSpeaking(value) {
    speaking = !!value;
  }

  function setMuted(value) {
    muted = !!value;
    if (gain) gain.gain.value = muted ? 0 : 1;
  }

  function setPaused(value) {
    paused = !!value;
    if (!app) return;
    if (paused) {
      app.ticker.stop();
      stopAudio();
    } else {
      app.ticker.start();
    }
  }

  function tapZone(zone) {
    reactToZone(zone);
  }

  window.remBridge = {
    init: init,
    setExpression: setExpression,
    setSpeaking: setSpeaking,
    playAudio: playAudio,
    stopAudio: stopAudio,
    setMuted: setMuted,
    setPaused: setPaused,
    tapZone: tapZone,
  };
})();
