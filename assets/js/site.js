(function () {
  var root = document.documentElement;
  var themeToggle = document.querySelector("[data-theme-toggle]");
  var themeLabel = document.querySelector("[data-theme-label]");
  var themeIcon = document.querySelector("[data-theme-icon]");

  function updateThemeToggle(theme) {
    if (!themeToggle) {
      return;
    }

    themeToggle.setAttribute("aria-pressed", String(theme === "dark"));
    if (themeLabel) {
      themeLabel.textContent = theme === "dark" ? "다크" : "라이트";
    }
    if (themeIcon) {
      themeIcon.textContent = theme === "dark" ? "☾" : "☼";
    }
  }

  function setTheme(theme) {
    root.setAttribute("data-theme", theme);
    updateThemeToggle(theme);
    try {
      localStorage.setItem("reading-list-theme", theme);
    } catch (error) {
      return;
    }
  }

  updateThemeToggle(root.getAttribute("data-theme") || "light");

  if (themeToggle) {
    themeToggle.addEventListener("click", function () {
      var nextTheme = root.getAttribute("data-theme") === "dark" ? "light" : "dark";
      setTheme(nextTheme);
    });
  }

  var filterRoot = document.querySelector("[data-filter-root]");
  if (!filterRoot) {
    return;
  }

  var reportCards = Array.prototype.slice.call(document.querySelectorAll("[data-report-card]"));
  var tagButtons = Array.prototype.slice.call(document.querySelectorAll("[data-tag-filter]"));
  var resetButton = filterRoot.querySelector("[data-tag-reset]");
  var statusNode = filterRoot.querySelector("[data-filter-status]");
  var emptyState = filterRoot.querySelector("[data-filter-empty]");
  var params = new URLSearchParams(window.location.search);
  var activeTag = params.get("tag") || "";

  function syncFilterState() {
    var visibleCount = 0;

    reportCards.forEach(function (card) {
      var tags = (card.getAttribute("data-tags") || "").split("||").filter(Boolean);
      var matches = !activeTag || tags.indexOf(activeTag) !== -1;
      card.hidden = !matches;
      if (matches) {
        visibleCount += 1;
      }
    });

    tagButtons.forEach(function (button) {
      button.setAttribute("aria-pressed", String(button.getAttribute("data-tag-filter") === activeTag));
    });

    if (statusNode) {
      statusNode.textContent = activeTag ? '"' + activeTag + '" 태그 ' + visibleCount + "건" : "전체 " + visibleCount + "건";
    }

    if (resetButton) {
      resetButton.hidden = !activeTag;
    }

    if (emptyState) {
      emptyState.hidden = visibleCount > 0;
    }

    var nextUrl = new URL(window.location.href);
    if (activeTag) {
      nextUrl.searchParams.set("tag", activeTag);
    } else {
      nextUrl.searchParams.delete("tag");
    }
    window.history.replaceState({}, "", nextUrl.toString());
  }

  tagButtons.forEach(function (button) {
    button.addEventListener("click", function () {
      var tag = button.getAttribute("data-tag-filter");
      activeTag = activeTag === tag ? "" : tag;
      syncFilterState();
    });
  });

  if (resetButton) {
    resetButton.addEventListener("click", function () {
      activeTag = "";
      syncFilterState();
    });
  }

  syncFilterState();
}());
