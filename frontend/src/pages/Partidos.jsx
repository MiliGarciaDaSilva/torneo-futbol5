// Lista de partidos con filtros. De acá se entra a la planilla de cada partido jugado,
// y los partidos que ya pasaron se marcan como jugados (el planillero y el admin).
// El admin además da de alta, modifica, borra y cambia de estado los partidos. Las reglas (5 jugadores por equipo,
// rival repetido, un partido por equipo por fecha, cancha ocupada, partido jugado que no se borra) las controla la base:
// si rechaza algo, el mensaje del trigger aparece en el formulario o arriba de la tabla.
import { useCallback, useState } from 'react'
import { Link } from 'react-router-dom'
import { api } from '../api.js'
import { ADMIN, useAuth } from '../auth.jsx'
import ElegirTorneo from '../components/ElegirTorneo.jsx'
import Formulario from '../components/Formulario.jsx'
import Tabla from '../components/Tabla.jsx'
import { useDatos } from '../useDatos.js'

const ESTADOS = ['programado', 'jugado', 'postergado', 'cancelado']

// A qué estados puede pasar el admin desde cada uno (a jugado se pasa con "Marcar como jugado", cuando el turno ya terminó)
const SIGUIENTES = {
  programado: [
    { estado: 'postergado', texto: 'Postergar' },
    { estado: 'cancelado', texto: 'Cancelar partido' },
  ],
  postergado: [
    { estado: 'programado', texto: 'Reprogramar' },
    { estado: 'cancelado', texto: 'Cancelar partido' },
  ],
  cancelado: [{ estado: 'programado', texto: 'Reprogramar' }],
}

// El turno ya terminó; la base vuelve a controlarlo al marcar el partido como jugado
function yaPaso(partido) {
  return new Date(`${partido.dia}T${partido.hora_fin}`) <= new Date()
}

export default function Partidos() {
  const { usuario } = useAuth()
  const esAdmin = usuario.rol === ADMIN
  const [torneo, setTorneo] = useState(null)
  const [estado, setEstado] = useState('')
  const [fecha, setFecha] = useState('')
  const [editando, setEditando] = useState(null) // partido que se está editando; null = alta
  const [errorAccion, setErrorAccion] = useState('')

  let ruta = null // espera a que haya un torneo elegido
  if (torneo) {
    const filtros = new URLSearchParams({ id_torneo: torneo })
    if (estado) filtros.set('estado', estado)
    if (fecha) filtros.set('numero_fecha', fecha)
    ruta = `/partidos?${filtros}`
  }
  const { datos: partidos, error, recargar } = useDatos(ruta)

  // Lo que necesita el formulario de alta: solo se pide si el que entró es el admin
  const { datos: torneos } = useDatos(esAdmin ? '/torneos' : null)
  const { datos: equipos } = useDatos(esAdmin && torneo ? `/equipos?id_torneo=${torneo}` : null)
  const { datos: canchas } = useDatos(esAdmin ? '/canchas' : null)
  const { datos: turnos } = useDatos(esAdmin ? '/turnos' : null)
  const elegido = torneos.find((t) => t.id_torneo === torneo)

  const cambiarTorneo = useCallback((id) => {
    setTorneo(id)
    setEditando(null)
  }, [])

  const campos = [
    { nombre: 'numero_fecha', etiqueta: 'Fecha', tipo: 'number', requerido: true, min: 1, max: 50 },
    {
      nombre: 'id_equipo_local', etiqueta: 'Local', tipo: 'select', requerido: true,
      opciones: equipos.map((e) => ({ valor: e.id_equipo, texto: e.nombre })),
    },
    {
      nombre: 'id_equipo_visitante', etiqueta: 'Visitante', tipo: 'select', requerido: true,
      // Un equipo no juega contra sí mismo: el que se eligió de local no se ofrece de visitante
      opciones: (valores) =>
        equipos.filter((e) => e.id_equipo !== valores.id_equipo_local).map((e) => ({ valor: e.id_equipo, texto: e.nombre })),
    },
    {
      nombre: 'dia', etiqueta: 'Día', tipo: 'date', requerido: true,
      min: elegido?.fecha_inicio, max: elegido?.fecha_fin,
    },
    {
      nombre: 'id_turno', etiqueta: 'Turno', tipo: 'select', requerido: true,
      opciones: turnos.map((t) => ({ valor: t.id_turno, texto: `${t.hora_inicio} a ${t.hora_fin}` })),
    },
    {
      // La cancha se identifica con el complejo y el nombre; en el desplegable va todo junto
      nombre: 'cancha', etiqueta: 'Cancha', tipo: 'select', requerido: true,
      opciones: canchas.map((c) => ({ valor: valorCancha(c), texto: `${c.nombre_cancha}, ${c.complejo}` })),
    },
  ]

  async function guardar(valores) {
    const { cancha, ...resto } = valores
    const [idComplejo, ...nombre] = cancha.split('|')
    const cuerpo = { ...resto, id_torneo: torneo, id_complejo: Number(idComplejo), nombre_cancha: nombre.join('|') }
    if (editando) {
      await api(`/partidos/${editando.id_partido}`, { method: 'PUT', body: cuerpo })
    } else {
      await api('/partidos', { method: 'POST', body: cuerpo })
    }
    setEditando(null)
    recargar()
  }

  // Ejecuta una acción sobre una fila y muestra el error si la base la rechaza
  async function accion(pedido) {
    setErrorAccion('')
    try {
      await pedido()
      recargar()
    } catch (err) {
      setErrorAccion(err.message)
    }
  }

  function marcarJugado(partido) {
    accion(() => api(`/partidos/${partido.id_partido}/estado`, { method: 'PATCH', body: { estado: 'jugado' } }))
  }

  function cambiarEstado(partido, siguiente) {
    if (siguiente.estado === 'cancelado' && !confirm(`¿Cancelar ${descripcion(partido)}?`)) return
    accion(() => api(`/partidos/${partido.id_partido}/estado`, { method: 'PATCH', body: { estado: siguiente.estado } }))
  }

  function borrar(partido) {
    if (!confirm(`¿Borrar ${descripcion(partido)}?`)) return
    accion(async () => {
      await api(`/partidos/${partido.id_partido}`, { method: 'DELETE' })
      if (editando?.id_partido === partido.id_partido) setEditando(null)
    })
  }

  // Primero los más recientes
  const filas = [...partidos]
    .sort((a, b) => b.dia.localeCompare(a.dia) || b.id_partido - a.id_partido)
    .map((p) => ({ ...p, cancha: `${p.nombre_cancha}, ${p.complejo}`, hora: p.hora_inicio }))

  return (
    <>
      <h2>Partidos</h2>

      <div className="filtros">
        <ElegirTorneo valor={torneo} onCambio={cambiarTorneo} />
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

      {esAdmin && torneo && (
        <>
          <h3>{editando ? `Editar ${descripcion(editando)}` : 'Nuevo partido'}</h3>
          <Formulario
            key={editando?.id_partido ?? `alta-${torneo}`}
            campos={campos}
            inicial={editando && { ...editando, cancha: valorCancha(editando) }}
            onGuardar={guardar}
            onCancelar={() => setEditando(null)}
            textoAlta="Programar partido"
          />
        </>
      )}

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
          acciones={(p) => (
            <>
              {p.estado === 'jugado' && <Link to={`/partidos/${p.id_partido}/planilla`}>Planilla</Link>}
              {(p.estado === 'programado' || p.estado === 'postergado') && yaPaso(p) && (
                <button onClick={() => marcarJugado(p)}>Marcar como jugado</button>
              )}
              {esAdmin && p.estado !== 'jugado' && (
                <>
                  {SIGUIENTES[p.estado].map((s) => (
                    <button key={s.estado} className="secondary" onClick={() => cambiarEstado(p, s)}>
                      {s.texto}
                    </button>
                  ))}
                  <button className="secondary" onClick={() => setEditando(p)}>
                    Editar
                  </button>
                  <button className="contrast" onClick={() => borrar(p)}>
                    Borrar
                  </button>
                </>
              )}
            </>
          )}
        />
      )}
    </>
  )
}

const valorCancha = (c) => `${c.id_complejo}|${c.nombre_cancha}`

const descripcion = (p) => `el partido ${p.equipo_local} vs ${p.equipo_visitante} (fecha ${p.numero_fecha})`
