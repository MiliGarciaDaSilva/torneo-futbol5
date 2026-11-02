import { useState } from 'react'
import { api } from '../api.js'
import Formulario from '../components/Formulario.jsx'
import Tabla from '../components/Tabla.jsx'
import { useDatos } from '../useDatos.js'

const TIPOS = ['grado', 'posgrado', 'docente', 'funcionario']
const HOY = new Date().toLocaleDateString('sv') // AAAA-MM-DD, para que no se pueda nacer en el futuro

export default function Jugadores() {
  const { datos: facultades } = useDatos('/facultades')
  const [facultad, setFacultad] = useState('') // filtro de la lista; '' = todas
  const { datos: jugadores, error: errorCarga, recargar } = useDatos(
    facultad ? `/jugadores?id_facultad=${facultad}` : '/jugadores',
  )
  const [editando, setEditando] = useState(null)
  const [error, setError] = useState('')

  const campos = [
    {
      nombre: 'ci', etiqueta: 'Cédula', requerido: true, soloAlta: true,
      pattern: '[0-9]{7,8}', title: 'Solo números, sin puntos ni guion (7 u 8 cifras)',
    },
    { nombre: 'nombre', etiqueta: 'Nombre', requerido: true, maxLength: 50 },
    { nombre: 'apellido', etiqueta: 'Apellido', requerido: true, maxLength: 50 },
    { nombre: 'email', etiqueta: 'Correo', tipo: 'email', requerido: true, maxLength: 100 },
    {
      nombre: 'fecha_nacimiento', etiqueta: 'Nacimiento', tipo: 'date', requerido: true,
      max: HOY,
    },
    {
      nombre: 'id_facultad', etiqueta: 'Facultad', tipo: 'select', requerido: true,
      opciones: facultades.map((f) => ({ valor: f.id_facultad, texto: f.nombre })),
    },
    {
      nombre: 'tipo', etiqueta: 'Tipo', tipo: 'select', requerido: true,
      opciones: TIPOS.map((t) => ({ valor: t, texto: t })),
    },
  ]

  async function guardar(valores) {
    if (editando) {
      await api(`/jugadores/${editando.ci}`, { method: 'PUT', body: valores })
    } else {
      await api('/jugadores', { method: 'POST', body: valores })
    }
    setEditando(null)
    recargar()
  }

  async function borrar(jugador) {
    if (!confirm(`¿Borrar a ${jugador.nombre} ${jugador.apellido}?`)) return
    setError('')
    try {
      await api(`/jugadores/${jugador.ci}`, { method: 'DELETE' })
      recargar()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <>
      <h2>Jugadores</h2>

      <Formulario
        key={editando?.ci ?? 'alta'}
        campos={campos}
        inicial={editando}
        onGuardar={guardar}
        onCancelar={() => setEditando(null)}
        textoAlta="Agregar jugador"
      />

      <div className="filtros">
        <label>
          Ver jugadores de
          <select value={facultad} onChange={(e) => setFacultad(e.target.value)}>
            <option value="">Todas las facultades</option>
            {facultades.map((f) => (
              <option key={f.id_facultad} value={f.id_facultad}>
                {f.nombre}
              </option>
            ))}
          </select>
        </label>
      </div>

      {(errorCarga || error) && <p className="error">{errorCarga || error}</p>}
      <Tabla
        columnas={[
          { campo: 'ci', titulo: 'Cédula' },
          { campo: 'nombre', titulo: 'Nombre' },
          { campo: 'apellido', titulo: 'Apellido' },
          { campo: 'email', titulo: 'Correo' },
          { campo: 'fecha_nacimiento', titulo: 'Nacimiento' },
          { campo: 'facultad', titulo: 'Facultad' },
          { campo: 'tipo', titulo: 'Tipo' },
        ]}
        filas={jugadores}
        acciones={(jugador) => (
          <>
            <button className="secondary" onClick={() => setEditando(jugador)}>
              Editar
            </button>
            <button className="contrast" onClick={() => borrar(jugador)}>
              Borrar
            </button>
          </>
        )}
      />
    </>
  )
}
