<?php
include "../connect.php";
include "filter_repository.php";

$itemId = (int) filterRequest("itemid");
$variantId = filterRequest("variantid");
$variantId = ($variantId === null || $variantId === '') ? null : (int) $variantId;
$lang = filterRequest("lang") === "ar" ? "ar" : "en";
$isArabic = $lang === "ar";

$filter = null;
if ($itemId > 0) {
    $filter = getItemArFilter($con, $itemId, $variantId);
}

$pageTitle = 'Virtual Try On';
$productName = $filter
    ? ($isArabic ? ($filter['items_name_ar'] ?? '') : ($filter['items_name_en'] ?? ''))
    : '';

$configJson = json_encode($filter, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
?>
<!DOCTYPE html>
<html lang="<?= $isArabic ? 'ar' : 'en' ?>" dir="<?= $isArabic ? 'rtl' : 'ltr' ?>">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title><?= htmlspecialchars($pageTitle, ENT_QUOTES, 'UTF-8') ?></title>
  <style>
    :root {
      color-scheme: dark;
      --bg: #07111f;
      --card: rgba(10, 22, 39, 0.82);
      --line: rgba(180, 219, 255, 0.18);
      --accent: #6ed8ff;
      --text: #f4fbff;
      --muted: #a7bdd1;
      --danger: #ff8f8f;
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      min-height: 100vh;
      font-family: Arial, sans-serif;
      color: var(--text);
      background:
        radial-gradient(circle at top, rgba(110, 216, 255, 0.2), transparent 34%),
        radial-gradient(circle at bottom, rgba(138, 255, 193, 0.12), transparent 30%),
        var(--bg);
    }

    .shell {
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      gap: 14px;
      padding: 14px;
    }

    .panel {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 22px;
      backdrop-filter: blur(14px);
      box-shadow: 0 24px 60px rgba(0, 0, 0, 0.35);
    }

    .hero { padding: 16px 18px; }

    .eyebrow {
      margin: 0 0 8px;
      color: var(--accent);
      font-size: 12px;
      letter-spacing: 0.12em;
      text-transform: uppercase;
    }

    h1 {
      margin: 0;
      font-size: 22px;
      line-height: 1.2;
    }

    .sub {
      margin: 8px 0 0;
      color: var(--muted);
      font-size: 14px;
      line-height: 1.6;
    }

    .stage {
      position: relative;
      overflow: hidden;
      min-height: 60vh;
    }

    video, canvas {
      position: absolute;
      inset: 0;
      width: 100%;
      height: 100%;
      object-fit: cover;
      border-radius: 22px;
    }

    video {
      opacity: 0;
      pointer-events: none;
    }

    .status {
      position: absolute;
      inset-inline: 12px;
      top: 12px;
      z-index: 2;
      padding: 12px 14px;
      border-radius: 16px;
      background: rgba(4, 12, 24, 0.72);
      border: 1px solid rgba(255, 255, 255, 0.08);
      font-size: 13px;
      line-height: 1.5;
    }

    .status.error { color: var(--danger); }

    .controls {
      padding: 14px 16px;
      display: grid;
      gap: 12px;
    }

    .controlsHeader {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
    }

    .controlsTitle {
      margin: 0;
      font-size: 15px;
      color: var(--text);
    }

    .resetBtn {
      border: 1px solid rgba(110, 216, 255, 0.22);
      background: rgba(110, 216, 255, 0.1);
      color: var(--accent);
      border-radius: 999px;
      padding: 8px 12px;
      font-size: 12px;
      cursor: pointer;
    }

    .controlRow {
      display: grid;
      gap: 6px;
    }

    .controlMeta {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
      font-size: 13px;
      color: var(--muted);
    }

    .controlValue {
      color: var(--text);
      font-variant-numeric: tabular-nums;
    }

    .slider {
      width: 100%;
      accent-color: var(--accent);
    }

    .footer {
      padding: 14px 16px;
      display: grid;
      gap: 10px;
    }

    .tip {
      font-size: 13px;
      color: var(--muted);
      line-height: 1.6;
    }

    .chip {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 8px 12px;
      border-radius: 999px;
      background: rgba(110, 216, 255, 0.1);
      border: 1px solid rgba(110, 216, 255, 0.22);
      color: var(--accent);
      font-size: 12px;
      width: fit-content;
    }
  </style>
</head>
<body>
  <div class="shell">
    <section class="panel hero">
      <p class="eyebrow">AR TRY ON</p>
      <h1><?= htmlspecialchars($productName !== '' ? $productName : $pageTitle, ENT_QUOTES, 'UTF-8') ?></h1>
      <p class="sub">Point the camera at your face in good lighting. The frame will align live over your eyes.</p>
    </section>

    <section class="panel stage">
      <div id="status" class="status">Preparing camera and frame overlay...</div>
      <video id="inputVideo" playsinline muted></video>
      <canvas id="outputCanvas"></canvas>
    </section>

    <section class="panel controls">
      <div class="controlsHeader">
        <p class="controlsTitle">Frame Controls</p>
        <button id="resetControls" class="resetBtn" type="button">Reset</button>
      </div>

      <label class="controlRow">
        <div class="controlMeta">
          <span>Move Left / Right</span>
          <span id="offsetXValue" class="controlValue">0.00</span>
        </div>
        <input id="offsetXSlider" class="slider" type="range" min="-0.25" max="0.25" step="0.01" value="0">
      </label>

      <label class="controlRow">
        <div class="controlMeta">
          <span>Move Up / Down</span>
          <span id="offsetYValue" class="controlValue">0.00</span>
        </div>
        <input id="offsetYSlider" class="slider" type="range" min="-0.25" max="0.25" step="0.01" value="0">
      </label>

      <label class="controlRow">
        <div class="controlMeta">
          <span>Frame Size</span>
          <span id="scaleValue" class="controlValue">1.00</span>
        </div>
        <input id="scaleSlider" class="slider" type="range" min="0.10" max="10" step="0.01" value="1">
      </label>

      <label class="controlRow">
        <div class="controlMeta">
          <span>Frame Width</span>
          <span id="widthValue" class="controlValue">1.00</span>
        </div>
        <input id="widthSlider" class="slider" type="range" min="0.75" max="1.45" step="0.01" value="1">
      </label>

      <label class="controlRow">
        <div class="controlMeta">
          <span>Bridge Height</span>
          <span id="bridgeValue" class="controlValue">0.00</span>
        </div>
        <input id="bridgeSlider" class="slider" type="range" min="-0.25" max="0.25" step="0.01" value="0">
      </label>

      <label class="controlRow">
        <div class="controlMeta">
          <span>Hide Temples Back</span>
          <span id="templeDepthValue" class="controlValue">0.00</span>
        </div>
        <input id="templeDepthSlider" class="slider" type="range" min="0" max="1" step="0.01" value="0">
      </label>

      <label class="controlRow">
        <div class="controlMeta">
          <span>Temple Spread</span>
          <span id="templeSpreadValue" class="controlValue">1.00</span>
        </div>
        <input id="templeSpreadSlider"
               class="slider"
               type="range"
               min="0.8"
               max="1.4"
               step="0.01"
               value="1">
      </label>
    </section>

    <section class="panel footer">
      <div class="chip">Live preview</div>
      <div class="tip">Single transparent PNG alignment using eye landmarks, nose bridge anchoring, and smoothing.</div>
      <div class="tip">Temple arms can now fade backward gradually with one slider for a cleaner side fit.</div>
    </section>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/camera_utils/camera_utils.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/@mediapipe/face_mesh/face_mesh.js"></script>
  <script>
    const filterConfig = <?= $configJson ?: 'null' ?>;
    const runtimeAdjustments = {
      offsetX: 0,
      offsetY: 0,
      scaleFactor: 1,
      bridgeYAdjust: 0,
      widthScale: 1,
      templeDepth: 0,
      templeSpread: 1
    };

    const copy = {
      loading: 'Preparing camera and frame overlay...',
      tracking: 'Move your face gently until the frame locks in.',
      noFilter: 'This product has no try-on frame image yet.',
      cameraError: 'Unable to access the camera. Please allow permission and try again.',
      trackingLost: 'Keep your face inside the frame to position the overlay.',
      loadingFrame: 'Loading frame image...',
      ready: 'Frame image is ready.',
    };

    const statusEl = document.getElementById('status');
    const video = document.getElementById('inputVideo');
    const canvas = document.getElementById('outputCanvas');
    const ctx = canvas.getContext('2d');

    const frameImage = new Image();
    frameImage.crossOrigin = 'anonymous';
    const leftTempleImage = new Image();
    leftTempleImage.crossOrigin = 'anonymous';
    const rightTempleImage = new Image();
    rightTempleImage.crossOrigin = 'anonymous';

    const offsetXSlider = document.getElementById('offsetXSlider');
    const offsetYSlider = document.getElementById('offsetYSlider');
    const scaleSlider = document.getElementById('scaleSlider');
    const widthSlider = document.getElementById('widthSlider');
    const bridgeSlider = document.getElementById('bridgeSlider');
    const templeDepthSlider = document.getElementById('templeDepthSlider');
    const templeSpreadSlider = document.getElementById('templeSpreadSlider');
    const templeSpreadValue = document.getElementById('templeSpreadValue');

    const offsetXValue = document.getElementById('offsetXValue');
    const offsetYValue = document.getElementById('offsetYValue');
    const scaleValue = document.getElementById('scaleValue');
    const widthValue = document.getElementById('widthValue');
    const bridgeValue = document.getElementById('bridgeValue');
    const templeDepthValue = document.getElementById('templeDepthValue');
    const resetControlsBtn = document.getElementById('resetControls');

    let frameReady = false;
    let leftTempleReady = false;
    let rightTempleReady = false;
    let currentFacingMode = 'user';
    let prevPose = null;

    const frameImageUrl = filterConfig?.front_frame_url || filterConfig?.overlay_url || '';
    const leftTempleUrl = filterConfig?.left_temple_url || '';
    const rightTempleUrl = filterConfig?.right_temple_url || '';

    function setStatus(message, isError = false) {
      statusEl.textContent = message;
      statusEl.classList.toggle('error', isError);
    }

    function fitCanvas() {
      const rect = canvas.getBoundingClientRect();
      canvas.width = Math.max(1, Math.floor(rect.width));
      canvas.height = Math.max(1, Math.floor(rect.height));
    }

    function clamp(value, min, max) {
      return Math.min(max, Math.max(min, value));
    }

    function getAdjustedValue(baseValue, runtimeValue, fallback = 0) {
      const resolvedBase = typeof baseValue === 'number' ? baseValue : fallback;
      return resolvedBase + runtimeValue;
    }

    function getAdjustedScale(baseValue) {
      const resolvedBase = typeof baseValue === 'number' ? baseValue : 1;
      return clamp(resolvedBase * runtimeAdjustments.scaleFactor, 0.10, 10);
    }

    function pointToCanvas(point) {
      return {
        x: point.x * canvas.width,
        y: point.y * canvas.height,
      };
    }

    function smoothValue(prev, current, alpha = 0.7) {
      if (prev === null || prev === undefined) return current;
      return prev * alpha + current * (1 - alpha);
    }

    function normalizeAngle(angle) {
      let normalized = angle;
      while (normalized > Math.PI) normalized -= Math.PI * 2;
      while (normalized < -Math.PI) normalized += Math.PI * 2;
      return normalized;
    }

    function smoothAngle(prev, current) {
      if (prev === null || prev === undefined) return current;
      const delta = normalizeAngle(current - prev);
      return prev + delta * 0.3;
    }

    function syncControls() {
      offsetXSlider.value = runtimeAdjustments.offsetX;
      offsetYSlider.value = runtimeAdjustments.offsetY;
      scaleSlider.value = runtimeAdjustments.scaleFactor;
      widthSlider.value = runtimeAdjustments.widthScale;
      bridgeSlider.value = runtimeAdjustments.bridgeYAdjust;
      templeDepthSlider.value = runtimeAdjustments.templeDepth;
      templeSpreadSlider.value = runtimeAdjustments.templeSpread;

      offsetXValue.textContent = Number(runtimeAdjustments.offsetX).toFixed(2);
      offsetYValue.textContent = Number(runtimeAdjustments.offsetY).toFixed(2);
      scaleValue.textContent = Number(runtimeAdjustments.scaleFactor).toFixed(2);
      widthValue.textContent = Number(runtimeAdjustments.widthScale).toFixed(2);
      bridgeValue.textContent = Number(runtimeAdjustments.bridgeYAdjust).toFixed(2);
      templeDepthValue.textContent = Number(runtimeAdjustments.templeDepth).toFixed(2);
      templeSpreadValue.textContent = Number(runtimeAdjustments.templeSpread).toFixed(2);
    }

    function bindControl(slider, key, output) {
      slider.addEventListener('input', () => {
        runtimeAdjustments[key] = Number(slider.value);
        output.textContent = Number(slider.value).toFixed(2);
      });
    }

    function prepareAssets() {
      if (!filterConfig || !frameImageUrl) {
        setStatus(copy.noFilter, true);
        return;
      }

      setStatus(copy.loadingFrame);
      frameImage.onload = () => {
        frameReady = true;
        setStatus(copy.ready);
      };
      frameImage.onerror = () => setStatus(copy.noFilter, true);
      frameImage.src = frameImageUrl;

      if (leftTempleUrl) {
        leftTempleImage.onload = () => {
          leftTempleReady = true;
        };
        leftTempleImage.src = leftTempleUrl;
      }

      if (rightTempleUrl) {
        rightTempleImage.onload = () => {
          rightTempleReady = true;
        };
        rightTempleImage.src = rightTempleUrl;
      }
    }

    function renderBaseFrame() {
      ctx.save();
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
      ctx.restore();
    }

    function computeFramePose(landmarks) {
      const leftEye = pointToCanvas(landmarks[33]);
      const rightEye = pointToCanvas(landmarks[263]);
      const noseBridge = pointToCanvas(landmarks[168]);
      const leftCheek = pointToCanvas(landmarks[234]);
      const rightCheek = pointToCanvas(landmarks[454]);

      const dx = rightEye.x - leftEye.x;
      const dy = rightEye.y - leftEye.y;
      const eyeDistance = Math.hypot(dx, dy);
      if (!eyeDistance) return null;

      const angle = Math.atan2(dy, dx) + clamp((filterConfig.rotation_adjust || 0), -0.35, 0.35);
      const faceWidth = Math.max(eyeDistance, Math.abs(rightCheek.x - leftCheek.x));
      const autoFitWidth = Math.min(
        faceWidth * 0.84,
        eyeDistance * 1.52
      );
      const width =
        autoFitWidth *
        getAdjustedScale(filterConfig.scale_factor || 1.0) *
        (runtimeAdjustments.widthScale || 1);

      const centerX =
        (leftEye.x + rightEye.x) / 2 +
        clamp(getAdjustedValue(filterConfig.offset_x, runtimeAdjustments.offsetX), -0.20, 0.20) * eyeDistance;

      const centerY =
        noseBridge.y +
        clamp(getAdjustedValue(filterConfig.bridge_y_adjust, runtimeAdjustments.bridgeYAdjust), -0.20, 0.20) * eyeDistance +
        clamp(getAdjustedValue(filterConfig.offset_y, runtimeAdjustments.offsetY), -0.20, 0.20) * eyeDistance;

      const pose = { angle, width, centerX, centerY };
      pose.centerX = smoothValue(prevPose?.centerX, pose.centerX);
      pose.centerY = smoothValue(prevPose?.centerY, pose.centerY);
      pose.angle = smoothAngle(prevPose?.angle, pose.angle);
      pose.width = smoothValue(prevPose?.width, pose.width);
      prevPose = pose;
      return pose;
    }

    window.applyLiveAdjustments = function(nextValues) {
      if (!nextValues || typeof nextValues !== 'object') return;
      if (typeof nextValues.offsetX === 'number') runtimeAdjustments.offsetX = nextValues.offsetX;
      if (typeof nextValues.offsetY === 'number') runtimeAdjustments.offsetY = nextValues.offsetY;
      if (typeof nextValues.scaleFactor === 'number') runtimeAdjustments.scaleFactor = nextValues.scaleFactor;
      if (typeof nextValues.bridgeYAdjust === 'number') runtimeAdjustments.bridgeYAdjust = nextValues.bridgeYAdjust;
      if (typeof nextValues.widthScale === 'number') runtimeAdjustments.widthScale = nextValues.widthScale;
      if (typeof nextValues.templeDepth === 'number') runtimeAdjustments.templeDepth = nextValues.templeDepth;
      if (typeof nextValues.templeSpread === 'number') runtimeAdjustments.templeSpread = nextValues.templeSpread;
      syncControls();
    };

    bindControl(offsetXSlider, 'offsetX', offsetXValue);
    bindControl(offsetYSlider, 'offsetY', offsetYValue);
    bindControl(scaleSlider, 'scaleFactor', scaleValue);
    bindControl(widthSlider, 'widthScale', widthValue);
    bindControl(bridgeSlider, 'bridgeYAdjust', bridgeValue);
    bindControl(templeDepthSlider, 'templeDepth', templeDepthValue);
    bindControl(
      templeSpreadSlider,
      'templeSpread',
      templeSpreadValue
    );

    resetControlsBtn.addEventListener('click', () => {
      runtimeAdjustments.offsetX = 0;
      runtimeAdjustments.offsetY = 0;
      runtimeAdjustments.scaleFactor = 1;
      runtimeAdjustments.bridgeYAdjust = 0;
      runtimeAdjustments.widthScale = 1;
      runtimeAdjustments.templeDepth = 0;
      runtimeAdjustments.templeSpread = 1;
      syncControls();
    });

    function drawTempleImage(image, centerX, centerY, width, angle, flipX = false, opacity = 1) {
      if (!image.width || !image.height || opacity <= 0.02) return;
      const height = width * (image.height / image.width);
      ctx.save();
      ctx.globalAlpha = opacity;
      ctx.translate(centerX, centerY);
      ctx.rotate(angle);
      if (flipX) ctx.scale(-1, 1);
      ctx.drawImage(image, 0, -height / 2, width, height);
      ctx.restore();
    }

    function drawTemples(landmarks, pose) {
      const leftOuterEye = pointToCanvas(landmarks[33]);
      const rightOuterEye = pointToCanvas(landmarks[263]);
      const leftCheek = pointToCanvas(landmarks[234]);
      const rightCheek = pointToCanvas(landmarks[454]);
      const noseTip = pointToCanvas(landmarks[1]);

      const leftReach = Math.max(0, noseTip.x - leftCheek.x);
      const rightReach = Math.max(0, rightCheek.x - noseTip.x);
      const faceSpan = Math.max(1, rightCheek.x - leftCheek.x);
      const yawBias = clamp((rightReach - leftReach) / faceSpan, -1, 1);

      const templeDepth = runtimeAdjustments.templeDepth;
      const baseTempleLength =
        pose.width *
        ((filterConfig.temple_length_ratio || 0.95) * 0.42);

      const templeLength =
        baseTempleLength *
        (1 - templeDepth * 0.75);

      const templeDrop =
        pose.width *
        ((filterConfig.temple_drop_ratio || 0.18) -
        templeDepth * 0.15);

      const templeOutset =
        pose.width *
        (0.08 + templeDepth * 0.12) *
        runtimeAdjustments.templeSpread;

      const templeBackShift =
        pose.width *
        (0.12 + templeDepth * 0.35);
      const templeBaseY = ((leftOuterEye.y + rightOuterEye.y) / 2) + templeDrop;

      const leftOpacity = leftTempleReady
        ? clamp(
          (0.85 - yawBias * 0.6) *
          (1 - templeDepth * 0.95),
          0.01,
          1
        )
        : 0;

      const rightOpacity = rightTempleReady
        ? clamp(
          (0.85 + yawBias * 0.6) *
          (1 - templeDepth * 0.95),
          0.01,
          1
        )
        : 0;

      if (leftTempleReady) {
        drawTempleImage(
          leftTempleImage,
          leftCheek.x - templeOutset + templeBackShift,
          templeBaseY,
          templeLength,
          pose.angle + 0.12 + yawBias * 0.15 + templeDepth * 0.30,
          true,
          leftOpacity
        );
      }

      if (rightTempleReady) {
        drawTempleImage(
          rightTempleImage,
          rightCheek.x + templeOutset - templeBackShift,
          templeBaseY,
          templeLength,
          pose.angle - 0.12 + yawBias * 0.15 - templeDepth * 0.30,
          false,
          rightOpacity
        );
      }
    }

    function drawFrame(landmarks) {
      const pose = computeFramePose(landmarks);
      if (!pose || !frameReady || !frameImage.width || !frameImage.height) return;

      drawTemples(landmarks, pose);

      const height = pose.width * (frameImage.height / frameImage.width);
      ctx.save();
      ctx.translate(pose.centerX, pose.centerY);
      ctx.rotate(pose.angle);
      ctx.drawImage(frameImage, -pose.width / 2, -height / 2, pose.width, height);
      ctx.restore();
    }

    async function startExperience() {
      if (!filterConfig || !frameImageUrl) {
        setStatus(copy.noFilter, true);
        return;
      }

      const faceMesh = new FaceMesh({
        locateFile: (file) => `https://cdn.jsdelivr.net/npm/@mediapipe/face_mesh/${file}`,
      });

      faceMesh.setOptions({
        maxNumFaces: 1,
        refineLandmarks: true,
        minDetectionConfidence: 0.5,
        minTrackingConfidence: 0.5,
      });

      faceMesh.onResults((results) => {
        renderBaseFrame();

        if (results.multiFaceLandmarks && results.multiFaceLandmarks.length) {
          drawFrame(results.multiFaceLandmarks[0]);
          setStatus(copy.tracking);
        } else {
          prevPose = null;
          setStatus(copy.trackingLost);
        }
      });

      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          audio: false,
          video: {
            facingMode: currentFacingMode,
            width: { ideal: 1280 },
            height: { ideal: 720 }
          }
        });

        video.srcObject = stream;
        await video.play();
        fitCanvas();

        const camera = new Camera(video, {
          onFrame: async () => {
            await faceMesh.send({ image: video });
          },
          width: 1280,
          height: 720,
        });

        camera.start();
      } catch (error) {
        setStatus(copy.cameraError, true);
        console.error(error);
      }
    }

    window.addEventListener('resize', fitCanvas);
    fitCanvas();
    syncControls();
    prepareAssets();
    startExperience();
  </script>
</body>
</html>




