// Botones + y − de los selectores de cantidad
document.querySelectorAll('.selector-cantidad').forEach(function (selector) {
  var input = selector.querySelector('input');
  selector.querySelectorAll('button[data-paso]').forEach(function (boton) {
    boton.addEventListener('click', function () {
      var min = parseInt(input.min || '0', 10);
      var max = parseInt(input.max || '999', 10);
      var valor = (parseInt(input.value, 10) || 0) + parseInt(boton.dataset.paso, 10);
      input.value = Math.min(Math.max(valor, min), max);
      input.dispatchEvent(new Event('change'));
    });
  });
});

// En el carrito, al cambiar una cantidad se guarda sola (sin botón "Actualizar")
var temporizador;
document.querySelectorAll('input[data-autoenviar]').forEach(function (input) {
  input.addEventListener('change', function () {
    clearTimeout(temporizador);
    temporizador = setTimeout(function () { document.getElementById(input.getAttribute('form')).submit(); }, 600);
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
