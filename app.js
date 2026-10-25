// LED Photo Wall · shared helpers
(function () {
  const C = window.PHOTOWALL_CONFIG || {};
  const PW = (window.PW = {});

  PW.configured = !!(C.SUPABASE_URL && C.SUPABASE_ANON_KEY &&
    !/YOUR-/.test(C.SUPABASE_URL) && !/YOUR-/.test(C.SUPABASE_ANON_KEY));

  PW.client = function (opts) {
    if (!PW._client) {
      PW._client = window.supabase.createClient(C.SUPABASE_URL, C.SUPABASE_ANON_KEY, opts || {});
    }
    return PW._client;
  };

  PW.param = (k, d) => {
    const v = new URLSearchParams(location.search).get(k);
    return v === null || v === '' ? d : v;
  };

  PW.publicUrl = (path) =>
    `${String(C.SUPABASE_URL).replace(/\/$/, '')}/storage/v1/object/public/photos/${path}`;

  // Folder of the current page, e.g. https://led-solutions.github.io/led-photo-wall/
  PW.baseUrl = () => location.origin + location.pathname.replace(/[^/]*$/, '');
  PW.guestUrl = (slug) => `${PW.baseUrl()}?e=${encodeURIComponent(slug)}`;
  PW.screenUrl = (slug, extra) =>
    `${PW.baseUrl()}screen.html?e=${encodeURIComponent(slug)}${extra || ''}`;

  PW.esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

  PW.uuid = () => (crypto.randomUUID ? crypto.randomUUID()
    : 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
        const r = (Math.random() * 16) | 0;
        return (c === 'x' ? r : (r & 3) | 8).toString(16);
      }));

  PW.slugify = (s) => String(s || '')
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .toLowerCase().replace(/&/g, '-').replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '').slice(0, 40);

  // Draws a QR code into `el` (needs qrcode.min.js). Returns the element.
  PW.qr = (el, text, size, dark, light) => {
    el.innerHTML = '';
    new window.QRCode(el, {
      text, width: size, height: size,
      colorDark: dark || '#000000', colorLight: light || '#ffffff',
      correctLevel: window.QRCode.CorrectLevel.M
    });
    return el;
  };

  PW.setupMessage = `
    <div style="max-width:560px;margin:10vh auto;padding:24px;font:16px/1.5 system-ui,sans-serif;color:#e8e6e1">
      <h2 style="margin:0 0 8px">Almost ready</h2>
      <p>This photo wall isn't connected to its Supabase project yet.
      Put the Project URL and anon key in <code>config.js</code> (see the README, step 3).</p>
      <p style="opacity:.7">To preview the screen without Supabase, open <code>screen.html?demo=1</code>.</p>
    </div>`;
})();
