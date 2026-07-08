// Blog listing: data-driven search + tag/topic filtering with numbered
// pagination, kept in sync with the URL. The full post list is embedded in the
// page as JSON (#blog-index-data); this script hydrates the grid from it and
// rebuilds the visible cards on every filter/page change.
//
// URL model:
//   /blog                       all posts, page 1
//   /blog/<n>                   all posts, page n
//   /blog/topic/<topic>         posts with that topic, page 1
//   /blog/topic/<topic>/<n>     that topic, page n
//   ?search=<text>&tags=<a>,<b> applied on top of the path
// Search matches title, category, subtitle and tag labels; tags match the
// post's slugs (OR within selected tags, AND against search/topic). Toggling a
// chip or typing in search resets pagination to page 1. The featured post sits
// above the grid whenever no filter is active.
(function () {
  "use strict";

  var PER_PAGE = 6;

  var controls = document.querySelector(".blog-controls");
  if (!controls) return;

  var dataEl = document.getElementById("blog-index-data");
  if (!dataEl) return;

  var posts;
  try {
    posts = JSON.parse(dataEl.textContent);
  } catch (e) {
    return;
  }
  if (!posts || !posts.length) return;

  var search = controls.querySelector(".blog-search");
  var menu = controls.querySelector(".blog-tags-menu");
  var toggle = controls.querySelector(".blog-tags-toggle");
  var popover = controls.querySelector(".blog-tags-popover");
  var clearBtn = controls.querySelector(".blog-tags-clear");
  var chips = Array.prototype.slice.call(
    controls.querySelectorAll(".blog-filter-chip")
  );

  var featured = document.querySelector(".blog-featured");
  var grid = document.querySelector(".blog-grid");
  var pagination = document.querySelector(".blog-pagination");
  var empty = document.querySelector(".blog-empty");

  var TOGGLE_LABEL = "Tags";

  // State is derived from the URL; interactions update it and write the URL back.
  var state = { topic: null, page: 1, search: "", tags: Object.create(null) };

  function slugify(s) {
    return String(s || "").toLowerCase().replace(/ /g, "-");
  }

  function tagCount() {
    return Object.keys(state.tags).length;
  }

  function filtersActive() {
    return state.search !== "" || tagCount() > 0 || state.topic !== null;
  }

  // ---- URL <-> state -------------------------------------------------------

  function readState() {
    var path = location.pathname.replace(/\/+$/, "");
    var rest = path.replace(/^\/blog/, "");
    var parts = rest.split("/").filter(Boolean);

    state.topic = null;
    state.page = 1;
    if (parts.length) {
      if (parts[0] === "topic") {
        if (parts[1]) state.topic = decodeURIComponent(parts[1]);
        if (parts[2] && /^\d+$/.test(parts[2])) state.page = parseInt(parts[2], 10);
      } else if (/^\d+$/.test(parts[0])) {
        state.page = parseInt(parts[0], 10);
      }
    }
    if (state.page < 1) state.page = 1;

    var params = new URLSearchParams(location.search);
    state.search = params.get("search") || "";
    state.tags = Object.create(null);
    var tagsParam = params.get("tags") || "";
    tagsParam.split(",").forEach(function (t) {
      t = t.trim();
      if (t) state.tags[t] = true;
    });
  }

  function buildUrl() {
    var path = "/blog";
    if (state.topic) path += "/topic/" + encodeURIComponent(state.topic);
    if (state.page > 1) path += "/" + state.page;

    var params = new URLSearchParams();
    if (state.search) params.set("search", state.search);
    var tags = Object.keys(state.tags);
    if (tags.length) params.set("tags", tags.join(","));
    var qs = params.toString();
    return qs ? path + "?" + qs : path;
  }

  function pushUrl() {
    history.pushState(null, "", buildUrl());
  }
  function replaceUrl() {
    history.replaceState(null, "", buildUrl());
  }

  // ---- Filtering -----------------------------------------------------------

  function postSlugs(post) {
    return (post.tags || []).map(slugify);
  }

  function matchingPosts() {
    if (!filtersActive()) return posts.slice();
    var q = state.search.toLowerCase();
    var selected = state.tags;
    var hasTags = tagCount() > 0;
    return posts.filter(function (post) {
      if (state.topic !== null && slugify(post.topic) !== state.topic) {
        return false;
      }
      if (hasTags) {
        var slugs = postSlugs(post);
        var hit = slugs.some(function (s) {
          return selected[s];
        });
        if (!hit) return false;
      }
      if (q) {
        var hay = [
          post.title,
          post.header,
          post.subtitle,
          (post.tags || []).join(" "),
        ]
          .join(" ")
          .toLowerCase();
        if (hay.indexOf(q) === -1) return false;
      }
      return true;
    });
  }

  // ---- Card rendering ------------------------------------------------------

  function buildCard(post) {
    var a = document.createElement("a");
    a.className = "blog-card " + (post.gradient || "");
    a.setAttribute("href", "/blog/" + post.name);
    a.setAttribute("data-tags", postSlugs(post).join(" "));

    var tags = post.tags || [];
    if (tags.length) {
      var ul = document.createElement("ul");
      ul.className = "blog-card-tags";
      tags.forEach(function (label) {
        var li = document.createElement("li");
        li.className = "blog-card-tag";
        li.textContent = label;
        ul.appendChild(li);
      });
      a.appendChild(ul);
    }

    var extra = document.createElement("span");
    extra.className = "blog-card-extra";
    extra.textContent = post.header || "";
    a.appendChild(extra);

    var title = document.createElement("h3");
    title.className = "blog-card-title";
    // Match the static build: render straight apostrophes as typographic ones.
    title.textContent = String(post.title || "").replace(/'/g, "’");
    a.appendChild(title);

    var subtitle = document.createElement("span");
    subtitle.className = "blog-card-subtitle";
    subtitle.textContent = post.subtitle || "";
    a.appendChild(subtitle);

    return a;
  }

  // ---- Pagination controls -------------------------------------------------

  function pageButton(label, target, disabled, ariaLabel, isCurrent) {
    var b = document.createElement("button");
    b.type = "button";
    b.className = "blog-page-btn";
    b.textContent = label;
    if (ariaLabel) b.setAttribute("aria-label", ariaLabel);
    if (isCurrent) {
      b.classList.add("is-active");
      b.setAttribute("aria-current", "page");
    }
    if (disabled) {
      b.disabled = true;
    } else {
      b.addEventListener("click", function () {
        state.page = target;
        pushUrl();
        render();
      });
    }
    return b;
  }

  function renderPagination(totalPages) {
    if (!pagination) return;
    pagination.textContent = "";
    if (totalPages <= 1) {
      pagination.hidden = true;
      return;
    }
    pagination.hidden = false;
    pagination.appendChild(
      pageButton("‹", state.page - 1, state.page === 1, "Previous page", false)
    );
    for (var p = 1; p <= totalPages; p++) {
      pagination.appendChild(
        pageButton(String(p), p, false, "Page " + p, p === state.page)
      );
    }
    pagination.appendChild(
      pageButton("›", state.page + 1, state.page === totalPages, "Next page", false)
    );
  }

  // ---- Render --------------------------------------------------------------

  function render() {
    var active = filtersActive();

    // When filtering, drop the featured distinction; every matching post is
    // shown inline in the paginated grid.
    if (featured) featured.hidden = active;

    var matches = matchingPosts();
    var totalPages = Math.max(1, Math.ceil(matches.length / PER_PAGE));
    if (state.page > totalPages) state.page = totalPages;
    if (state.page < 1) state.page = 1;

    var start = (state.page - 1) * PER_PAGE;
    var pagePosts = matches.slice(start, start + PER_PAGE);

    if (grid) {
      grid.textContent = "";
      pagePosts.forEach(function (post) {
        grid.appendChild(buildCard(post));
      });
    }

    if (empty) empty.hidden = !(active && matches.length === 0);
    renderPagination(totalPages);

    if (toggle) {
      var count = tagCount();
      toggle.textContent = count ? TOGGLE_LABEL + " (" + count + ")" : TOGGLE_LABEL;
      toggle.classList.toggle("is-active", count > 0);
    }
  }

  // Reflect the current state onto the controls (search box + chips).
  function syncControls() {
    if (search) search.value = state.search;
    chips.forEach(function (chip) {
      var on = !!state.tags[chip.dataset.tag];
      chip.classList.toggle("is-active", on);
      chip.setAttribute("aria-pressed", on ? "true" : "false");
    });
  }

  // ---- Popover -------------------------------------------------------------

  function onOutside(e) {
    if (menu && !menu.contains(e.target)) closePopover();
  }
  function onKey(e) {
    if (e.key === "Escape" || e.key === "Esc") {
      closePopover();
      if (toggle) toggle.focus();
    }
  }
  function openPopover() {
    if (!popover) return;
    popover.hidden = false;
    if (toggle) toggle.setAttribute("aria-expanded", "true");
    document.addEventListener("click", onOutside, true);
    document.addEventListener("keydown", onKey);
  }
  function closePopover() {
    if (!popover) return;
    popover.hidden = true;
    if (toggle) toggle.setAttribute("aria-expanded", "false");
    document.removeEventListener("click", onOutside, true);
    document.removeEventListener("keydown", onKey);
  }

  if (toggle) {
    toggle.addEventListener("click", function () {
      if (popover && popover.hidden) openPopover();
      else closePopover();
    });
  }

  // ---- Interactions --------------------------------------------------------

  chips.forEach(function (chip) {
    chip.addEventListener("click", function () {
      var tag = chip.dataset.tag;
      if (!tag) return;
      if (state.tags[tag]) delete state.tags[tag];
      else state.tags[tag] = true;
      state.page = 1;
      syncControls();
      pushUrl();
      render();
    });
  });

  if (clearBtn) {
    clearBtn.addEventListener("click", function () {
      state.tags = Object.create(null);
      state.page = 1;
      syncControls();
      pushUrl();
      render();
    });
  }

  if (search) {
    search.addEventListener("input", function () {
      state.search = search.value.trim();
      state.page = 1;
      // replaceState so per-keystroke typing doesn't flood the history stack.
      replaceUrl();
      render();
    });
  }

  window.addEventListener("popstate", function () {
    readState();
    syncControls();
    render();
  });

  readState();
  syncControls();
  render();
})();

// Code-block copy buttons on blog post pages. Wraps each rendered code block in
// a positioned container and adds a "Copy" button revealed on hover. No-ops on
// pages without rendered Markdown code (e.g. the blog listing).
(function () {
  "use strict";

  var blocks = document.querySelectorAll(".post-content pre.hljs");
  if (!blocks.length) return;

  Array.prototype.forEach.call(blocks, function (pre) {
    // Wrap the <pre> so the button can be pinned to the block while the code
    // itself scrolls horizontally underneath it.
    var wrap = document.createElement("div");
    wrap.className = "code-block";
    pre.parentNode.insertBefore(wrap, pre);
    wrap.appendChild(pre);

    var btn = document.createElement("button");
    btn.type = "button";
    btn.className = "code-copy-btn";
    btn.textContent = "Copy";
    btn.setAttribute("aria-label", "Copy code to clipboard");
    wrap.appendChild(btn);

    var resetTimer = null;

    function flash(label) {
      btn.textContent = label;
      btn.classList.add("is-copied");
      if (resetTimer) clearTimeout(resetTimer);
      resetTimer = setTimeout(function () {
        btn.textContent = "Copy";
        btn.classList.remove("is-copied");
      }, 1500);
    }

    btn.addEventListener("click", function () {
      var code = pre.querySelector("code");
      var text = code ? code.textContent : pre.textContent;

      function fallback() {
        var ta = document.createElement("textarea");
        ta.value = text;
        ta.setAttribute("readonly", "");
        ta.style.position = "fixed";
        ta.style.opacity = "0";
        document.body.appendChild(ta);
        ta.select();
        try {
          document.execCommand("copy");
          flash("Copied");
        } catch (e) {
          /* clipboard unavailable */
        }
        document.body.removeChild(ta);
      }

      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(function () {
          flash("Copied");
        }, fallback);
      } else {
        fallback();
      }
    });
  });
})();
