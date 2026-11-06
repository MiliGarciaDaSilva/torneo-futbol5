// ABM de sanciones de un torneo. Hay dos clases:
//   - automáticas: las crea la base sola con una roja o la tercera amarilla. Se pueden alargar o acortar, pero no se
//     borran desde acá (se van solas si se borra la tarjeta que las generó) y su motivo no cambia.
//   - disciplinarias: las carga el administrador a mano, para el jugador de un plantel del torneo.
import { useCallback, useEffect, useState } from 'react'
import { api } from '../api.js'
import ElegirTorneo from '../components/ElegirTorneo.jsx'
import Formulario from '../components/Formulario.jsx'
import Tabla from '../components/Tabla.jsx'
import { useDatos } from '../useDatos.js'

const MOTIVOS = [
  { valor: 'disciplinaria', texto: 'Disciplinaria' },
  { valor: 'roja', texto: 'Roja' },
  { valor: 'acumulacion de amarillas', texto: 'Acumulación de amarillas' },
]
const SOLO_DISCIPLINARIA = MOTIVOS.slice(0, 1)

export default function Sanciones() {
  const [torneo, setTorneo] = useState(null)
  const [editando, setEditando] = useState(null) // sanción que se está editando; null = alta
  const [error, setError] = useState('')

  const { datos: equipos } = useDatos(torneo ? `/equipos?id_torneo=${torneo}` : null)
  const { datos: sanciones, error: errorCarga, recargar } = useDatos(torneo ? `/sanciones?id_torneo=${torneo}` : null)
  const jugadores = useJugadoresDelTorneo(equipos)

  const cambiarTorneo = useCallback((id) => {
    setTorneo(id)
    setEditando(null)
  }, [])

  const campos = [
    {
      nombre: 'ci_jugador', etiqueta: 'Jugador', tipo: 'select', requerido: true, soloAlta: true,
      opciones: jugadores.map((j) => ({ valor: j.ci, texto: `${j.apellido} ${j.nombre} (${j.equipo})` })),
    },
    {
      nombre: 'motivo', etiqueta: 'Motivo', tipo: 'select', requerido: true, soloAlta: true,
      opciones: editando ? MOTIVOS : SOLO_DISCIPLINARIA,
    },
    { nombre: 'numero_fecha_inicio', etiqueta: 'Desde la fecha', tipo: 'number', requerido: true, min: 1, max: 99 },
    { nombre: 'cantidad_fechas', etiqueta: 'Cantidad de fechas', tipo: 'number', requerido: true, min: 1, max: 20 },
  ]

  async function guardar(valores) {
    if (editando) {
      const { numero_fecha_inicio, cantidad_fechas } = valores
      await api(`/sanciones/${editando.id_sancion}`, {
        method: 'PUT',
        body: { motivo: editando.motivo, numero_fecha_inicio, cantidad_fechas },
      })
    } else {
      await api('/sanciones', { method: 'POST', body: { ...valores, id_torneo: torneo } })
    }
    setEditando(null)
    recargar()
  }

  async function borrar(sancion) {
    if (!confirm(`¿Borrar la sanción de ${sancion.nombre} ${sancion.apellido}?`)) return
    setError('')
    try {
      await api(`/sanciones/${sancion.id_sancion}`, { method: 'DELETE' })
      recargar()
    } catch (err) {
      setError(err.message)
    }
  }

  const filas = sanciones.map((s) => ({
    ...s,
    jugador: `${s.apellido} ${s.nombre}`,
    origen: s.id_tarjeta === null ? 'A mano' : 'Automática',
  }))

  return (
    <>
      <h2>Sanciones</h2>

      <div className="filtros">
        <ElegirTorneo valor={torneo} onCambio={cambiarTorneo} />
      </div>

      {torneo && (
        <>
          <h3>{editando ? `Editar la sanción de ${editando.nombre} ${editando.apellido}` : 'Nueva sanción disciplinaria'}</h3>
          <Formulario
            key={editando?.id_sancion ?? `alta-${torneo}-${jugadores.length}`}
            campos={campos}
            inicial={editando}
            onGuardar={guardar}
            onCancelar={() => setEditando(null)}
            textoAlta="Cargar sanción"
          />
        </>
      )}

      {(errorCarga || error) && <p className="error">{errorCarga || error}</p>}
      <Tabla
        columnas={[
          { campo: 'jugador', titulo: 'Jugador' },
          { campo: 'equipo', titulo: 'Equipo' },
          { campo: 'motivo', titulo: 'Motivo' },
          { campo: 'numero_fecha_inicio', titulo: 'Desde' },
          { campo: 'numero_fecha_fin', titulo: 'Hasta' },
          { campo: 'cantidad_fechas', titulo: 'Fechas' },
          { campo: 'origen', titulo: 'Origen' },
        ]}
        filas={filas}
        acciones={(sancion) => (
          <>
            <button className="secondary" onClick={() => setEditando(sancion)}>
              Editar
            </button>
            {sancion.id_tarjeta === null && (
              <button className="contrast" onClick={() => borrar(sancion)}>
                Borrar
              </button>
            )}
          </>
        )}
      />
    </>
  )
}

// Todos los jugadores de los planteles de los equipos del torneo, cada uno con el nombre de su equipo
function useJugadoresDelTorneo(equipos) {
  const [jugadores, setJugadores] = useState([])

  useEffect(() => {
    let vigente = true
    Promise.all(
      equipos.map((e) =>
        api(`/equipos/${e.id_equipo}/plantel`).then((plantel) => plantel.map((j) => ({ ...j, equipo: e.nombre }))),
      ),
    )
      .then((planteles) => vigente && setJugadores(planteles.flat()))
      .catch(() => vigente && setJugadores([]))
    return () => {
      vigente = false
    }
  }, [equipos])

  return jugadores
}
