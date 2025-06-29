addEventListener('DOMContentLoaded', (e) => {
  d = document
  const f = d.getElementById('file-picker')
  /**
   *  Reset Button
   *  */
  const r = d.getElementById('file-reset')
  if (!f.value) r.disabled = true
  // Update reset button on file selection
  f.addEventListener('change', function () {
    r.disabled = !f.files.length
  })
  // Re-disable reset when form is reset
  f.form.addEventListener('reset', function () {
    r.disabled = true
  })
  const c = d.getElementById('openChrome')
  const protocol = window.location.protocol.replace(':', '')
  c.href = `intent://${window.location.host}#Intent;scheme=${protocol};package=com.android.chrome;end`
})
