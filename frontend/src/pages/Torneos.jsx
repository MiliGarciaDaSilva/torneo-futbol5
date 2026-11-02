import { useState } from 'react'
import { api } from '../api.js'
import Formulario from '../components/Formulario.jsx'
import Tabla from '../components/Tabla.jsx'
import { useDatos } from '../useDatos.js'

const CAMPOS = [
  { nombre: 'nombre', etiqueta: 'Nombre', requerido: true, maxLength: 100 },
  { nombre: 'anio', etiqueta: 'Año', tipo: 'number', requerido: true, min: 2000, max: 2100 },
  {
    nombre: 'semestre', etiqueta: 'Semestre', tipo: 'select', requerido: true,
    opciones: [{ valor: 1, texto: 'Primero' }, { valor: 2, texto: 'Segundo' }],
  },
  { nombre: 'fecha_inicio', etiqueta: 'Empieza', tipo: 'date', requerido: true },
  { nombre: 'fecha_fin', etiqueta: 'Termina', tipo: 'date', requerido: true },
]

// Las etapas van en orden: inscripción → en curso → finalizado (la base no deja volver atrás)
const SIGUIENTE = {
  inscripcion: { estado: 'en curso', texto: 'Empezar' },
  'en curso': { estado: 'finalizado', texto: 'Finalizar' },
}

export default function Torneos() {
  const { datos: torneos, error: errorCarga, recargar } = useDatos('/torneos')
  const [editando, setEditando] = useState(null)
  const [error, setError] = useState('')

  async function guardar(valores) {
    if (valores.fecha_fin < valores.fecha_inicio) {
      throw new Error('La fecha de fin no puede ser anterior a la de inicio')
    }
    if (editando) {
      await api(`/torneos/${editando.id_torneo}`, { method: 'PUT', body: valores })
    } else {
      await api('/torneos', { method: 'POST', body: valores })
    }
    setEditando(null)
    recargar()
  }

  // Ejecuta una acción sobre una fila y muestra el error si la base la rechaza
  async function accion(promesa) {
    setError('')
    try {
      await promesa()
      recargar()
    } catch (err) {
      setError(err.message)
    }
  }

  function avanzar(torneo) {
    const siguiente = SIGUIENTE[torneo.estado]
    if (!confirm(`¿Pasar ${torneo.nombre} a "${siguiente.estado}"?`)) return
    accion(() => api(`/torneos/${torneo.id_torneo}/estado`, { method: 'PATCH', body: { estado: siguiente.estado } }))
  }

  function borrar(torneo) {
    if (!confirm(`¿Borrar el torneo ${torneo.nombre}?`)) return
    accion(() => api(`/torneos/${torneo.id_torneo}`, { method: 'DELETE' }))
  }

  return (
    <>
      <h2>Torneos</h2>
      <p>
        Un torneo se crea en inscripción; cuando los planteles están cargados se empieza y ya no se pueden cambiar.
      </p>

      <Formulario
        key={editando?.id_torneo ?? 'alta'}
        campos={CAMPOS}
        inicial={editando}
        onGuardar={guardar}
        onCancelar={() => setEditando(null)}
        textoAlta="Crear torneo"
      />

      {(errorCarga || error) && <p className="error">{errorCarga || error}</p>}
      <Tabla
        columnas={[
          { campo: 'nombre', titulo: 'Nombre' },
          { campo: 'anio', titulo: 'Año' },
          { campo: 'semestre', titulo: 'Semestre' },
          { campo: 'fecha_inicio', titulo: 'Empieza' },
          { campo: 'fecha_fin', titulo: 'Termina' },
          { campo: 'estado', titulo: 'Etapa' },
        ]}
        filas={torneos}
        acciones={(torneo) => (
          <>
            <button className="secondary" onClick={() => setEditando(torneo)}>
              Editar
            </button>
            {SIGUIENTE[torneo.estado] && (
              <button onClick={() => avanzar(torneo)}>{SIGUIENTE[torneo.estado].texto}</button>
            )}
            <button className="contrast" onClick={() => borrar(torneo)}>
              Borrar
            </button>
          </>
        )}
      />
    </>
  )
}
