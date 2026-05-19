import time
import numpy as np
import torch
import torch.nn.functional as F
from sklearn.datasets import fetch_openml
from codecarbon import EmissionsTracker


def to_bitplanes(img):
    return (img > 128).astype(np.uint8)[None, :, :]


def rule90_step(arr):
    L = np.zeros_like(arr); L[1:, :] = arr[:-1, :]
    R = np.zeros_like(arr); R[:-1, :] = arr[1:, :]
    return np.bitwise_xor(L, R)


def evolve_bitplanes(bitplanes, steps=8):
    out = []; cur = bitplanes.copy()
    for _ in range(steps):
        x = np.array([rule90_step(bp) for bp in cur])
        out.append(x); cur = x
    return out


def max_pool(im, size=2, stride=2):
    h, w = im.shape
    o = np.zeros((h // stride, w // stride), dtype=im.dtype)
    for i in range(0, h, stride):
        for j in range(0, w, stride):
            o[i // stride, j // stride] = im[i:i + size, j:j + size].max()
    return o


def reca_features(img: np.ndarray):
    bps = to_bitplanes(img)
    evo = evolve_bitplanes(bps)
    gs = [layer[0] for layer in evo]
    pp = [max_pool(g) for g in gs]
    return np.concatenate([p.ravel() for p in pp]).astype(np.float32)


# Loads pretrained weights
def load_model(path: str = "reca_weights.pt"):
    ckpt = torch.load(path, map_location="cpu")
    W = ckpt["W"].float()   
    b = ckpt["b"].float()  
    return W, b


def predict(img: np.ndarray, W: torch.Tensor, b: torch.Tensor) -> int:
    feat = torch.from_numpy(reca_features(img))
    logits = F.linear(feat, W, b)
    return int(logits.argmax().item())


def predict_batch(imgs: np.ndarray, W: torch.Tensor, b: torch.Tensor) -> np.ndarray:
    feats = torch.from_numpy(np.stack([reca_features(img) for img in imgs]))
    logits = F.linear(feats, W, b)
    return logits.argmax(dim=1).numpy()

# Calculating the average energy of N inferences
if __name__ == "__main__":
    N = 50
    W, b = load_model("reca_weights.pt")
    mnist = fetch_openml("mnist_784", version=1, as_frame=False)
    X_imgs = mnist["data"].reshape(-1, 28, 28).astype(np.uint8)
    y_all = mnist["target"].astype(int)
    X_test, y_test = X_imgs[100], y_all[100]

    # Tracking energy and time
    tracker = EmissionsTracker(log_level="critical", save_to_file=False)
    tracker.start()
    t0 = time.perf_counter()
    for i in range(N):
        pred = predict(X_test, W, b)
    duration = time.perf_counter() - t0
    tracker.stop()
    joules = tracker._total_energy.kWh * 3.6e6

    print(f"Avg inference energy: {joules/N:.6f} J, Avg inference time: {duration/N:.6f} s")