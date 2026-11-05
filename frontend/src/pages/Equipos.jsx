// ABM de equipos con su plantel. Las reglas (solo en inscripción, plantel de 5 a 10, jugadores de la facultad del
// equipo, máximo 2 docentes o funcionarios, capitán en el plantel) las controla la base; acá se muestran y se evita
// mandar lo que seguro va a ser rechazado, y si la base rechaza algo se muestra su mensaje.
import { useCallback, useState } from 'react'
import { api } from '../api.js'
import ElegirTorneo from '../components/ElegirTorneo.jsx'
import Formulario from '../components/Formulario.jsx'
import Tabla from '../components/Tabla.jsx'
import { useDatos } from '../useDatos.js'

const MINIMO = 5
const MAXIMO = 10
const MAX_DOCENTES = 2
const TIPOS_DOCENTE = ['docente', 'funcionario']

export default function Equipos() {
  const [torneo, setTorneo] = useState(null)
  const [editando, setEditando] = useState(null) // equipo que se está editando; null = alta
  const [elegidoId, setElegidoId] = useState(null) // equipo cuyo plantel se está viendo
  const [error, setError] = useState('')

  const { datos: torneos } = useDatos('/torneos')
  const { datos: facultades } = useDatos('/facultades')
  const { datos: jugadores } = useDatos('/jugadores')
  const { datos: equipos, error: errorCarga, recargar } = useDatos(torneo ? `/equipos?id_torneo=${torneo}` : null)
  // El capitán de un equipo ya armado tiene que ser de su plantel, por eso al editar se pide el plantel
  const { datos: plantelEditando } = useDatos(editando ? `/equipos/${editando.id_equipo}/plantel` : null)

  const enInscripcion = torneos.find((t) => t.id_torneo === torneo)?.estado === 'inscripcion'
  const elegido = equipos.find((e) => e.id_equipo === elegidoId)

  const cambiarTorneo = useCallback((id) => {
    setTorneo(id)
    setEditando(null)
    setElegidoId(null)
  }, [])

  // Una facultad tiene un solo equipo por torneo: al crear solo se ofrecen las que todavía no tienen
  const facultadesLibres = facultades.filter((f) => editando || !equipos.some((e) => e.id_facultad === f.id_facultad))

  const campos = [
    { nombre: 'nombre', etiqueta: 'Nombre del equipo', requerido: true, maxLength: 100 },
    {
      nombre: 'id_facultad', etiqueta: 'Facultad', tipo: 'select', requerido: true, soloAlta: true,
      opciones: facultadesLibres.map((f) => ({ valor: f.id_facultad, texto: f.nombre })),
    },
    {
      nombre: 'ci_capitan', etiqueta: 'Capitán', tipo: 'select', requerido: true,
      // Al crear, alcanza con que sea de la facultad; al editar tiene que estar en el plantel
      opciones: (valores) =>
        (editando ? plantelEditando : jugadores.filter((j) => j.id_facultad === valores.id_facultad)).map((j) => ({
          valor: j.ci,
          texto: `${j.nombre} ${j.apellido}`,
        })),
    },
  ]

  async function guardar(valores) {
    const cuerpo = { ...valores, id_torneo: torneo }
    if (editando) {
      await api(`/equipos/${editando.id_equipo}`, { method: 'PUT', body: cuerpo })
    } else {
      const nuevo = await api('/equipos', { method: 'POST', body: cuerpo })
      if (nuevo?.id_equipo) setElegidoId(nuevo.id_equipo) // para cargarle el plantel enseguida
    }
    setEditando(null)
    recargar()
  }

  function editar(equipo) {
    setEditando(equipo)
    setElegidoId(equipo.id_equipo)
  }

  async function borrar(equipo) {
    if (!confirm(`¿Borrar el equipo ${equipo.nombre}?`)) return
    setError('')
    try {
      await api(`/equipos/${equipo.id_equipo}`, { method: 'DELETE' })
      if (elegidoId === equipo.id_equipo) setElegidoId(null)
      recargar()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <>
      <h2>Equipos y planteles</h2>

      <div className="filtros">
        <ElegirTorneo valor={torneo} onCambio={cambiarTorneo} />
      </div>

      {torneo && !enInscripcion && (
        <p className="aviso">Este torneo ya empezó: los equipos y los planteles solo se pueden cambiar en la inscripción.</p>
      )}

      {enInscripcion && (
        <>
          <h3>{editando ? `Editar ${editando.nombre}` : 'Nuevo equipo'}</h3>
          <Formulario
            key={editando?.id_equipo ?? `alta-${torneo}`}
            campos={campos}
            inicial={editando}
            onGuardar={guardar}
            onCancelar={() => setEditando(null)}
            textoAlta="Crear equipo"
          />
        </>
      )}

      {(errorCarga || error) && <p className="error">{errorCarga || error}</p>}
      <h3>Equipos</h3>
      <Tabla
        columnas={[
          { campo: 'nombre', titulo: 'Equipo' },
          { campo: 'facultad', titulo: 'Facultad' },
          { campo: 'capitan', titulo: 'Capitán' },
          { campo: 'cantidad_jugadores', titulo: 'Jugadores' },
        ]}
        filas={equipos}
        acciones={(equipo) => (
          <>
            <button className="secondary" onClick={() => setElegidoId(equipo.id_equipo)}>
              Plantel
            </button>
            {enInscripcion && (
              <>
                <button className="secondary" onClick={() => editar(equipo)}>
                  Editar
                </button>
                <button className="contrast" onClick={() => borrar(equipo)}>
                  Borrar
                </button>
              </>
            )}
          </>
        )}
      />

      {elegido && (
        <Plantel key={elegido.id_equipo} equipo={elegido} jugadores={jugadores} enInscripcion={enInscripcion} alCambiar={recargar} />
      )}
    </>
  )
}

function Plantel({ equipo, jugadores, enInscripcion, alCambiar }) {
  const { datos: plantel, error: errorCarga, recargar } = useDatos(`/equipos/${equipo.id_equipo}/plantel`)
  const [error, setError] = useState('')

  const docentes = plantel.filter((p) => TIPOS_DOCENTE.includes(p.tipo)).length
  const completo = plantel.length >= MAXIMO

  // Se ofrecen los de la facultad del equipo que todavía no están en el plantel, y no más docentes si ya hay dos
  const candidatos = jugadores.filter(
    (j) =>
      j.id_facultad === equipo.id_facultad &&
      !plantel.some((p) => p.ci === j.ci) &&
      !(TIPOS_DOCENTE.includes(j.tipo) && docentes >= MAX_DOCENTES),
  )

  const campos = [
    {
      nombre: 'ci_jugador', etiqueta: 'Jugador', tipo: 'select', requerido: true,
      opciones: candidatos.map((j) => ({ valor: j.ci, texto: `${j.nombre} ${j.apellido} (${j.tipo})` })),
    },
    { nombre: 'numero_camiseta', etiqueta: 'Camiseta', tipo: 'number', requerido: true, min: 1, max: 99 },
  ]

  async function agregar(valores) {
    if (plantel.some((p) => p.numero_camiseta === valores.numero_camiseta)) {
      throw new Error(`La camiseta ${valores.numero_camiseta} ya la tiene otro jugador del equipo`)
    }
    await api(`/equipos/${equipo.id_equipo}/plantel`, { method: 'POST', body: valores })
    recargar()
    alCambiar()
  }

  async function quitar(jugador) {
    if (!confirm(`¿Sacar a ${jugador.nombre} ${jugador.apellido} del plantel?`)) return
    setError('')
    try {
      await api(`/equipos/${equipo.id_equipo}/plantel/${jugador.ci}`, { method: 'DELETE' })
      recargar()
      alCambiar()
    } catch (err) {
      setError(err.message)
    }
  }

  const filas = plantel.map((p) => ({
    ...p,
    jugador: `${p.nombre} ${p.apellido}${p.ci === equipo.ci_capitan ? ' (capitán)' : ''}`,
  }))

  return (
    <>
      <h3>Plantel de {equipo.nombre}</h3>
      <p className="aviso">
        {plantel.length} de {MAXIMO} jugadores (hacen falta {MINIMO} como mínimo) · {docentes} de {MAX_DOCENTES} docentes o
        funcionarios
      </p>

      {enInscripcion &&
        (completo ? (
          <p className="aviso">El plantel está completo.</p>
        ) : (
          <Formulario campos={campos} onGuardar={agregar} textoAlta="Agregar al plantel" />
        ))}

      {(errorCarga || error) && <p className="error">{errorCarga || error}</p>}
      <Tabla
        columnas={[
          { campo: 'numero_camiseta', titulo: 'Camiseta' },
          { campo: 'jugador', titulo: 'Jugador' },
          { campo: 'tipo', titulo: 'Tipo' },
        ]}
        filas={filas}
        acciones={
          enInscripcion
            ? (jugador) => (
                <button className="contrast" onClick={() => quitar(jugador)}>
                  Quitar
                </button>
              )
            : undefined
        }
      />
    </>
  )
}
