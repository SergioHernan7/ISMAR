// Botones + y − de los selectores de cantidad.
// El + se desactiva al llegar al stock disponible (max) y el − al llegar al mínimo.
document.querySelectorAll('.selector-cantidad').forEach(function (selector) {
  var input = selector.querySelector('input');
  var menos = selector.querySelector('button[data-paso="-1"]');
  var mas = selector.querySelector('button[data-paso="1"]');
  var min = parseInt(input.min || '0', 10);
  var max = parseInt(input.max || '999', 10);

  function limitar() {
    var valor = parseInt(input.value, 10);
    if (isNaN(valor)) return;  // mientras escribe, deja el campo vacío
    if (valor > max) input.value = max;
    if (valor < min) input.value = min;
  }

  function actualizarBotones() {
    var valor = parseInt(input.value, 10) || 0;
    mas.disabled = valor >= max;
    menos.disabled = valor <= min;
    mas.title = mas.disabled ? 'No hay más unidades disponibles' : '';
  }

  [menos, mas].forEach(function (boton) {
    boton.addEventListener('click', function () {
      var valor = (parseInt(input.value, 10) || 0) + parseInt(boton.dataset.paso, 10);
      input.value = Math.min(Math.max(valor, min), max);
      actualizarBotones();
      input.dispatchEvent(new Event('change'));
    });
  });
  input.addEventListener('input', function () { limitar(); actualizarBotones(); });
  input.addEventListener('blur', function () {
    if (input.value === '') input.value = min;
    actualizarBotones();
  });
  actualizarBotones();
});

// En el carrito, al cambiar una cantidad se guarda sola (sin botón "Actualizar")
var temporizador;
document.querySelectorAll('input[data-autoenviar]').forEach(function (input) {
  input.addEventListener('change', function () {
    clearTimeout(temporizador);
    temporizador = setTimeout(function () {
      var form = document.getElementById(input.getAttribute('form'));
      // requestSubmit (a diferencia de submit) pasa por el manejador de abajo
      if (form.requestSubmit) form.requestSubmit(); else form.submit();
    }, 600);
  });
});
document.querySelectorAll('.sin-js').forEach(function (el) { el.classList.add('d-none'); });

// Galería del detalle de producto
var fotoGrande = document.getElementById('foto-grande');
document.querySelectorAll('.miniatura-btn').forEach(function (btn) {
  btn.addEventListener('click', function () {
    fotoGrande.src = btn.dataset.src;
    document.querySelectorAll('.miniatura-btn').forEach(function (b) { b.classList.remove('activa'); });
    btn.classList.add('activa');
  });
});

// Acciones del carrito (agregar, cambiar cantidades, quitar) sin llenar el historial:
// se envían por detrás y luego se *reemplaza* la página actual, así el botón "atrás"
// no repite la página del carrito. Sin JavaScript, los formularios funcionan igual que antes.
document.addEventListener('submit', function (e) {
  var form = e.target;
  if (form.method.toLowerCase() !== 'post' || !/\/carrito\//.test(form.getAttribute('action') || '')) return;
  e.preventDefault();
  if (form.dataset.enviando) return;  // evita doble clic
  form.dataset.enviando = '1';
  fetch(form.action, { method: 'POST', body: new FormData(form), headers: { 'X-Carrito': '1' } })
    .then(function (r) { if (!r.ok) throw r; return r.json(); })
    .then(function (datos) { location.replace(datos.destino); })
    .catch(function () { delete form.dataset.enviando; form.submit(); });  // si algo falla, envío normal
});

// Si el navegador muestra una página guardada al usar "atrás"/"adelante", se recarga
// para que el contador del carrito y las cantidades estén al día
window.addEventListener('pageshow', function (e) {
  if (e.persisted) location.reload();
});
