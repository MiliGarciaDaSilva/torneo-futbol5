// Planilla de un partido: quién jugó, los goles y las tarjetas. La usan el planillero y el admin.
// Se dibuja como un pizarrón con marco de madera.
// Los datos vienen de GET /partidos/{id}/planilla; cada cambio se manda a su ruta y se vuelve a pedir la planilla.
// Las reglas (partido jugado, jugador del plantel, suspendidos, 48 h) las controla la base: si rechaza algo,
// el mensaje del trigger aparece arriba o debajo del formulario.
import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { api } from '../api.js'
import { useAuth } from '../auth.jsx'
import Camiseta from '../components/Camiseta.jsx'
import Formulario from '../components/Formulario.jsx'
import { useDatos } from '../useDatos.js'

export default function Planilla() {
  const { id } = useParams()
  const { usuario } = useAuth()
  const { datos: planilla, error: errorCarga, recargar } = useDatos(`/partidos/${id}/planilla`, null)
  const [error, setError] = useState('')

  if (errorCarga) return <p className="error">{errorCarga}</p>
  if (!planilla) return <p>Cargando…</p>

  const { partido, equipos, goles, tarjetas, se_puede_editar: seEdita } = planilla
  const base = `/partidos/${id}`
  const enPlanilla = equipos.flatMap((e) => e.jugadores.filter((j) => j.en_planilla).map((j) => ({ ...j, equipo: e.nombre })))
  const opcionesJugador = enPlanilla.map((j) => ({ valor: j.ci, texto: `${j.nombre} ${j.apellido} (${j.equipo})` }))
  const nombreEquipo = (idEquipo) => equipos.find((e) => e.id_equipo === idEquipo)?.nombre

  // El gol cuenta para el equipo del que lo hizo; si es en contra, para el rival
  const golesDe = (idEquipo) => goles.filter((g) => (g.id_equipo === idEquipo) !== g.autogol).length

  // Ejecuta un cambio y vuelve a pedir la planilla; si la base lo rechaza, muestra el mensaje
  async function cambiar(pedido) {
    setError('')
    try {
      await pedido()
      recargar()
    } catch (err) {
      setError(err.message)
    }
  }

  function alternarJugador(jugador) {
    cambiar(() =>
      jugador.en_planilla
        ? api(`${base}/planilla/${jugador.ci}`, { method: 'DELETE' })
        : api(`${base}/planilla`, { method: 'POST', body: { ci_jugador: jugador.ci } }),
    )
  }

  // Los formularios muestran ellos mismos el error, por eso acá no se atrapa
  async function agregar(ruta, valores) {
    await api(`${base}/${ruta}`, { method: 'POST', body: valores })
    recargar()
  }

  const camposGol = [
    { nombre: 'ci_jugador', etiqueta: 'Jugador', tipo: 'select', requerido: true, opciones: opcionesJugador },
    { nombre: 'minuto', etiqueta: 'Minuto', tipo: 'number', requerido: true, min: 1, max: 60 },
    { nombre: 'autogol', etiqueta: 'En contra', tipo: 'checkbox' },
  ]
  const camposTarjeta = [
    { nombre: 'ci_jugador', etiqueta: 'Jugador', tipo: 'select', requerido: true, opciones: opcionesJugador },
    { nombre: 'minuto', etiqueta: 'Minuto', tipo: 'number', requerido: true, min: 1, max: 60 },
    {
      nombre: 'color', etiqueta: 'Color', tipo: 'select', requerido: true,
      opciones: [{ valor: 'amarilla', texto: 'Amarilla' }, { valor: 'roja', texto: 'Roja' }],
    },
  ]

  return (
    <>
      <p>
        <Link to="/partidos">← Partidos</Link>
      </p>

      <div className="pizarra">
        <div className="pizarra-cabecera">
          <span>Torneo Interfacultades de Fútbol 5</span>
          <span>Planilla N.º {partido.id_partido}</span>
        </div>

        <dl className="pizarra-datos">
          <div>
            <dt>Fecha</dt>
            <dd>{partido.numero_fecha}</dd>
          </div>
          <div>
            <dt>Día</dt>
            <dd>{partido.dia}</dd>
          </div>
          <div>
            <dt>Hora</dt>
            <dd>
              {partido.hora_inicio} a {partido.hora_fin}
            </dd>
          </div>
          <div>
            <dt>Cancha</dt>
            <dd>
              {partido.nombre_cancha}, {partido.complejo}
            </dd>
          </div>
        </dl>

        <div className="marcador">
          <span className="equipo">
            <Camiseta idEquipo={partido.id_equipo_local} tam={40} />
            {partido.equipo_local}
          </span>
          <span className="goles">
            {golesDe(partido.id_equipo_local)} – {golesDe(partido.id_equipo_visitante)}
          </span>
          <span className="equipo visitante">
            {partido.equipo_visitante}
            <Camiseta idEquipo={partido.id_equipo_visitante} tam={40} />
          </span>
        </div>

        <div className="sellos">
          <span className={`sello ${partido.estado === 'jugado' ? 'tinta' : ''}`}>{partido.estado}</span>
          {partido.estado === 'jugado' && !seEdita && <span className="sello">Cerrada</span>}
        </div>
        {partido.estado !== 'jugado' && (
          <p className="aviso">La planilla se carga cuando el partido está marcado como jugado.</p>
        )}
        {partido.estado === 'jugado' && !seEdita && (
          <p className="aviso">Pasaron más de 48 horas desde que terminó el turno, ya no se puede cambiar.</p>
        )}
        {error && <p className="error">{error}</p>}

        <h3>Quiénes jugaron</h3>
        <div className="dos-columnas">
          {equipos.map((equipo) => (
            <div className="plantel" key={equipo.id_equipo}>
              <h4>
                <Camiseta idEquipo={equipo.id_equipo} tam={22} />
                {equipo.nombre}
              </h4>
              {equipo.jugadores.map((j) => (
                <label key={j.ci}>
                  <input
                    type="checkbox"
                    checked={j.en_planilla}
                    disabled={!seEdita || j.suspendido}
                    onChange={() => alternarJugador(j)}
                  />
                  <span className="camiseta num">{j.numero_camiseta}</span>
                  <span>
                    {j.nombre} {j.apellido}
                    {j.es_capitan && ' (c)'}
                  </span>
                  {j.suspendido && <span className="sello chico">suspendido</span>}
                </label>
              ))}
            </div>
          ))}
        </div>

        <h3>Goles</h3>
        {enPlanilla.length === 0 ? (
          <p>Marcá primero quiénes jugaron.</p>
        ) : (
          <fieldset disabled={!seEdita}>
            <Formulario campos={camposGol} onGuardar={(v) => agregar('goles', v)} textoAlta="Anotar gol" />
          </fieldset>
        )}
        <ul className="lista-hechos">
          {goles.map((g) => (
            <li key={g.id_gol}>
              <span className="minuto num">{g.minuto}'</span>
              <span>
                {g.nombre} {g.apellido}
                {g.autogol && ' (en contra)'}
              </span>
              <small>{nombreEquipo(g.id_equipo)}</small>
              {seEdita && (
                <button onClick={() => cambiar(() => api(`${base}/goles/${g.id_gol}`, { method: 'DELETE' }))}>Quitar</button>
              )}
            </li>
          ))}
        </ul>

        <h3>Tarjetas</h3>
        {enPlanilla.length > 0 && (
          <fieldset disabled={!seEdita}>
            <Formulario campos={camposTarjeta} onGuardar={(v) => agregar('tarjetas', v)} textoAlta="Anotar tarjeta" />
          </fieldset>
        )}
        <ul className="lista-hechos">
          {tarjetas.map((t) => (
            <li key={t.id_tarjeta}>
              <span className="minuto num">{t.minuto}'</span>
              <span className={`tarjeta ${t.color}`} title={t.color} />
              <span>
                {t.nombre} {t.apellido}
              </span>
              <small>{nombreEquipo(t.id_equipo)}</small>
              {seEdita && (
                <button onClick={() => cambiar(() => api(`${base}/tarjetas/${t.id_tarjeta}`, { method: 'DELETE' }))}>
                  Quitar
                </button>
              )}
            </li>
          ))}
        </ul>

        <div className="pizarra-firma">
          <span>Planillero</span>
          <span className="linea">{usuario.correo}</span>
        </div>
      </div>
    </>
  )
}
