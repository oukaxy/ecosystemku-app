(function () {
  'use strict';

  var MODEL_URL = 'rem/Character.model3.json';
  var MOUTH_PARAM = 'PARAM_MOUTH_OPEN_Y';

  var app = null;
  var model = null;
  var ready = false;
  var speaking = false;
  var muted = false;
  var mouth = 0;
  var expressionTimer = null;
  var audio = null;
  var audioUrl = null;
  var audioContext = null;
  var analyser = null;
  var gain = null;
  var source = null;
  var freqData = null;

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

  function fitModel() {
    if (!model || !app) return;
    var width = app.renderer.width;
    var height = app.renderer.height;
    var scale = Math.min(width / model.width, height / model.height) * 0.92;
    model.scale.set(scale);
    model.anchor.set(0.5, 1);
    model.x = width / 2;
    model.y = height * 1.02;
  }

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

  function tick() {
    if (!model) return;
    var target = 0;
    if (speaking) {
      target = 0.35 + 0.3 * Math.abs(Math.sin(performance.now() / 110));
    }
    if (analyser && audio && !audio.paused) {
      analyser.getByteFrequencyData(freqData);
      var sum = 0;
      for (var i = 0; i < freqData.length; i++) sum += freqData[i];
      var level = sum / freqData.length / 255;
      target = Math.min(1, level * 2.4);
    }
    mouth += (target - mouth) * 0.25;
    var core = model.internalModel && model.internalModel.coreModel;
    if (core && core.setParameterValueById) {
      core.setParameterValueById(MOUTH_PARAM, mouth);
    }
  }

  function init(options) {
    if (ready) {
      send('ready', {});
      return;
    }
    muted = !!(options && options.muted);
    if (!ensureRuntime()) return;

    var canvas = document.getElementById('live2d-canvas');
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

    PIXI.live2d.Live2DModel.from(MODEL_URL, {
      autoInteract: false,
      idleMotionGroup: 'idle',
    }).then(function (loaded) {
      model = loaded;
      app.stage.addChild(model);
      fitModel();
      model.motion('idle');
      app.ticker.add(tick);
      window.addEventListener('resize', function () {
        app.renderer.resize(window.innerWidth, window.innerHeight);
        fitModel();
      });
      ready = true;
      send('ready', {});
    }).catch(function (error) {
      var detail = error && error.message ? error.message : String(error);
      reportError('Model gagal dimuat: ' + detail);
    });
  }

  function setExpression(name) {
    if (!model) return;
    var expression = name || 'none';
    try {
      if (expression === 'none') {
        model.motion('idle');
      } else {
        model.motion(expression);
      }
    } catch (e) {
      model.motion('idle');
    }
    send('expressionChanged', { name: expression });
    if (expressionTimer) clearTimeout(expressionTimer);
    expressionTimer = setTimeout(function () {
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

  function tapZone(zone) {
    if (!model) return;
    var reactions = ['happy', 'smile', 'surprise', 'shame'];
    var pick = reactions[Math.floor(Math.random() * reactions.length)];
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
