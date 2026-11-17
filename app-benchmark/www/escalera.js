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
