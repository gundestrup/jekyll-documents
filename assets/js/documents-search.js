/* Minimal client-side search using Lunr and the generated document index.
   Usage on any page:
     {% include documents_search.html %}
*/
(function () {
  const input = document.getElementById("doc-search-input");
  const resultsEl = document.getElementById("doc-search-results");
  if (!input || !resultsEl) return;

  const indexUrl = window.__jekyllDocumentsIndexPath || "/documents.json";
  let idx, docs = [];

  function escapeHtml(value) {
    const div = document.createElement("div");
    div.appendChild(document.createTextNode(String(value)));
    return div.innerHTML
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;");
  }

  function withBaseurl(url) {
    const value = String(url || "");
    if (!value || /^(?:[a-z][a-z\d+.-]*:|\/\/)/i.test(value)) return value;

    const baseurl = String(window.__jekyllDocumentsBaseurl || "")
      .replace(/^\/+|\/+$/g, "");
    const path = value.replace(/^\/+/, "");
    return `/${[baseurl, path].filter(Boolean).join("/")}`;
  }

  function getIconTag(fileType, iconUrl) {
    if (!iconUrl) return "";
    const altText = `${String(fileType || "file").toUpperCase()} file`;
    const url = escapeHtml(withBaseurl(iconUrl));
    return `<img src="${url}" alt="${escapeHtml(altText)}" class="file-icon" />`;
  }

  function render(matches) {
    if (!matches || matches.length === 0) {
      resultsEl.innerHTML = "<p>No results.</p>";
      return;
    }

    const items = matches.slice(0, 20).map(match => {
      const document = docs.find(item => item.url === match.ref);
      if (!document) return "";

      const title = escapeHtml(document.title || "Untitled");
      const category = escapeHtml(document.category || "uncategorized");
      const date = document.date ? `<small>${escapeHtml(document.date)}</small>` : "";
      const icon = getIconTag(document.file_type, document.icon_url);
      const url = escapeHtml(withBaseurl(document.url));
      return `<li>${icon}<a href="${url}">${title}</a> ` +
        `<small>[${category}]</small> ${date}</li>`;
    });
    resultsEl.innerHTML = `<ul class="documents-search-list">${items.join("")}</ul>`;
  }

  function debounce(fn, wait) {
    let timer;
    return function (...args) {
      clearTimeout(timer);
      timer = setTimeout(() => fn.apply(this, args), wait);
    };
  }

  function buildIndex() {
    idx = lunr(function () {
      this.ref("url");
      this.field("title", { boost: 10 });
      this.field("category", { boost: 5 });
      this.field("slug");
      docs.forEach(document => this.add(document));
    });
  }

  function doSearch(query) {
    if (!idx || !query || query.trim().length === 0) {
      resultsEl.innerHTML = "";
      return;
    }

    try {
      render(idx.search(query));
    } catch (error) {
      // If Lunr query syntax fails, fall back to a simple contains filter.
      const normalizedQuery = query.toLowerCase();
      const matches = docs.filter(document =>
        [document.title, document.category, document.slug].some(value =>
          String(value || "").toLowerCase().includes(normalizedQuery)
        )
      ).map(document => ({ ref: document.url }));
      render(matches);
    }
  }

  fetch(indexUrl)
    .then(response => {
      if (!response.ok) {
        throw new Error(`Search index request failed: ${response.status}`);
      }
      return response.json();
    })
    .then(json => {
      if (!Array.isArray(json)) {
        throw new Error("Search index must be a JSON array");
      }
      docs = json;
      buildIndex();
    })
    .catch(error => {
      resultsEl.innerHTML = "<p>Document search is currently unavailable.</p>";
      console.error("Documents search index failed:", error);
    });

  input.addEventListener("input", debounce(event => doSearch(event.target.value), 150));
})();
