// Link card OGP fetcher
// Fetches OGP data server-side for cards marked with link-card-loading class

(async function() {
  const loadingCards = document.querySelectorAll('.link-card-loading');
  if (loadingCards.length === 0) return;

  // Process cards in batches to avoid overwhelming the server
  const BATCH_SIZE = 5;
  for (let i = 0; i < loadingCards.length; i += BATCH_SIZE) {
    const batch = Array.from(loadingCards).slice(i, i + BATCH_SIZE);
    await Promise.all(batch.map(fetchCardData));
  }

  async function fetchCardData(card) {
    const url = card.dataset.url;
    if (!url) return;

    try {
      const apiUrl = `/api/ogp?url=${encodeURIComponent(url)}`;
      const response = await fetch(apiUrl);

      if (!response.ok) {
        // If fetch fails, keep the default card
        return;
      }

      const data = await response.json();
      updateCard(card, data);
    } catch (e) {
      // Silently fail - card remains as default link
      console.debug('Failed to fetch OGP for:', url, e);
    }
  }

  function updateCard(card, data) {
    // Remove loading class
    card.classList.remove('link-card-loading');

    // Update title if we have one (and it's not just the URL)
    if (data.title && data.title !== url) {
      const titleEl = card.querySelector('.link-card-title');
      if (titleEl) titleEl.textContent = data.title;
    }

    // Update description
    if (data.description) {
      const descEl = card.querySelector('.link-card-description');
      if (descEl) descEl.textContent = data.description;
    }

    // Update or add image
    if (data.image) {
      let imgEl = card.querySelector('.link-card-image');
      if (!imgEl || imgEl.classList.contains('link-card-image-placeholder')) {
        // Replace placeholder with actual image
        const placeholder = card.querySelector('.link-card-image-placeholder');
        if (placeholder) {
          const newImg = document.createElement('img');
          newImg.className = 'link-card-image';
          newImg.src = data.image;
          newImg.alt = data.title || url;
          placeholder.replaceWith(newImg);
        }
      } else {
        imgEl.src = data.image;
        if (data.title) imgEl.alt = data.title;
      }
    }

    // Update site name
    if (data.site_name) {
      const siteEl = card.querySelector('.link-card-site');
      if (siteEl) siteEl.textContent = data.site_name;
    }
  }
})();
