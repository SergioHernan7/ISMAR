// Buscador con sugerencias (tienda y panel de administrador).
// Se activa en cualquier <form data-sugerencias="URL"> con un <input name="q">: mientras se
// escribe pide a URL los productos que coinciden (JSON: total y productos con nombre, url,
// imagen, detalle, precio, precio_anterior y avisos) y los muestra en una lista bajo el campo.
document.querySelectorAll('form[data-sugerencias]').forEach(function (form) {
  var input = form.querySelector('input[name="q"]');
  var contenedor = input.parentElement;
  contenedor.classList.add('con-sugerencias');
  var lista = document.createElement('div');
  lista.className = 'sugerencias d-none';
  lista.setAttribute('role', 'listbox');
  contenedor.appendChild(lista);

  var espera, peticion, activo = -1;

  function escapar(texto) {
    var div = document.createElement('div');
    div.textContent = texto;
    return div.innerHTML;
  }

  // Quita tildes para comparar "iluminacion" con "Iluminación"
  function normalizar(texto) {
    return texto.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  }

  // Pone en negrita las palabras escritas dentro del nombre del producto
  function resaltar(nombre, q) {
    var base = normalizar(nombre);
    var marcas = new Array(nombre.length).fill(false);
    q.split(/\s+/).filter(Boolean).forEach(function (palabra) {
      var p = normalizar(palabra), i = base.indexOf(p);
      while (p && i !== -1) {
        for (var k = i; k < i + p.length; k++) marcas[k] = true;
        i = base.indexOf(p, i + p.length);
      }
    });
    var html = '', abierto = false;
    for (var j = 0; j < nombre.length; j++) {
      if (marcas[j] && !abierto) { html += '<mark>'; abierto = true; }
      if (!marcas[j] && abierto) { html += '</mark>'; abierto = false; }
      html += escapar(nombre[j]);
    }
    return html + (abierto ? '</mark>' : '');
  }

  // Los demás campos del formulario (p. ej. la categoría elegida en el panel) también se envían
  function parametros(q) {
    var datos = new URLSearchParams(new FormData(form));
    datos.set('q', q);
    return datos.toString();
  }

  function cerrar() {
    lista.classList.add('d-none');
    activo = -1;
  }

  function opciones() {
    return lista.querySelectorAll('.sugerencia');
  }

  function marcar(indice) {
    var items = opciones();
    if (!items.length) return;
    activo = (indice + items.length) % items.length;
    items.forEach(function (el, i) { el.classList.toggle('activa', i === activo); });
    items[activo].scrollIntoView({ block: 'nearest' });
  }

  function mostrar(datos, q) {
    var urlTodos = form.getAttribute('action') ? form.action.split('?')[0] : location.pathname;
    urlTodos += '?' + parametros(q);
    if (!datos.productos.length) {
      lista.innerHTML = '<div class="sugerencias-vacio"><i class="bi bi-search"></i> No encontramos productos para "' +
        escapar(q) + '"</div>';
    } else {
      lista.innerHTML = datos.productos.map(function (p) {
        var foto = p.imagen
          ? '<img src="' + escapar(p.imagen) + '" alt="" loading="lazy">'
          : '<span class="sin-foto"><i class="bi bi-lightning-charge"></i></span>';
        var avisos = (p.avisos || []).map(function (a) {
          return ' <span class="aviso aviso-' + escapar(a.tipo) + '">' + escapar(a.texto) + '</span>';
        }).join('');
        var precio = '<span class="precio">' + escapar(p.precio) + '</span>' +
          (p.precio_anterior ? ' <span class="precio-anterior">' + escapar(p.precio_anterior) + '</span>' : '');
        return '<a class="sugerencia" role="option" href="' + escapar(p.url) + '">' +
          '<span class="foto">' + foto + '</span>' +
          '<span class="info"><span class="nombre">' + resaltar(p.nombre, q) + '</span>' +
          '<span class="detalle">' + escapar(p.detalle || '') + avisos + '</span></span>' +
          '<span class="precios-sugerencia">' + precio + '</span></a>';
      }).join('') +
        '<a class="sugerencia ver-todos" role="option" href="' + escapar(urlTodos) + '">Ver ' +
        (datos.total > 1 ? 'los ' + datos.total + ' resultados' : 'el resultado') + ' <i class="bi bi-arrow-right"></i></a>';
    }
    activo = -1;
    lista.classList.remove('d-none');
  }

  function buscar() {
    var q = input.value.trim();
    if (q.length < 2) { cerrar(); return; }
    if (peticion) peticion.abort();
    peticion = new AbortController();
    fetch(form.dataset.sugerencias + '?' + parametros(q), { signal: peticion.signal })
      .then(function (r) { return r.json(); })
      .then(function (datos) {
        // si el usuario siguió escribiendo, esta respuesta ya no sirve
        if (input.value.trim() === q) mostrar(datos, q);
      })
      .catch(function () {});
  }

  input.setAttribute('autocomplete', 'off');
  input.addEventListener('input', function () {
    clearTimeout(espera);
    espera = setTimeout(buscar, 200);
  });

  input.addEventListener('focus', function () {
    if (input.value.trim().length >= 2 && lista.innerHTML) lista.classList.remove('d-none');
  });

  input.addEventListener('keydown', function (e) {
    if (lista.classList.contains('d-none')) return;
    if (e.key === 'ArrowDown') { e.preventDefault(); marcar(activo + 1); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); marcar(activo - 1); }
    else if (e.key === 'Escape') { cerrar(); }
    else if (e.key === 'Enter' && activo >= 0) { e.preventDefault(); opciones()[activo].click(); }
  });

  document.addEventListener('click', function (e) {
    if (!contenedor.contains(e.target)) cerrar();
  });
});
