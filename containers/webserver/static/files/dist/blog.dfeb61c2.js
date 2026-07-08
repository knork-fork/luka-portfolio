// Blog listing: search + tag popover filtering with numbered pagination.
// Filters run client-side over the already-rendered cards. Search matches the
// card's visible text (title, category, subtitle, tag labels); tags match the
// card's data-tags slugs. Search and tags combine (AND across the two, OR
// within selected tags). Matching cards are paged PER_PAGE at a time. The
// featured post sits above the grid and is unaffected by pagination.
(function () {
  "use strict";

  var PER_PAGE = 6;

  var controls = document.querySelector(".blog-controls");
  if (!controls) return;

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
  var cards = grid
    ? Array.prototype.slice.call(grid.querySelectorAll(".blog-card"))
    : [];

  var TOGGLE_LABEL = "Tags";
  var selected = Object.create(null);
  var selectedCount = 0;
  var page = 1;

  function query() {
    return search ? search.value.trim().toLowerCase() : "";
  }

  function filtersActive() {
    return query() !== "" || selectedCount > 0;
  }

  function matchingCards() {
    var active = filtersActive();
    if (!active) return cards.slice();
    var q = query();
    return cards.filter(function (card) {
      var matchesSearch =
        !q || card.textContent.toLowerCase().indexOf(q) !== -1;
      var cardTags = (card.dataset.tags || "").split(" ").filter(Boolean);
      var matchesTags =
        selectedCount === 0 ||
        cardTags.some(function (t) {
          return selected[t];
        });
      return matchesSearch && matchesTags;
    });
  }

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
        page = target;
        apply();
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
      pageButton("‹", page - 1, page === 1, "Previous page", false)
    );
    for (var p = 1; p <= totalPages; p++) {
      pagination.appendChild(
        pageButton(String(p), p, false, "Page " + p, p === page)
      );
    }
    pagination.appendChild(
      pageButton("›", page + 1, page === totalPages, "Next page", false)
    );
  }

  function apply() {
    var active = filtersActive();

    // When filtering, drop the featured distinction; every matching post is
    // shown inline in the paginated grid.
    if (featured) featured.hidden = active;

    var matches = matchingCards();
    var totalPages = Math.max(1, Math.ceil(matches.length / PER_PAGE));
    if (page > totalPages) page = totalPages;
    if (page < 1) page = 1;

    var start = (page - 1) * PER_PAGE;
    var pageCards = matches.slice(start, start + PER_PAGE);

    cards.forEach(function (card) {
      card.classList.add("blog-card-hidden");
    });
    pageCards.forEach(function (card) {
      card.classList.remove("blog-card-hidden");
    });

    if (empty) empty.hidden = !(active && matches.length === 0);
    renderPagination(totalPages);

    if (toggle) {
      toggle.textContent = selectedCount
        ? TOGGLE_LABEL + " (" + selectedCount + ")"
        : TOGGLE_LABEL;
      toggle.classList.toggle("is-active", selectedCount > 0);
    }
  }

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

  chips.forEach(function (chip) {
    chip.addEventListener("click", function () {
      var tag = chip.dataset.tag;
      if (!tag) return;
      if (selected[tag]) {
        delete selected[tag];
        selectedCount--;
        chip.classList.remove("is-active");
        chip.setAttribute("aria-pressed", "false");
      } else {
        selected[tag] = true;
        selectedCount++;
        chip.classList.add("is-active");
        chip.setAttribute("aria-pressed", "true");
      }
      page = 1;
      apply();
    });
  });

  if (clearBtn) {
    clearBtn.addEventListener("click", function () {
      selected = Object.create(null);
      selectedCount = 0;
      chips.forEach(function (chip) {
        chip.classList.remove("is-active");
        chip.setAttribute("aria-pressed", "false");
      });
      page = 1;
      apply();
    });
  }

  if (search) {
    search.addEventListener("input", function () {
      page = 1;
      apply();
    });
  }

  apply();
})();
