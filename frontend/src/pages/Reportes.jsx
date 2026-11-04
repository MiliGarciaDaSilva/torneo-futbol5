import { useState } from 'react'
import ElegirTorneo from '../components/ElegirTorneo.jsx'
import Tabla from '../components/Tabla.jsx'
import { useDatos } from '../useDatos.js'

// Una entrada por ruta GET /reportes/{clave} del backend. porTorneo: se filtra por el torneo elegido.
const REPORTES = [
  { clave: 'posiciones', titulo: 'Tabla de posiciones', porTorneo: true },
  { clave: 'goleadores', titulo: 'Goleadores (top 10)', porTorneo: true },
  { clave: 'fair-play', titulo: 'Fair play (1 punto la amarilla, 3 la roja; gana el que tiene menos)', porTorneo: true },
  { clave: 'goles-por-fecha', titulo: 'Promedio de goles por fecha', porTorneo: true },
  { clave: 'goles-por-edicion', titulo: 'Promedio de goles por edición', porTorneo: false },
  { clave: 'canchas', titulo: 'Canchas más usadas', porTorneo: false },
  { clave: 'turnos', titulo: 'Turnos más usados', porTorneo: false },
  { clave: 'jugadores-por-facultad', titulo: 'Jugadores por facultad', porTorneo: false },
  { clave: 'jugadores-por-tipo', titulo: 'Jugadores por tipo', porTorneo: false },
  { clave: 'nunca-en-planilla', titulo: 'Jugadores que nunca estuvieron en una planilla', porTorneo: true },
  { clave: 'sanciones-por-equipo', titulo: 'Sanciones por equipo', porTorneo: true },
  { clave: 'sanciones-por-motivo', titulo: 'Sanciones por motivo', porTorneo: true },
  { clave: 'estados', titulo: 'Partidos jugados, postergados y cancelados (%)', porTorneo: true },
  // Las 3 consultas que propusimos nosotros
  { clave: 'suspendidos', titulo: 'Suspendidos para la próxima fecha', porTorneo: true },
  { clave: 'partidos-mas-goles', titulo: 'Partidos con más goles', porTorneo: true },
  { clave: 'local-vs-visitante', titulo: 'Rendimiento de local y de visitante', porTorneo: true },
]

// Los reportes que son una tabla de posiciones: se muestran numerados
const RANKINGS = ['posiciones', 'goleadores', 'fair-play']

export default function Reportes() {
  const [clave, setClave] = useState(REPORTES[0].clave)
  const [torneo, setTorneo] = useState(null)
  const reporte = REPORTES.find((r) => r.clave === clave)

  let ruta = `/reportes/${clave}`
  if (reporte.porTorneo) ruta = torneo ? `${ruta}?id_torneo=${torneo}` : null // espera a que haya torneo
  const { datos, error } = useDatos(ruta)

  return (
    <>
      <h2>Reportes</h2>

      <div className="filtros">
        <label>
          Reporte
          <select value={clave} onChange={(e) => setClave(e.target.value)}>
            {REPORTES.map((r) => (
              <option key={r.clave} value={r.clave}>
                {r.titulo}
              </option>
            ))}
          </select>
        </label>
        {reporte.porTorneo && <ElegirTorneo valor={torneo} onCambio={setTorneo} />}
      </div>

      <h3>{reporte.titulo}</h3>
      {error ? <p className="error">{error}</p> : <Tabla filas={datos.map((fila) => sinIds(fila, reporte.porTorneo))} numerar={RANKINGS.includes(clave)} />}
    </>
  )
}

// Las vistas traen columnas que no hace falta mostrar: los id y, si ya se filtró, el nombre del torneo
function sinIds(fila, porTorneo) {
  return Object.fromEntries(
    Object.entries(fila).filter(([campo]) => !campo.startsWith('id_') && !(porTorneo && campo === 'torneo')),
  )
}
