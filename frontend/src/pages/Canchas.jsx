// ABM de canchas. La clave es compuesta (complejo + nombre), por eso no se pueden cambiar al editar:
// solo la superficie y si es techada. Si la cancha ya tiene partidos, la base no deja borrarla.
import { useState } from 'react'
import { api } from '../api.js'
import Formulario from '../components/Formulario.jsx'
import Tabla from '../components/Tabla.jsx'
import { useDatos } from '../useDatos.js'

const SUPERFICIES = [
  { valor: 'sintetico', texto: 'Sintético' },
  { valor: 'parquet', texto: 'Parquet' },
]

export default function Canchas() {
  const { datos: complejos } = useDatos('/complejos')
  const { datos: canchas, error: errorCarga, recargar } = useDatos('/canchas')
  const [editando, setEditando] = useState(null) // cancha que se está editando; null = alta
  const [error, setError] = useState('')

  const campos = [
    { nombre: 'nombre_cancha', etiqueta: 'Nombre', requerido: true, maxLength: 50, soloAlta: true },
    {
      nombre: 'id_complejo', etiqueta: 'Complejo', tipo: 'select', requerido: true, soloAlta: true,
      opciones: complejos.map((c) => ({ valor: c.id_complejo, texto: c.nombre })),
    },
    { nombre: 'superficie', etiqueta: 'Superficie', tipo: 'select', requerido: true, opciones: SUPERFICIES },
    { nombre: 'techada', etiqueta: 'Techada', tipo: 'checkbox' },
  ]

  async function guardar(valores) {
    if (editando) {
      await api(`/canchas/${editando.id_complejo}/${encodeURIComponent(editando.nombre_cancha)}`, {
        method: 'PUT',
        body: valores,
      })
    } else {
      await api('/canchas', { method: 'POST', body: valores })
    }
    setEditando(null)
    recargar()
  }

  async function borrar(cancha) {
    if (!confirm(`¿Borrar la cancha ${cancha.nombre_cancha} de ${cancha.complejo}?`)) return
    setError('')
    try {
      await api(`/canchas/${cancha.id_complejo}/${encodeURIComponent(cancha.nombre_cancha)}`, { method: 'DELETE' })
      recargar()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <>
      <h2>Canchas</h2>

      <Formulario
        key={editando ? `${editando.id_complejo}/${editando.nombre_cancha}` : 'alta'}
        campos={campos}
        inicial={editando}
        onGuardar={guardar}
        onCancelar={() => setEditando(null)}
        textoAlta="Agregar cancha"
      />

      {(errorCarga || error) && <p className="error">{errorCarga || error}</p>}
      <Tabla
        columnas={[
          { campo: 'nombre_cancha', titulo: 'Cancha' },
          { campo: 'complejo', titulo: 'Complejo' },
          { campo: 'texto_superficie', titulo: 'Superficie' },
          { campo: 'techada', titulo: 'Techada' },
        ]}
        filas={canchas.map((c) => ({ ...c, texto_superficie: SUPERFICIES.find((s) => s.valor === c.superficie)?.texto }))}
        acciones={(cancha) => (
          <>
            <button className="secondary" onClick={() => setEditando(cancha)}>
              Editar
            </button>
            <button className="contrast" onClick={() => borrar(cancha)}>
              Borrar
            </button>
          </>
        )}
      />
    </>
  )
}
