// Panel de administrador: precio final con descuento mientras se escribe.
// Cada <input data-descuento> busca su precio en data-precio o en el campo name="precio" del formulario,
// y escribe el resultado en el [data-precio-final] más cercano.
function formatoPesos(n) {
  return '$' + Math.round(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
}

function precioConDescuento(precio, descuento) {
  return Math.round(precio * (100 - descuento) / 100);  // igual que ROUND(...) del servidor
}

function actualizarPrecioFinal(input) {
  var fila = input.closest('[data-fila-oferta]') || input.form || document;
  var salida = fila.querySelector('[data-precio-final]');
  if (!salida) return;
  var precio = parseFloat(input.dataset.precio || ((fila.querySelector('[name="precio"]') || {}).value || '').replace(',', '.'));
  var descuento = parseInt(input.value, 10) || 0;
  var max = parseInt(input.max || '90', 10);
  if (isNaN(precio) || descuento <= 0) { salida.textContent = input.dataset.precio ? '—' : ''; return; }
  if (descuento > max) { salida.textContent = 'Máximo ' + max + ' %'; return; }
  salida.textContent = (input.dataset.precio ? '' : 'Precio final: ') + formatoPesos(precioConDescuento(precio, descuento));
}

document.querySelectorAll('input[data-descuento]').forEach(function (input) {
  input.addEventListener('input', function () { actualizarPrecioFinal(input); });
  actualizarPrecioFinal(input);
  var precio = input.form && input.form.querySelector('[name="precio"]');
  if (precio && !input.dataset.precio) precio.addEventListener('input', function () { actualizarPrecioFinal(input); });
});

// Página Ofertas del panel: filtros, marcar productos, descuento a varios y cambios sin guardar
(function () {
  var form = document.getElementById('form-ofertas');
  if (!form) return;
  var filas = Array.prototype.slice.call(form.querySelectorAll('[data-fila-oferta]'));
  var texto = form.querySelector('[data-filtro-texto]');
  var categoria = form.querySelector('[data-filtro-categoria]');
  var soloOferta = form.querySelector('[data-filtro-oferta]');
  var marcarTodos = form.querySelector('[data-marcar-todos]');
  var barraGuardar = form.querySelector('[data-barra-guardar]');

  function campo(fila) { return fila.querySelector('[data-descuento]'); }
  function visibles() { return filas.filter(function (f) { return !f.hidden; }); }
  function marcadas() { return filas.filter(function (f) { return f.querySelector('[data-marcar]').checked; }); }

  function filtrar() {
    var t = texto.value.trim().toLowerCase();
    filas.forEach(function (f) {
      f.hidden = (t && f.dataset.texto.indexOf(t) === -1) ||
                 (categoria.value && f.dataset.categoria !== categoria.value) ||
                 (soloOferta.checked && !(parseInt(campo(f).value, 10) > 0));
    });
    form.querySelector('[data-sin-resultados]').classList.toggle('d-none', visibles().length > 0);
    actualizarMarcas();
  }

  function actualizarMarcas() {
    var n = marcadas().length, vis = visibles();
    form.querySelector('[data-cuenta-marcados]').textContent = n;
    form.querySelector('[data-barra-masiva]').classList.toggle('activa', n > 0);
    marcarTodos.checked = vis.length > 0 && vis.every(function (f) { return f.querySelector('[data-marcar]').checked; });
  }

  function actualizarCambios() {
    var n = 0;
    filas.forEach(function (f) {
      var c = campo(f), cambiado = String(parseInt(c.value, 10) || 0) !== c.dataset.original;
      f.classList.toggle('fila-cambiada', cambiado);
      f.classList.toggle('fila-en-oferta', (parseInt(c.value, 10) || 0) > 0);
      if (cambiado) n++;
    });
    form.querySelector('[data-cuenta-cambios]').textContent = n;
    barraGuardar.hidden = n === 0;
  }

  function ponerDescuento(valor) {
    marcadas().forEach(function (f) {
      var c = campo(f); c.value = valor; actualizarPrecioFinal(c);
    });
    actualizarCambios();
  }

  [texto, categoria, soloOferta].forEach(function (el) { el.addEventListener('input', filtrar); });
  marcarTodos.addEventListener('change', function () {
    visibles().forEach(function (f) { f.querySelector('[data-marcar]').checked = marcarTodos.checked; });
    actualizarMarcas();
  });
  filas.forEach(function (f) {
    f.querySelector('[data-marcar]').addEventListener('change', actualizarMarcas);
    campo(f).addEventListener('input', actualizarCambios);
  });
  form.querySelector('[data-aplicar-masivo]').addEventListener('click', function () {
    var entrada = form.querySelector('[data-descuento-masivo]');
    var valor = parseInt(entrada.value, 10);
    var max = parseInt(entrada.max, 10);
    if (!(valor >= 1 && valor <= max)) { entrada.focus(); entrada.classList.add('is-invalid'); return; }
    entrada.classList.remove('is-invalid');
    ponerDescuento(valor);
  });
  form.querySelector('[data-quitar-masivo]').addEventListener('click', function () { ponerDescuento(0); });
  form.querySelector('[data-deshacer]').addEventListener('click', function () {
    filas.forEach(function (f) { var c = campo(f); c.value = c.dataset.original; actualizarPrecioFinal(c); });
    actualizarCambios();
  });
  // Avisa si sale de la página con cambios sin guardar
  var enviando = false;
  form.addEventListener('submit', function () { enviando = true; });
  window.addEventListener('beforeunload', function (e) {
    if (!enviando && !barraGuardar.hidden) { e.preventDefault(); e.returnValue = ''; }
  });
  actualizarMarcas();
})();

// Lista de pedidos: marcar varios y cambiarles el estado de una vez
(function () {
  var form = document.getElementById('form-pedidos');
  if (!form) return;
  var casillas = Array.prototype.slice.call(form.querySelectorAll('[data-marcar]'));
  var marcarTodos = form.querySelector('[data-marcar-todos]');

  function actualizar() {
    var n = casillas.filter(function (c) { return c.checked; }).length;
    form.querySelector('[data-cuenta-marcados]').textContent = n;
    form.querySelector('[data-barra-masiva]').classList.toggle('activa', n > 0);
    form.querySelectorAll('[data-accion-masiva]').forEach(function (b) { b.disabled = n === 0; });
    marcarTodos.checked = casillas.length > 0 && n === casillas.length;
  }

  marcarTodos.addEventListener('change', function () {
    casillas.forEach(function (c) { c.checked = marcarTodos.checked; });
    actualizar();
  });
  casillas.forEach(function (c) { c.addEventListener('change', actualizar); });
  actualizar();
})();
