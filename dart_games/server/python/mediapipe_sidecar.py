"""
Face-landmark sidecar for Dart Games server.

Reads a single JSON line from stdin:
    {"image_path": "/absolute/path/to/avatar.jpg"}

Writes a single JSON line to stdout:
    {
        "detected": true,
        "boundingBox": {"x": 0.18, "y": 0.12, "width": 0.64, "height": 0.72},
        "leftEye":     {"x": 0.34, "y": 0.40},
        "rightEye":    {"x": 0.66, "y": 0.40},
        "noseTip":     {"x": 0.50, "y": 0.55},
        "mouthCenter": {"x": 0.50, "y": 0.72},
        "confidence":  0.97
    }

On no face detected: {"detected": false}
On any exception:    {"error": "<msg>"}  (exit code 1)

Detection strategy (in order):
  1. mediapipe Tasks FaceLandmarker (0.10.x) with bundled task file — if
     the face_landmarker.task model file is present next to this script.
  2. OpenCV DNN face detector (res10 SSD) — if model files are present.
  3. OpenCV Haar cascade face + eye detector — always available.

All coordinates are normalized 0..1 relative to image width/height.
"""

import os
import sys
import json
import math

# Suppress TensorFlow Lite / glog startup noise before importing mediapipe.
os.environ['GLOG_minloglevel'] = '2'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
os.environ['MEDIAPIPE_DISABLE_GPU'] = '1'

import cv2
import numpy as np


# ---------------------------------------------------------------------------
# Helper: load image
# ---------------------------------------------------------------------------

def _load_image_bgr(image_path: str):
    """Load image as BGR numpy array, using PIL as fallback for EXIF-rotated JPEGs."""
    img = cv2.imread(image_path)
    if img is not None:
        return img
    # PIL fallback.
    from PIL import Image
    pil_img = Image.open(image_path).convert('RGB')
    return cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)


# ---------------------------------------------------------------------------
# Strategy 1: mediapipe Tasks FaceLandmarker (0.10.x Tasks API)
# ---------------------------------------------------------------------------

def _script_dir() -> str:
    return os.path.dirname(os.path.abspath(__file__))


def _detect_with_mediapipe_tasks(img_bgr) -> dict | None:
    """
    Use the mediapipe 0.10.x Tasks API (FaceLandmarker).

    Requires 'face_landmarker.task' to be present in the same directory as
    this script. Download from:
    https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task
    """
    task_model = os.path.join(_script_dir(), 'face_landmarker.task')
    if not os.path.isfile(task_model):
        return None  # Model not present — fall through to next strategy.

    try:
        from mediapipe.tasks.python.core.base_options import BaseOptions
        from mediapipe.tasks.python.vision import (
            FaceLandmarker,
            FaceLandmarkerOptions,
            RunningMode,
        )
        import mediapipe as mp

        options = FaceLandmarkerOptions(
            base_options=BaseOptions(model_asset_path=task_model),
            running_mode=RunningMode.IMAGE,
            num_faces=1,
            min_face_detection_confidence=0.5,
        )

        h, w = img_bgr.shape[:2]
        img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=img_rgb)

        with FaceLandmarker.create_from_options(options) as landmarker:
            result = landmarker.detect(mp_image)

        if not result.face_landmarks or len(result.face_landmarks) == 0:
            return {'detected': False}

        lm = result.face_landmarks[0]  # list of NormalizedLandmark

        # Key landmark indices (same as mediapipe legacy FaceMesh):
        #   33: left eye outer corner (user's left)
        #  263: right eye outer corner (user's right)
        #    1: nose tip
        #   13: upper lip center
        #   14: lower lip center
        xs = [l.x for l in lm]
        ys = [l.y for l in lm]
        bb_x = round(min(xs), 4)
        bb_y = round(min(ys), 4)
        bb_w = round(max(xs) - min(xs), 4)
        bb_h = round(max(ys) - min(ys), 4)

        mouth_x = round((lm[13].x + lm[14].x) / 2, 4)
        mouth_y = round((lm[13].y + lm[14].y) / 2, 4)

        return {
            'detected': True,
            'boundingBox': {'x': bb_x, 'y': bb_y, 'width': bb_w, 'height': bb_h},
            'leftEye':     {'x': round(lm[33].x, 4),  'y': round(lm[33].y, 4)},
            'rightEye':    {'x': round(lm[263].x, 4), 'y': round(lm[263].y, 4)},
            'noseTip':     {'x': round(lm[1].x, 4),   'y': round(lm[1].y, 4)},
            'mouthCenter': {'x': mouth_x, 'y': mouth_y},
            'confidence':  1.0,
        }
    except Exception as e:
        # Log but fall through to next strategy.
        print(f'[sidecar] mediapipe Tasks FaceLandmarker failed: {e}', file=sys.stderr)
        return None


# ---------------------------------------------------------------------------
# Strategy 2: OpenCV Haar cascade face + eye detector (always available)
# ---------------------------------------------------------------------------

def _detect_with_opencv_haar(img_bgr) -> dict | None:
    """
    Detect face and eyes using OpenCV bundled Haar cascades.

    Returns normalized landmark dict on success, {'detected': False} if no
    face found, None on error.
    """
    h, w = img_bgr.shape[:2]
    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    # Equalise for better detection in varied lighting.
    gray_eq = cv2.equalizeHist(gray)

    cascade_dir = cv2.data.haarcascades
    face_cascade = cv2.CascadeClassifier(
        os.path.join(cascade_dir, 'haarcascade_frontalface_default.xml')
    )
    eye_cascade = cv2.CascadeClassifier(
        os.path.join(cascade_dir, 'haarcascade_eye.xml')
    )

    # Detect faces. scaleFactor / minNeighbors tuned for cropped avatar images.
    faces = face_cascade.detectMultiScale(
        gray_eq,
        scaleFactor=1.1,
        minNeighbors=5,
        minSize=(int(w * 0.15), int(h * 0.15)),
    )

    if len(faces) == 0:
        # Try alt cascade as fallback.
        face_cascade2 = cv2.CascadeClassifier(
            os.path.join(cascade_dir, 'haarcascade_frontalface_alt2.xml')
        )
        faces = face_cascade2.detectMultiScale(
            gray_eq, scaleFactor=1.05, minNeighbors=3,
            minSize=(int(w * 0.1), int(h * 0.1)),
        )

    if len(faces) == 0:
        return {'detected': False}

    # Pick the largest face.
    fx, fy, fw, fh = max(faces, key=lambda r: r[2] * r[3])

    # Normalize bounding box.
    bb_x = round(fx / w, 4)
    bb_y = round(fy / h, 4)
    bb_w = round(fw / w, 4)
    bb_h = round(fh / h, 4)

    # Detect eyes within the face ROI.
    face_roi_gray = gray_eq[fy: fy + fh, fx: fx + fw]
    eyes = eye_cascade.detectMultiScale(
        face_roi_gray, scaleFactor=1.1, minNeighbors=5,
        minSize=(int(fw * 0.1), int(fh * 0.08)),
    )

    # Try left/right specific cascades if generic fails.
    if len(eyes) < 2:
        left_eye_cascade = cv2.CascadeClassifier(
            os.path.join(cascade_dir, 'haarcascade_lefteye_2splits.xml')
        )
        right_eye_cascade = cv2.CascadeClassifier(
            os.path.join(cascade_dir, 'haarcascade_righteye_2splits.xml')
        )
        l_eyes = left_eye_cascade.detectMultiScale(
            face_roi_gray, scaleFactor=1.1, minNeighbors=3)
        r_eyes = right_eye_cascade.detectMultiScale(
            face_roi_gray, scaleFactor=1.1, minNeighbors=3)
        if len(l_eyes) > 0 and len(r_eyes) > 0:
            eyes = np.array([
                l_eyes[0],
                r_eyes[0],
            ])

    if len(eyes) >= 2:
        # Sort by x to identify left/right within face ROI.
        eyes_sorted = sorted(eyes, key=lambda e: e[0])
        # In face ROI coords → normalize to full image.
        eye1 = eyes_sorted[0]  # left in face ROI (user's right side of image)
        eye2 = eyes_sorted[-1]  # right in face ROI (user's left side of image)
        eye1_cx = round((fx + eye1[0] + eye1[2] / 2) / w, 4)
        eye1_cy = round((fy + eye1[1] + eye1[3] / 2) / h, 4)
        eye2_cx = round((fx + eye2[0] + eye2[2] / 2) / w, 4)
        eye2_cy = round((fy + eye2[1] + eye2[3] / 2) / h, 4)
        # Mediapipe convention: leftEye = user's left (image right side).
        # After sorting by x in image coords: eyes_sorted[0] is image-left
        # (user's right), eyes_sorted[-1] is image-right (user's left).
        left_eye  = {'x': eye2_cx, 'y': eye2_cy}
        right_eye = {'x': eye1_cx, 'y': eye1_cy}
    else:
        # Fallback: heuristic eye positions from face bounding box.
        left_eye  = {'x': round(bb_x + bb_w * 0.65, 4),
                     'y': round(bb_y + bb_h * 0.38, 4)}
        right_eye = {'x': round(bb_x + bb_w * 0.35, 4),
                     'y': round(bb_y + bb_h * 0.38, 4)}

    # Heuristic nose tip and mouth center derived from face bounding box.
    # These are anatomically reasonable for frontal faces.
    nose_tip     = {'x': round(bb_x + bb_w * 0.50, 4),
                    'y': round(bb_y + bb_h * 0.60, 4)}
    mouth_center = {'x': round(bb_x + bb_w * 0.50, 4),
                    'y': round(bb_y + bb_h * 0.78, 4)}

    return {
        'detected': True,
        'boundingBox': {'x': bb_x, 'y': bb_y, 'width': bb_w, 'height': bb_h},
        'leftEye':     left_eye,
        'rightEye':    right_eye,
        'noseTip':     nose_tip,
        'mouthCenter': mouth_center,
        'confidence':  0.80,
    }


# ---------------------------------------------------------------------------
# Main detection function
# ---------------------------------------------------------------------------

def detect_landmarks(image_path: str) -> dict:
    """
    Run face detection on the given image and return normalized landmarks.

    Returns a dict with 'detected': True and landmark coords on success,
    or 'detected': False if no face is found.
    """
    img = _load_image_bgr(image_path)

    # Strategy 1: mediapipe Tasks API (best quality, needs model file).
    result = _detect_with_mediapipe_tasks(img)
    if result is not None:
        return result

    # Strategy 2: OpenCV Haar cascade (always available, good for frontal faces).
    result = _detect_with_opencv_haar(img)
    if result is not None:
        return result

    return {'detected': False}


def main():
    """Entry point: read JSON from stdin, write JSON to stdout."""
    try:
        raw = sys.stdin.read().strip()
        request = json.loads(raw)
        image_path = request['image_path']
    except Exception as e:
        print(json.dumps({'error': f'Invalid input: {e}'}), flush=True)
        sys.exit(1)

    try:
        result = detect_landmarks(image_path)
        print(json.dumps(result), flush=True)
        sys.exit(0)
    except Exception as e:
        print(json.dumps({'error': str(e)}), flush=True)
        sys.exit(1)


if __name__ == '__main__':
    main()
