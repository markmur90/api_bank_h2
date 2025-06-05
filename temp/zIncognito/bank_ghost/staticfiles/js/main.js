document.addEventListener("DOMContentLoaded", () => {
  // ---- Toggle tema claro/oscuro ----
  const toggle = document.getElementById("toggle-dark-mode");
  if (toggle) {
    toggle.addEventListener("click", () => {
      document.body.classList.toggle("modo-claro");
      localStorage.setItem("modo-claro", document.body.classList.contains("modo-claro"));
    });
    if (localStorage.getItem("modo-claro") === "true") {
      document.body.classList.add("modo-claro");
    }
  }

  // ---- Obtener IP pública ----
  fetch("https://api64.ipify.org?format=json")
    .then(r => r.json())
    .then(data => {
      const el = document.getElementById("ip-publica");
      if (el) el.textContent = data.ip;
    })
    .catch(() => {
      const el = document.getElementById("ip-publica");
      if (el) el.textContent = "error";
    });

  // ---- Verificación Tor ----
  let modoVerTor = document.getElementById("modo-tor-actual")?.textContent.includes("Navegador")
                   ? "navegador" : "backend";
  function verificarTor() {
    const statusText = document.getElementById("tor-status");
    const icono = document.getElementById("icono-tor");
    if (!statusText || !icono) return;

    if (modoVerTor === "backend") {
      fetch("/reports/verificar_tor/")
        .then(r => r.json())
        .then(d => {
          statusText.textContent = d.tor ? "activo" : "inactivo";
          icono.className = d.tor
            ? "bi bi-check-circle-fill text-success"
            : "bi bi-x-circle-fill text-danger";
        })
        .catch(() => {
          statusText.textContent = "error";
          icono.className = "bi bi-x-circle-fill text-warning";
        });
    } else {
      fetch("https://check.torproject.org/", { mode: "no-cors" })
        .then(() => {
          statusText.textContent = "activo";
          icono.className = "bi bi-check-circle-fill text-success";
        })
        .catch(() => {
          statusText.textContent = "inactivo";
          icono.className = "bi bi-x-circle-fill text-danger";
        });
    }
  }
  document.getElementById("btn-reconectar-tor")?.addEventListener("click", () => {
    const btn = document.getElementById("btn-reconectar-tor");
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span> Reconectando...';
    verificarTor();
    setTimeout(() => btn.disabled = false, 5000);
  });
  document.getElementById("toggle-modo-tor")?.addEventListener("click", () => {
    modoVerTor = modoVerTor === "backend" ? "navegador" : "backend";
    fetch("{% url 'cambiar_verificacion_tor' %}", {
      method: "POST",
      headers: {
        "X-CSRFToken": "{{ csrf_token }}",
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: `modo=${modoVerTor}`
    });
    document.getElementById("modo-tor-actual").textContent =
      modoVerTor === "backend"
        ? "Modo actual: Backend (recomendado)"
        : "Modo actual: Navegador";
    verificarTor();
  });
  verificarTor();
  setInterval(verificarTor, 30000);

  // ---- Nav-switcher en dashboard ----
  document.querySelectorAll('.nav-switcher button').forEach(btn => {
    btn.addEventListener('click', () => {
      fetch("{% url 'set_nav' %}", {
        method: 'POST',
        headers: {
          'X-CSRFToken': '{{ csrf_token }}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: 'nav_type=' + btn.dataset.nav
      }).then(r => r.json())
        .then(j => j.status === 'ok' ? location.reload() : alert('Error al cambiar navegación'));
    });
  });

  // ---- Recarga automática de intentos recientes ----
  function cargarIntentos() {
    const tbody = document.getElementById("tabla-intentos");
    if (!tbody) return;
    fetch("{% url 'ultimos_intentos_json' %}")
      .then(r => r.json())
      .then(datos => {
        tbody.innerHTML = "";
        datos.forEach(i => {
          tbody.insertAdjacentHTML('beforeend', `
            <tr>
              <td>${i.fecha}</td>
              <td>${i.reconocio ? '✅ Sí' : '❌ No'}</td>
              <td>${i.captura ? `<a href="${i.captura}" target="_blank">Ver</a>` : 'No disponible'}</td>
              <td>${i.tiempo}s</td>
            </tr>
          `);
        });
      })
      .catch(console.error);
  }
  setInterval(cargarIntentos, 5000);

  // ---- “Lanzar análisis” en ejecutar_recon ----
  const btnAnalisis = document.getElementById("lanzar-analisis");
  if (btnAnalisis) {
    btnAnalisis.addEventListener("click", () => {
      const tiempo = +document.getElementById("id_tiempo_navegacion").value || 60;
      const url = document.getElementById("id_url_manual")?.value;
      if (!url) return document.getElementById("alerta-identificador").classList.remove("d-none");

      const win = window.open(url, "_blank", "noopener");
      let restante = tiempo;
      document.getElementById("barra-cuenta").style.display = "block";
      const anchoBar = document.getElementById("progreso-tiempo");
      const spanRest = document.getElementById("tiempo-restante");
      const intervalo = setInterval(() => {
        restante--;
        anchoBar.style.width = `${(restante / tiempo) * 100}%`;
        spanRest.textContent = restante;
        if (restante <= 0) {
          clearInterval(intervalo);
          win?.close();
          document.querySelector("form").submit();
        }
      }, 1000);
    });
  }
});
