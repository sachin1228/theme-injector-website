/* ============================================================
   Theme Injector site — vanilla JS, progressive enhancement.
   Without JS: the video still autoplays (muted) and every
   download link still works; only the guide modals are skipped.
   ============================================================ */
(function () {
  'use strict';

  /* ---------------- platform highlight ----------------
     Promote the least-friction build for the visitor:
     Windows -> the .exe, Mac -> Apple Silicon .dmg (then
     refine to Intel via the high-entropy UA client hints). */
  var allBtns = Array.prototype.slice.call(document.querySelectorAll('.dl-btn'));
  function setPrimary(id) {
    allBtns.forEach(function (b) {
      b.classList.remove('primary');
      b.classList.add('secondary');
    });
    var el = document.getElementById(id);
    if (el) {
      el.classList.remove('secondary');
      el.classList.add('primary');
    }
  }

  var platform = (navigator.userAgentData && navigator.userAgentData.platform) || navigator.platform || '';
  var ua = navigator.userAgent || '';
  var isMac = /mac/i.test(platform) && !/iphone|ipad|ipod/i.test(ua);

  if (isMac) {
    setPrimary('dlMacArm');
    if (navigator.userAgentData && navigator.userAgentData.getHighEntropyValues) {
      navigator.userAgentData.getHighEntropyValues(['architecture']).then(function (v) {
        if (v && v.architecture === 'x86') setPrimary('dlMacIntel');
      }).catch(function () { /* keep the arm64 default */ });
    }
  } else if (/win/i.test(platform)) {
    setPrimary('dlWindows');
  }

  /* ---------------- hero video ----------------
     Click-to-play: the video never autoplays. The centre button starts it,
     then hides itself while the recording runs (hover or a moving pointer
     brings the pause control back), and one playthrough ends paused. */
  var video = document.getElementById('heroVideo');
  var overlay = document.getElementById('playOverlay');
  var playLabel = document.getElementById('playLabel');

  /* The .is-playing class is the single source of truth: CSS clears the scrim
     and hides the caption. The two glyphs are ALSO switched inline, because a
     browser serving a stale cached stylesheet would otherwise leave both the
     play triangle and the pause bars painted at once.
     (Toggling `.hidden` on the <svg> icons would be a no-op — SVG elements
     have no such IDL property.) */
  var iconPlay = document.getElementById('iconPlay');
  var iconPause = document.getElementById('iconPause');

  function setPlayingUI(playing) {
    if (!overlay) return;
    if (playing) overlay.classList.add('is-playing');
    else overlay.classList.remove('is-playing');
    if (iconPlay) iconPlay.style.display = playing ? 'none' : 'block';
    if (iconPause) iconPause.style.display = playing ? 'block' : 'none';
    overlay.setAttribute('aria-label', playing ? 'Pause preview' : 'Play preview');
  }

  /* While the recording plays the control steps out of the way: it shows for
     a moment after the press — so the pause button is visibly there — and
     then fades out. A moving pointer brings it back for the same beat. */
  var HIDE_AFTER = 2000;
  var hideControlsTimer;

  function revealControls() {
    if (!overlay || !video || video.paused) return;
    overlay.classList.add('show-controls');
    clearTimeout(hideControlsTimer);
    hideControlsTimer = setTimeout(function () {
      overlay.classList.remove('show-controls');
    }, HIDE_AFTER);
  }

  function dropControls() {
    clearTimeout(hideControlsTimer);
    if (overlay) overlay.classList.remove('show-controls');
  }

  if (video && overlay) {
    video.addEventListener('playing', function () {
      setPlayingUI(true);
      /* never autoplay, and if something else started it, make sure the
         poster state is consistent before the control fades away */
      revealControls();
      /* replaying from the start: the caption goes back to plain "Play" */
      if (playLabel) playLabel.textContent = 'Play preview · 19 s';
    });
    video.addEventListener('pause', function () { setPlayingUI(false); });
    video.addEventListener('error', function () { setPlayingUI(false); });
    video.addEventListener('ended', function () {
      setPlayingUI(false);
      if (playLabel) playLabel.textContent = 'Replay preview · 19 s';
    });

    overlay.addEventListener('mousemove', revealControls);
    overlay.addEventListener('mouseleave', dropControls);

    overlay.addEventListener('click', function () {
      if (video.paused) {
        var p = video.play();
        if (p && p.catch) p.catch(function () {});
      } else {
        video.pause();
      }
    });

    /* A muted recording that keeps running off-screen feels like the page
       playing itself, so the preview stops when its frame scrolls away. */
    if ('IntersectionObserver' in window) {
      var frame = video.closest('.video-frame') || video;
      new IntersectionObserver(function (entries) {
        entries.forEach(function (en) {
          if (!en.isIntersecting && !video.paused) { video.pause(); dropControls(); }
        });
      }, { threshold: 0.25 }).observe(frame);
    }
  }

  /* ---------------- download modals ---------------- */
  var backdrop = document.getElementById('modalBackdrop');
  var modalWin = document.getElementById('modalWin');
  var modalMac = document.getElementById('modalMac');
  var macFileLine = document.getElementById('macFileLine');
  var lastFocus = null;
  var openModal = null;

  function showModal(which) {
    if (!backdrop) return;
    lastFocus = document.activeElement;
    backdrop.hidden = false;
    modalWin.hidden = which !== 'win';
    modalMac.hidden = which !== 'mac';
    openModal = which;
    document.body.style.overflow = 'hidden';
    /* focus the dialog itself (not the footer button) so opening never
       scrolls past the top of the instructions */
    var dialog = which === 'win' ? modalWin : modalMac;
    try { dialog.focus({ preventScroll: true }); } catch (err) { dialog.focus(); }
  }

  function close() {
    if (!backdrop || backdrop.hidden) return;
    backdrop.hidden = true;
    modalWin.hidden = true;
    modalMac.hidden = true;
    openModal = null;
    document.body.style.overflow = '';
    if (lastFocus && lastFocus.focus) lastFocus.focus();
  }

  /* Each download button starts its file AND opens its guide.
     The <a href> keeps working without JS. */
  allBtns.forEach(function (btn) {
    btn.addEventListener('click', function () {
      var kind = btn.getAttribute('data-modal');
      if (kind === 'mac' && macFileLine) {
        macFileLine.innerHTML = '<b>' + btn.getAttribute('data-file') + '</b> · ' +
          btn.getAttribute('data-size') + ' · ' + btn.getAttribute('data-chip') +
          ' — saving to your Downloads folder.';
        showModal('mac');
      } else if (kind === 'win') {
        showModal('win');
      }
    });
  });

  Array.prototype.forEach.call(document.querySelectorAll('.modal-close'), function (b) {
    b.addEventListener('click', close);
  });

  if (backdrop) {
    backdrop.addEventListener('click', function (e) {
      if (e.target === backdrop) close();
    });
  }

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && openModal) close();
  });

  /* ---------------- copy the xattr command ---------------- */
  var copyBtn = document.getElementById('copyCmd');
  if (copyBtn) {
    copyBtn.addEventListener('click', function () {
      var cmd = document.getElementById('xattrCmd').textContent;
      function done() {
        copyBtn.textContent = 'Copied';
        setTimeout(function () { copyBtn.textContent = 'Copy'; }, 1500);
      }
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(cmd).then(done).catch(function () { fallback(); });
      } else {
        fallback();
      }
      function fallback() {
        var ta = document.createElement('textarea');
        ta.value = cmd;
        ta.style.position = 'fixed';
        ta.style.opacity = '0';
        document.body.appendChild(ta);
        ta.select();
        try { document.execCommand('copy'); done(); } catch (err) {}
        document.body.removeChild(ta);
      }
    });
  }
})();
