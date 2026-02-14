(() => {
  const viewport = document.getElementById("slide-viewport");
  if (!viewport) return;

  const frames = Array.from(viewport.querySelectorAll(".slide-frame"));
  const counter = document.getElementById("slide-counter");
  const prevButton = document.querySelector("[data-slide-prev]");
  const nextButton = document.querySelector("[data-slide-next]");
  const fullscreenButton = document.querySelector("[data-slide-fullscreen]");

  const total = frames.length;
  if (total === 0) return;

  function normalizeHash(hash) {
    if (!hash || hash.length <= 1) return 0;
    const parsed = Number.parseInt(hash.slice(1), 10);
    if (!Number.isFinite(parsed)) return 0;
    const idx = parsed - 1;
    if (idx < 0) return 0;
    if (idx >= total) return total - 1;
    return idx;
  }

  let index = normalizeHash(window.location.hash);

  function syncHash() {
    const nextHash = `#${index + 1}`;
    if (window.location.hash !== nextHash) {
      history.replaceState(null, "", nextHash);
    }
  }

  function render() {
    frames.forEach((frame, i) => {
      frame.classList.toggle("is-active", i === index);
    });

    if (counter) {
      counter.textContent = `${index + 1} / ${total}`;
    }

    if (prevButton) {
      prevButton.disabled = index === 0;
    }

    if (nextButton) {
      nextButton.disabled = index === total - 1;
    }

    syncHash();
  }

  function step(delta) {
    const next = index + delta;
    if (next < 0 || next >= total) return;
    index = next;
    render();
  }

  prevButton?.addEventListener("click", () => step(-1));
  nextButton?.addEventListener("click", () => step(1));

  function updateFullscreenLabel() {
    if (!fullscreenButton) return;
    const active = document.fullscreenElement != null;
    fullscreenButton.textContent = active ? "Exit Full Screen" : "Full Screen";
  }

  async function toggleFullscreen() {
    try {
      if (document.fullscreenElement) {
        await document.exitFullscreen();
      } else {
        await document.documentElement.requestFullscreen();
      }
    } catch (_) {
      // Ignore failures (e.g. unsupported env); button label remains current state.
    }
    updateFullscreenLabel();
  }

  fullscreenButton?.addEventListener("click", () => {
    void toggleFullscreen();
  });

  document.addEventListener("fullscreenchange", () => {
    updateFullscreenLabel();
  });

  window.addEventListener("keydown", (event) => {
    if (event.key === "ArrowLeft") {
      event.preventDefault();
      step(-1);
      return;
    }
    if (event.key === "ArrowRight") {
      event.preventDefault();
      step(1);
    }
  });

  window.addEventListener("hashchange", () => {
    index = normalizeHash(window.location.hash);
    render();
  });

  updateFullscreenLabel();
  render();
})();
