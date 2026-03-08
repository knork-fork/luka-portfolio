document.addEventListener('DOMContentLoaded', function () {
  var overlay = document.createElement('div');
  overlay.className = 'lightbox-overlay';
  overlay.innerHTML =
    '<button class="lightbox-close" aria-label="Close">&times;</button>' +
    '<img class="lightbox-img" src="" alt="">';
  document.body.appendChild(overlay);

  var img = overlay.querySelector('.lightbox-img');
  var closeBtn = overlay.querySelector('.lightbox-close');

  function open(src) {
    img.src = src;
    overlay.classList.add('active');
  }

  function close() {
    overlay.classList.remove('active');
  }

  document.querySelectorAll('.showcase-screenshot').forEach(function (el) {
    el.addEventListener('click', function (e) {
      e.stopPropagation();
      var bg = el.style.backgroundImage;
      var match = bg.match(/url\(["']?(.+?)["']?\)/);
      if (match) open(match[1]);
    });
  });

  document.querySelectorAll('.showcase-card').forEach(function (card) {
    card.addEventListener('click', function () {
      card.classList.toggle('expanded');
    });
  });

  closeBtn.addEventListener('click', close);

  overlay.addEventListener('click', function (e) {
    if (e.target === overlay) close();
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') close();
  });
});
