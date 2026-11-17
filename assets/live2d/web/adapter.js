(function () {
  'use strict';

  const MODEL_URL = '../rem/Character.model3.json';
  const MOUTH_PARAM = 'PARAM_MOUTH_OPEN_Y';

  let app = null;
  let model = null;
  let ready = false;
  let speaking = false;
  let muted = false;
  let mouth = 0;
  let expressionTimer = null;
  let audio = null;
  let audioUrl = null;
  let audioContext = null;
  let analyser = null;
  let gain = null;
  let source = null;
  let freqData = null;

  function send(type, payload) {
    const message = Object.assign({ type: type }, payload || {});
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler('remEvent', JSON.stringify(message));
    }
  }

  function fitModel() {
    if (!model || !app) return;
    const width = app.renderer.width;
    const height = app.renderer.height;
    const scale = Math.min(width / model.width, height / model.height) * 0.92;
    model.scale.set(scale);
    model.anchor.set(0.5, 1);
    model.x = width / 2;
    model.y = height * 1.02;
  }

  function ensureAudioContext() {
    if (audioContext) return;
    const Ctx = window.AudioContext || window.webkitAudioContext;
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

  function tick() {
    if (!model) return;
    let target = 0;
    if (speaking) {
      target = 0.35 + 0.3 * Math.abs(Math.sin(performance.now() / 110));
    }
    if (analyser && audio && !audio.paused) {
      analyser.getByteFrequencyData(freqData);
      let sum = 0;
      for (let i = 0; i < freqData.length; i += 1) sum += freqData[i];
      const level = sum / freqData.length / 255;
      target = Math.min(1, level * 2.4);
    }
    mouth += (target - mouth) * 0.25;
    const core = model.internalModel && model.internalModel.coreModel;
    if (core && core.setParameterValueById) {
      core.setParameterValueById(MOUTH_PARAM, mouth);
    }
  }

  async function init(options) {
    if (ready) {
      send('ready', {});
      return;
    }
    muted = !!(options && options.muted);
    const canvas = document.getElementById('live2d-canvas');
    app = new PIXI.Application({
      view: canvas,
      width: window.innerWidth,
      height: window.innerHeight,
      backgroundAlpha: 0,
      antialias: true,
      resolution: window.devicePixelRatio || 1,
      autoDensity: true,
      sharedTicker: false,
    });

    try {
      model = await PIXI.live2d.Live2DModel.from(MODEL_URL, {
        autoInteract: false,
        idleMotionGroup: 'idle',
      });
      app.stage.addChild(model);
      fitModel();
      model.motion('idle');
      app.ticker.add(tick);
      ready = true;
      window.addEventListener('resize', () => {
        app.renderer.resize(window.innerWidth, window.innerHeight);
        fitModel();
      });
      send('ready', {});
    } catch (error) {
      send('modelError', { message: String(error && error.message ? error.message : error) });
    }
  }

  function setExpression(name) {
    if (!model) return;
    const expression = name || 'none';
    try {
      if (expression === 'none') {
        model.motion('idle');
      } else {
        model.motion(expression);
      }
    } catch (_) {
      model.motion('idle');
    }
    send('expressionChanged', { name: expression });
    if (expressionTimer) clearTimeout(expressionTimer);
    expressionTimer = setTimeout(() => {
      if (model) model.motion('idle');
      send('expressionChanged', { name: 'none' });
    }, 6000);
  }

  function setSpeaking(value) {
    speaking = !!value;
  }

  function setMuted(value) {
    muted = !!value;
    if (gain) gain.gain.value = muted ? 0 : 1;
  }

  function setPaused(value) {
    if (!app) return;
    if (value) {
      app.ticker.stop();
      stopAudio();
    } else {
      app.ticker.start();
    }
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
    send('audioEnded', {});
  }

  async function playAudio(base64, mime) {
    ensureAudioContext();
    stopAudio();
    try {
      const binary = atob(base64);
      const bytes = new Uint8Array(binary.length);
      for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
      const blob = new Blob([bytes], { type: mime || 'audio/mpeg' });
      audioUrl = URL.createObjectURL(blob);
      audio = new Audio(audioUrl);
      if (audioContext && analyser) {
        source = audioContext.createMediaElementSource(audio);
        source.connect(analyser);
      }
      audio.onended = () => {
        speaking = false;
        send('audioEnded', {});
      };
      audio.onerror = () => {
        speaking = false;
        send('audioEnded', {});
      };
      if (audioContext && audioContext.state === 'suspended') {
        await audioContext.resume();
      }
      speaking = true;
      await audio.play();
      send('audioStarted', {});
    } catch (error) {
      send('modelError', {
        message: 'Audio gagal: ' + String(error && error.message ? error.message : error),
      });
    }
  }

  function tapZone(zone) {
    if (!model) return;
    const reactions = ['happy', 'smile', 'surprise', 'shame'];
    const pick = reactions[Math.floor(Math.random() * reactions.length)];
    model.motion(pick);
    send('expressionChanged', { name: pick, zone: zone });
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
