// MHX - Minimal Hypermedia Exchange Runtime
// A lightweight htmx-inspired library for MoonBit applications
(function() {
  'use strict';

  const MHX_ATTRS = {
    GET: 'mx-get',
    POST: 'mx-post',
    PUT: 'mx-put',
    PATCH: 'mx-patch',
    DELETE: 'mx-delete',
    TARGET: 'mx-target',
    SWAP: 'mx-swap',
    TRIGGER: 'mx-trigger',
    PUSH_URL: 'mx-push-url',
    REPLACE_URL: 'mx-replace-url',
    INDICATOR: 'mx-indicator',
  };

  const SWAP_STYLES = {
    innerHTML: 'innerHTML',
    outerHTML: 'outerHTML',
    beforebegin: 'beforebegin',
    afterbegin: 'afterbegin',
    beforeend: 'beforeend',
    afterend: 'afterend',
    delete: 'delete',
    none: 'none',
  };

  function getMethod(el) {
    for (const [method, attr] of [
      ['GET', MHX_ATTRS.GET],
      ['POST', MHX_ATTRS.POST],
      ['PUT', MHX_ATTRS.PUT],
      ['PATCH', MHX_ATTRS.PATCH],
      ['DELETE', MHX_ATTRS.DELETE],
    ]) {
      if (el.hasAttribute(attr)) {
        return { method, url: el.getAttribute(attr) };
      }
    }
    return null;
  }

  function getTarget(el) {
    const targetAttr = el.getAttribute(MHX_ATTRS.TARGET);
    if (!targetAttr) return el;
    if (targetAttr === 'this') return el;
    if (targetAttr === 'body') return document.body;
    if (targetAttr.startsWith('closest ')) {
      return el.closest(targetAttr.slice(8));
    }
    if (targetAttr.startsWith('find ')) {
      return el.querySelector(targetAttr.slice(5));
    }
    return document.querySelector(targetAttr);
  }

  function getSwapStyle(el) {
    return el.getAttribute(MHX_ATTRS.SWAP) || 'innerHTML';
  }

  function swap(target, content, style) {
    switch (style) {
      case 'innerHTML':
        target.innerHTML = content;
        break;
      case 'outerHTML':
        target.outerHTML = content;
        break;
      case 'beforebegin':
        target.insertAdjacentHTML('beforebegin', content);
        break;
      case 'afterbegin':
        target.insertAdjacentHTML('afterbegin', content);
        break;
      case 'beforeend':
        target.insertAdjacentHTML('beforeend', content);
        break;
      case 'afterend':
        target.insertAdjacentHTML('afterend', content);
        break;
      case 'delete':
        target.remove();
        break;
      case 'none':
        break;
      default:
        target.innerHTML = content;
    }
  }

  function handlePushUrl(el, responseUrl) {
    const pushUrl = el.getAttribute(MHX_ATTRS.PUSH_URL);
    const replaceUrl = el.getAttribute(MHX_ATTRS.REPLACE_URL);

    if (pushUrl) {
      const url = pushUrl === 'true' ? responseUrl : pushUrl;
      history.pushState({}, '', url);
    } else if (replaceUrl) {
      const url = replaceUrl === 'true' ? responseUrl : replaceUrl;
      history.replaceState({}, '', url);
    }
  }

  async function makeRequest(el) {
    const reqInfo = getMethod(el);
    if (!reqInfo) return;

    const target = getTarget(el);
    if (!target) {
      console.warn('MHX: Target not found');
      return;
    }

    const swapStyle = getSwapStyle(el);

    // Add loading class
    el.classList.add('mx-request');

    try {
      const response = await fetch(reqInfo.url, {
        method: reqInfo.method,
        headers: {
          'MX-Request': 'true',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const content = await response.text();
      swap(target, content, swapStyle);
      handlePushUrl(el, reqInfo.url);

      // Re-initialize any new elements
      initializeElements(target);
    } catch (error) {
      console.error('MHX request failed:', error);
    } finally {
      el.classList.remove('mx-request');
    }
  }

  function getTrigger(el) {
    const trigger = el.getAttribute(MHX_ATTRS.TRIGGER);
    if (trigger) return trigger.split(' ')[0]; // Get first event, ignore modifiers for now

    // Default triggers based on element type
    const tagName = el.tagName.toLowerCase();
    if (tagName === 'form') return 'submit';
    if (tagName === 'input' || tagName === 'textarea' || tagName === 'select') {
      return 'change';
    }
    return 'click';
  }

  function initializeElement(el) {
    if (el.dataset.mxInitialized) return;

    const reqInfo = getMethod(el);
    if (!reqInfo) return;

    const trigger = getTrigger(el);

    el.addEventListener(trigger, (e) => {
      e.preventDefault();
      makeRequest(el);
    });

    el.dataset.mxInitialized = 'true';
  }

  function initializeElements(root = document) {
    const selector = Object.values(MHX_ATTRS)
      .filter(attr => ['mx-get', 'mx-post', 'mx-put', 'mx-patch', 'mx-delete'].includes(attr))
      .map(attr => `[${attr}]`)
      .join(',');

    root.querySelectorAll(selector).forEach(initializeElement);
  }

  // Handle back/forward navigation
  window.addEventListener('popstate', () => {
    // Reload the current page content
    fetch(window.location.href, {
      headers: { 'MX-Request': 'true' }
    })
    .then(response => response.text())
    .then(html => {
      // Try to update just the main content area
      const parser = new DOMParser();
      const doc = parser.parseFromString(html, 'text/html');
      const newContent = doc.querySelector('#posts-container');
      const currentContent = document.querySelector('#posts-container');
      if (newContent && currentContent) {
        currentContent.innerHTML = newContent.innerHTML;
        initializeElements(currentContent);
      }
    })
    .catch(() => {
      // Fallback to full page reload
      window.location.reload();
    });
  });

  // Initialize on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => initializeElements());
  } else {
    initializeElements();
  }

  // Observe for dynamically added elements
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      mutation.addedNodes.forEach((node) => {
        if (node.nodeType === 1) {
          initializeElement(node);
          initializeElements(node);
        }
      });
    });
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true,
  });

  // Expose MHX globally for debugging
  window.MHX = {
    initialize: initializeElements,
    request: makeRequest,
  };
})();
