/* ============================================================
   Theme Injector site — vanilla JS, progressive enhancement.
   Without JS: the video still autoplays (muted) and every
   download link still works; only the guide modals are skipped.
   ============================================================ */
(function () {
  'use strict';

  var reduceMotion = !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches);

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
     Autoplay muted; under reduced motion stay paused on the
     poster and expose a play button instead. */
  var video = document.getElementById('heroVideo');
  var overlay = document.getElementById('playOverlay');

  function showOverlay() { if (overlay) overlay.hidden = false; }
  function hideOverlay() { if (overlay) overlay.hidden = true; }

  if (video) {
    video.addEventListener('playing', hideOverlay);
    video.addEventListener('pause', showOverlay);
    video.addEventListener('error', showOverlay);

    if (reduceMotion) {
      video.removeAttribute('autoplay');
      video.pause();
      showOverlay();
    } else {
      var pr = video.play();
      if (pr && pr.catch) pr.catch(showOverlay); // autoplay refused -> offer the button
    }

    if (overlay) {
      overlay.addEventListener('click', function () {
        var p = video.play();
        if (p && p.catch) p.catch(function () {});
      });
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
