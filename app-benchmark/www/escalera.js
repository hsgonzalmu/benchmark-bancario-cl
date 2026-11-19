// Cursor sincronizado de las líneas de 12 meses de la escalera. Cada .spark-wrap trae en data-x y data-y
// la posición de cada mes (en % de su ancho y alto) y en data-t su texto ("oct 2025 · 21,40 %"). Al
// mover el puntero sobre una línea, todas las líneas de la escalera marcan el mismo mes; la señalada
// muestra además su etiqueta. La escalera se vuelve a dibujar desde el server, por eso los eventos se
// escuchan en el documento.
(function () {
  var activa = null;

  function datos(w) {
    if (!w._datos) {
      w._datos = {
        x: w.dataset.x.split(","), y: w.dataset.y.split(","), t: w.dataset.t.split("|"),
        ultimo: Number(w.dataset.ultimo), punto: w.querySelector(".spark-punto")
      };
    }
    return w._datos;
  }

  function capa(w, clase) {
    var el = w.querySelector("." + clase);
    if (!el) {
      el = document.createElement("span");
      el.className = clase;
      w.appendChild(el);
    }
    return el;
  }

  function marcar(w, i, conEtiqueta) {
    var d = datos(w), cursor = capa(w, "spark-cursor"), tip = capa(w, "spark-tip");
    cursor.style.left = d.x[i] + "%";
    cursor.hidden = false;
    if (d.y[i] === "") {
      d.punto.hidden = true;
    } else {
      d.punto.hidden = false;
      d.punto.style.left = d.x[i] + "%";
      d.punto.style.top = d.y[i] + "%";
    }
    tip.hidden = !conEtiqueta;
    if (conEtiqueta) {
      tip.textContent = d.t[i];
      tip.classList.toggle("al-final", Number(d.x[i]) > 60);
      tip.classList.toggle("al-inicio", Number(d.x[i]) < 30);
      tip.style.left = d.x[i] + "%";
    }
  }

  function reposo(w) {
    var d = datos(w);
    w.querySelectorAll(".spark-cursor, .spark-tip").forEach(function (el) { el.hidden = true; });
    d.punto.hidden = false;
    d.punto.style.left = d.x[d.ultimo] + "%";
    d.punto.style.top = d.y[d.ultimo] + "%";
  }

  function hermanas(w) {
    var escalera = w.closest(".escalera");
    return escalera ? escalera.querySelectorAll(".spark-wrap[data-x]") : [w];
  }

  function mover(ev) {
    var w = ev.target.closest && ev.target.closest(".spark-wrap[data-x]");
    if (!w) {
      if (activa) {
        if (document.contains(activa)) hermanas(activa).forEach(reposo);
        activa = null;
      }
      return;
    }
    var d = datos(w), r = w.getBoundingClientRect();
    var fx = 100 * (ev.clientX - r.left) / r.width, i = 0, mejor = Infinity;
    d.x.forEach(function (x, k) {
      var dist = Math.abs(Number(x) - fx);
      if (dist < mejor) { mejor = dist; i = k; }
    });
    if (activa && activa !== w && document.contains(activa)) hermanas(activa).forEach(reposo);
    activa = w;
    hermanas(w).forEach(function (h) { marcar(h, i, h === w); });
  }

  document.addEventListener("pointermove", mover);
  document.addEventListener("pointerdown", mover);
  document.addEventListener("pointerleave", function () {
    if (activa && document.contains(activa)) hermanas(activa).forEach(reposo);
    activa = null;
  });
})();

// Deja un banco como analizado por el mismo camino que el filtro Banco. La usan la escalera, la tira de
// Puesto y el gráfico y la tabla de ranking (onClick en R/graficos.R).
window.seleccionarBanco = function (cod) {
  var sel = document.getElementById("banco");
  if (cod && sel && sel.selectize) sel.selectize.setValue(cod);
};

// Escalera con todo el ranking: al dibujarse, la lista se desplaza para mostrar a los competidores (con
// un asomo del banco de arriba); clic o Enter en un banco que no sea el analizado lo selecciona en el
// filtro Banco. Lo mismo con los puntos de la tira de la ficha de Puesto.
(function () {
  var quieto = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // Desliza la lista hasta destino() en 0,7 s con aceleración y frenado suaves (misma curva cúbica que las
  // transiciones del ranking). El scroll "smooth" del navegador es más corto y no se puede ajustar. El
  // destino se recalcula en cada cuadro porque las filas cambian de alto durante su propia transición.
  function deslizar(lista, destino) {
    var desde = lista.scrollTop, inicio = null, dur = 700;
    if (lista._anim) cancelAnimationFrame(lista._anim);
    function paso(t) {
      if (inicio === null) inicio = t;
      var p = Math.min(1, (t - inicio) / dur);
      var e = p < 0.5 ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2;
      lista.scrollTop = desde + (destino() - desde) * e;
      lista._anim = p < 1 ? requestAnimationFrame(paso) : null;
    }
    lista._anim = requestAnimationFrame(paso);
  }

  // suave: desliza la lista (al cambiar de banco); si no, salta (al dibujarse).
  function mostrarCompetidores(suave) {
    document.querySelectorAll(".escalera-lista").forEach(function (lista) {
      var primero = lista.querySelector(".peldano.competidor");
      if (!primero) return;
      var arriba = function () {
        var previo = primero.previousElementSibling;
        return Math.max(0, primero.offsetTop - (previo ? previo.offsetHeight * 0.6 : 0));
      };
      if (suave && !quieto) deslizar(lista, arriba);
      else lista.scrollTop = arriba();
    });
  }

  $(document).on("shiny:value", function (ev) {
    if (ev.name === "escalera") setTimeout(function () { mostrarCompetidores(false); }, 60);
  });

  // Cambio de banco sin redibujar (mensaje "escalera_foco", R/componentes.R): clases de las filas, brechas
  // entre los nuevos competidores y desplazamiento suave. Si la lista no es la del mensaje (por ejemplo,
  // porque también cambió la cuenta y viene un redibujo), no hace nada.
  function actualizarEscalera(msg) {
    var lista = document.querySelector(".escalera-lista");
    if (!lista) return;
    var filas = Array.prototype.slice.call(lista.querySelectorAll(".peldano[data-fila]"));
    var orden = filas.map(function (f) { return f.dataset.fila; });
    if (orden.join() !== msg.filas.join()) return;
    lista.querySelectorAll(".brecha").forEach(function (b) { b.remove(); });
    filas.forEach(function (f) {
      var cod = f.dataset.fila, competidor = msg.competidores.indexOf(cod) >= 0, foco = cod === msg.foco;
      f.className = "peldano " + (competidor ? "competidor" + (foco ? " es-foco" : "") : "fuera");
      if (foco) {
        ["data-cod", "tabindex", "role", "title"].forEach(function (a) { f.removeAttribute(a); });
      } else {
        var nombre = f.querySelector(".nombre-texto");
        f.setAttribute("data-cod", cod);
        f.setAttribute("tabindex", "0");
        f.setAttribute("role", "button");
        f.setAttribute("title", "Analizar " + (nombre ? nombre.textContent : ""));
      }
    });
    msg.competidores.slice(0, -1).forEach(function (cod, i) {
      var fila = lista.querySelector('.peldano[data-fila="' + cod + '"]');
      if (fila && msg.brechas[i]) fila.insertAdjacentHTML("afterend", msg.brechas[i]);
    });
    mostrarCompetidores(true);
  }
  $(function () { Shiny.addCustomMessageHandler("escalera_foco", actualizarEscalera); });

  function seleccionar(ev) {
    var fila = ev.target.closest && ev.target.closest(".peldano[data-cod], .tira-clic[data-cod]");
    if (!fila) return;
    if (ev.type === "keydown" && ev.key !== "Enter" && ev.key !== " ") return;
    ev.preventDefault();
    window.seleccionarBanco(fila.dataset.cod);
  }

  document.addEventListener("click", seleccionar);
  document.addEventListener("keydown", seleccionar);
})();

// Tira de la ficha de Puesto: al pasar el puntero por un punto, etiqueta con puesto y nombre del banco.
(function () {
  function tip(tira) {
    var el = tira.querySelector(".tira-tip");
    if (!el) {
      el = document.createElement("span");
      el.className = "tira-tip";
      el.hidden = true;
      tira.appendChild(el);
    }
    return el;
  }

  document.addEventListener("pointerover", function (ev) {
    var punto = ev.target.closest && ev.target.closest(".tira-hit");
    if (!punto) return;
    var tira = punto.closest(".ficha-tira");
    if (!tira) return;
    var r = punto.getBoundingClientRect(), base = tira.getBoundingClientRect(), el = tip(tira);
    var x = 100 * (r.left + r.width / 2 - base.left) / base.width;
    el.textContent = punto.dataset.nombre;
    el.style.left = x + "%";
    el.style.top = (r.top - base.top) + "px";
    el.classList.toggle("al-final", x > 75);
    el.classList.toggle("al-inicio", x < 25);
    el.hidden = false;
  });

  document.addEventListener("pointerout", function (ev) {
    var punto = ev.target.closest && ev.target.closest(".tira-hit");
    if (!punto) return;
    var tira = punto.closest(".ficha-tira");
    var el = tira && tira.querySelector(".tira-tip");
    if (el) el.hidden = true;
  });
})();

// Indicadores sin redibujar (mensaje "indicadores_foco", R/componentes.R): las cifras cuentan hasta el nuevo
// valor, los textos armados en R se reemplazan con un fundido y la tira de Puesto mueve su punto, la franja
// de la escalera y el anillo de hace 12 meses. Misma curva cúbica y 0,7 s que el deslizamiento de la
// escalera; sin movimiento si el sistema pide reducirlo.
(function () {
  var quieto = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var DUR = 700;
  function curva(p) { return p < 0.5 ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2; }

  // Llama a cada(e) con e de 0 a 1 durante DUR ms (o una vez con 1 si no hay movimiento).
  function animar(el, cada, alTerminar) {
    if (el._anim) cancelAnimationFrame(el._anim);
    if (quieto) { cada(1); if (alTerminar) alTerminar(); return; }
    var inicio = null;
    function paso(t) {
      if (inicio === null) inicio = t;
      var p = Math.min(1, (t - inicio) / DUR);
      cada(curva(p));
      if (p < 1) el._anim = requestAnimationFrame(paso);
      else { el._anim = null; if (alTerminar) alTerminar(); }
    }
    el._anim = requestAnimationFrame(paso);
  }

  var formatos = {
    porcentaje: function (v) { return v.toFixed(1).replace(".", ",") + " %"; },
    porcentaje2: function (v) { return v.toFixed(2).replace(".", ",") + " %"; },
    puesto: function (v) { return Math.round(v) + "°"; }
  };

  function contar(el, hasta) {
    if (!el) return;
    var desde = Number(el.dataset.valor), f = formatos[el.dataset.formato];
    el.dataset.valor = hasta;
    animar(el, function (e) { el.textContent = f(desde + (hasta - desde) * e); });
  }

  function reemplazar(el, html) {
    if (!el) return;
    if (quieto) { el.innerHTML = html; return; }
    el.classList.add("cambiando");
    setTimeout(function () { el.innerHTML = html; el.classList.remove("cambiando"); }, 200);
  }

  function num(el, atributo) { return Number(el.getAttribute(atributo)); }

  function moverTira(svg, s) {
    if (!svg || Number(svg.dataset.n) !== s.n) return;
    var x = function (p) { return 12 + (p - 1) * 296 / Math.max(1, s.n - 1); };
    var banda = svg.querySelector(".tira-banda"), actual = svg.querySelector(".tira-actual");
    var anillo = svg.querySelector(".tira-antes"), flecha = svg.querySelector(".tira-flecha");
    var punta = svg.querySelector(".tira-punta");
    var b0 = { x: num(banda, "x"), w: num(banda, "width") };
    var b1 = { x: x(s.desde) - 10, w: x(s.hasta) - x(s.desde) + 20 };
    var a0 = num(actual, "cx"), a1 = x(s.foco);
    var r0 = num(anillo, "cx"), r1 = x(s.antes === null ? s.foco : s.antes);
    flecha.style.opacity = 0;
    animar(svg, function (e) {
      banda.setAttribute("x", b0.x + (b1.x - b0.x) * e);
      banda.setAttribute("width", b0.w + (b1.w - b0.w) * e);
      actual.setAttribute("cx", a0 + (a1 - a0) * e);
      anillo.setAttribute("cx", r0 + (r1 - r0) * e);
    }, function () {
      if (s.antes !== null) {
        flecha.setAttribute("d", "M " + r1 + " 11 Q " + (r1 + a1) / 2 + " -2 " + a1 + " 11");
        flecha.style.opacity = 1;
      }
    });
    actual.style.fill = s.color;
    anillo.style.stroke = s.color;
    anillo.style.opacity = s.antes === null ? 0 : 1;
    flecha.style.stroke = s.color;
    if (punta) punta.style.fill = s.color;
    svg.querySelectorAll(".tira-dot").forEach(function (d) {
      var c = s.colores[Number(d.dataset.pos) - 1];
      d.style.fill = c || "#C3CBD5";
      d.setAttribute("r", c ? 4.6 : 2.6);
    });
    svg.querySelectorAll(".tira-num").forEach(function (t) {
      var p = Number(t.dataset.pos);
      t.style.opacity = s.marcas.indexOf(p) >= 0 ? 1 : 0;
      t.classList.toggle("es-foco", p === s.foco);
    });
    svg.querySelectorAll(".tira-hit").forEach(function (h) {
      var foco = Number(h.dataset.pos) === s.foco;
      h.classList.toggle("tira-clic", !foco);
      if (foco) h.removeAttribute("data-cod"); else h.setAttribute("data-cod", h.dataset.banco);
      h.setAttribute("data-nombre", h.dataset.base + (foco ? " · analizado" : ""));
    });
  }

  function actualizarIndicadores(msg) {
    var part = document.querySelector(".indicador-participacion");
    var puesto = document.querySelector(".ficha-puesto");
    if (part) {
      contar(part.querySelector(".cifra-animada"), msg.participacion.valor);
      reemplazar(part.querySelector(".indicador-etiqueta"), msg.participacion.etiqueta);
      reemplazar(part.querySelector(".indicador-lineas"), msg.participacion.lineas);
    }
    if (puesto) {
      contar(puesto.querySelector(".cifra-animada"), msg.puesto.valor);
      reemplazar(puesto.querySelector(".indicador-etiqueta"), msg.puesto.etiqueta);
      reemplazar(puesto.querySelector(".indicador-chips"), msg.puesto.chips);
      moverTira(puesto.querySelector(".tira-puestos"), msg.puesto.tira);
    }
  }
  $(function () { Shiny.addCustomMessageHandler("indicadores_foco", actualizarIndicadores); });
})();
