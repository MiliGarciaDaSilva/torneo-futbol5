// Lista de partidos con filtros. De acá se entra a la planilla de cada partido jugado,
// y los partidos que ya pasaron se marcan como jugados (el planillero y el admin).
// (El alta, la modificación y el cambio de estado de partidos del admin se suman en esta misma pantalla.)
import { useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../api.js'
import ElegirTorneo from '../components/ElegirTorneo.jsx'
import Tabla from '../components/Tabla.jsx'
import { useDatos } from '../useDatos.js'

const ESTADOS = ['programado', 'jugado', 'postergado', 'cancelado']

// El turno ya terminó; la base vuelve a controlarlo al marcar el partido como jugado
function yaPaso(partido) {
  return new Date(`${partido.dia}T${partido.hora_fin}`) <= new Date()
}

export default function Partidos() {
  const [torneo, setTorneo] = useState(null)
  const [estado, setEstado] = useState('')
  const [fecha, setFecha] = useState('')
  const [errorAccion, setErrorAccion] = useState('')

  let ruta = null // espera a que haya un torneo elegido
  if (torneo) {
    const filtros = new URLSearchParams({ id_torneo: torneo })
    if (estado) filtros.set('estado', estado)
    if (fecha) filtros.set('numero_fecha', fecha)
    ruta = `/partidos?${filtros}`
  }
  const { datos: partidos, error, recargar } = useDatos(ruta)

  async function marcarJugado(partido) {
    setErrorAccion('')
    try {
      await api(`/partidos/${partido.id_partido}/estado`, { method: 'PATCH', body: { estado: 'jugado' } })
      recargar()
    } catch (err) {
      setErrorAccion(err.message)
    }
  }

  // Primero los más recientes
  const filas = [...partidos]
    .sort((a, b) => b.dia.localeCompare(a.dia) || b.id_partido - a.id_partido)
    .map((p) => ({ ...p, cancha: `${p.nombre_cancha}, ${p.complejo}`, hora: p.hora_inicio }))

  return (
    <>
      <h2>Partidos</h2>

      <div className="filtros">
        <ElegirTorneo valor={torneo} onCambio={setTorneo} />
        <label>
          Estado
          <select value={estado} onChange={(e) => setEstado(e.target.value)}>
            <option value="">Todos</option>
            {ESTADOS.map((e) => (
              <option key={e} value={e}>
                {e}
              </option>
            ))}
          </select>
        </label>
        <label>
          Fecha
          <input type="number" min={1} max={50} value={fecha} onChange={(e) => setFecha(e.target.value)} />
        </label>
      </div>

      {errorAccion && <p className="error">{errorAccion}</p>}

      {error ? (
        <p className="error">{error}</p>
      ) : (
        <Tabla
          columnas={[
            { campo: 'numero_fecha', titulo: 'Fecha' },
            { campo: 'dia', titulo: 'Día' },
            { campo: 'hora', titulo: 'Hora' },
            { campo: 'equipo_local', titulo: 'Local' },
            { campo: 'equipo_visitante', titulo: 'Visitante' },
            { campo: 'cancha', titulo: 'Cancha' },
            { campo: 'estado', titulo: 'Estado' },
          ]}
          filas={filas}
          acciones={(p) => {
            if (p.estado === 'jugado') return <Link to={`/partidos/${p.id_partido}/planilla`}>Planilla</Link>
            if ((p.estado === 'programado' || p.estado === 'postergado') && yaPaso(p)) {
              return <button onClick={() => marcarJugado(p)}>Marcar como jugado</button>
            }
          }}
        />
      )}
    </>
  )
}
