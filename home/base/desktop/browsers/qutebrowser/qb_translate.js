// Translate the current page in place using Google Translate's free gtx
// endpoint. Bound to a key via `:jseval --file qb_translate.js -q` (see
// config.py). Pressing the key again restores the original text.
(async () => {
  const TARGET_LANG = "en"; // change to your target language code (e.g. 'de', 'fr')
  const API = "https://translate.googleapis.com/translate_a/single";
  const SKIP_TAGS = new Set([
    "SCRIPT",
    "STYLE",
    "NOSCRIPT",
    "TEXTAREA",
    "INPUT",
    "CODE",
    "PRE",
    "TEMPLATE",
    "SVG",
    "IFRAME",
  ]);
  const BATCH_MAX_CHARS = 1500;
  const CONCURRENCY = 4;
  const SEP = "\n";

  if (window.__qbTranslating) return;

  if (window.__qbTranslated) {
    for (const [node, original] of window.__qbOriginals) {
      node.nodeValue = original;
    }
    window.__qbTranslated = false;
    return;
  }

  function isVisible(el) {
    if (!el) return true;
    if (typeof el.checkVisibility === "function") {
      return el.checkVisibility({ checkOpacity: false, checkVisibilityCSS: true });
    }
    const style = getComputedStyle(el);
    return style.display !== "none" && style.visibility !== "hidden";
  }

  function collectTextNodes(root) {
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode(node) {
        if (!node.nodeValue || !node.nodeValue.trim()) return NodeFilter.FILTER_REJECT;
        const parent = node.parentElement;
        if (!parent || SKIP_TAGS.has(parent.tagName)) return NodeFilter.FILTER_REJECT;
        if (parent.closest('[contenteditable="true"]')) return NodeFilter.FILTER_REJECT;
        if (!isVisible(parent)) return NodeFilter.FILTER_REJECT;
        return NodeFilter.FILTER_ACCEPT;
      },
    });
    const nodes = [];
    let n;
    while ((n = walker.nextNode())) nodes.push(n);
    return nodes;
  }

  async function translateText(text) {
    const url = `${API}?client=gtx&sl=auto&tl=${TARGET_LANG}&dt=t&q=${encodeURIComponent(text)}`;
    const res = await fetch(url);
    if (!res.ok) throw new Error(`translate HTTP ${res.status}`);
    const data = await res.json();
    return data[0].map((chunk) => chunk[0]).join("");
  }

  function chunkNodes(nodes) {
    const batches = [];
    let current = [];
    let len = 0;
    for (const node of nodes) {
      const size = node.nodeValue.length + 1;
      if (len + size > BATCH_MAX_CHARS && current.length) {
        batches.push(current);
        current = [];
        len = 0;
      }
      current.push(node);
      len += size;
    }
    if (current.length) batches.push(current);
    return batches;
  }

  async function translateIndividually(nodes) {
    await Promise.all(
      nodes.map(async (node) => {
        try {
          const translated = await translateText(node.nodeValue);
          window.__qbOriginals.set(node, node.nodeValue);
          node.nodeValue = translated;
        } catch (e) {
          // leave this node untranslated on error
        }
      })
    );
  }

  async function translateBatch(nodes) {
    const joined = nodes.map((n) => n.nodeValue).join(SEP);
    let parts = null;
    try {
      const translated = await translateText(joined);
      parts = translated.split(SEP);
    } catch (e) {
      parts = null;
    }
    if (!parts || parts.length !== nodes.length) {
      await translateIndividually(nodes);
      return;
    }
    nodes.forEach((node, i) => {
      window.__qbOriginals.set(node, node.nodeValue);
      node.nodeValue = parts[i];
    });
  }

  window.__qbTranslating = true;
  window.__qbOriginals = new Map();
  try {
    const nodes = collectTextNodes(document.body);
    const batches = chunkNodes(nodes);
    let idx = 0;
    async function worker() {
      while (idx < batches.length) {
        const batch = batches[idx++];
        await translateBatch(batch);
      }
    }
    await Promise.all(Array.from({ length: CONCURRENCY }, worker));
    window.__qbTranslated = true;
  } finally {
    window.__qbTranslating = false;
  }
})();
