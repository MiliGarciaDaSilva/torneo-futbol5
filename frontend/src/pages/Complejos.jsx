// ABM de ejemplo: las demás pantallas de ABM se arman copiando esta.
import { useEffect, useState } from 'react'
import { api } from '../api.js'
import Tabla from '../components/Tabla.jsx'

const DEPARTAMENTOS = [
  'Artigas', 'Canelones', 'Cerro Largo', 'Colonia', 'Durazno', 'Flores', 'Florida',
  'Lavalleja', 'Maldonado', 'Montevideo', 'Paysandú', 'Río Negro', 'Rivera', 'Rocha',
  'Salto', 'San José', 'Soriano', 'Tacuarembó', 'Treinta y Tres',
]

const VACIO = { nombre: '', direccion: '', departamento: '' }

export default function Complejos() {
  const [complejos, setComplejos] = useState([])
  const [form, setForm] = useState(VACIO)
  const [editando, setEditando] = useState(null) // id del complejo que se está editando; null = alta
  const [error, setError] = useState('')

  async function cargar() {
    try {
      setComplejos(await api('/complejos'))
    } catch (err) {
      setError(err.message)
    }
  }

  useEffect(() => {
    cargar()
  }, [])

  function cambiar(e) {
    setForm({ ...form, [e.target.name]: e.target.value })
  }

  function limpiar() {
    setForm(VACIO)
    setEditando(null)
    setError('')
  }

  async function guardar(e) {
    e.preventDefault()
    setError('')
    try {
      if (editando) {
        await api(`/complejos/${editando}`, { method: 'PUT', body: form })
      } else {
        await api('/complejos', { method: 'POST', body: form })
      }
      limpiar()
      cargar()
    } catch (err) {
      setError(err.message)
    }
  }

  function editar(complejo) {
    setEditando(complejo.id_complejo)
    setForm({ nombre: complejo.nombre, direccion: complejo.direccion, departamento: complejo.departamento })
  }

  async function borrar(complejo) {
    if (!confirm(`¿Borrar el complejo ${complejo.nombre}?`)) return
    setError('')
    try {
      await api(`/complejos/${complejo.id_complejo}`, { method: 'DELETE' })
      cargar()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <>
      <h2>Complejos deportivos</h2>

      <form onSubmit={guardar}>
        <fieldset className="grid">
          <label>
            Nombre
            <input name="nombre" required maxLength={100} value={form.nombre} onChange={cambiar} />
          </label>
          <label>
            Dirección
            <input name="direccion" required maxLength={200} value={form.direccion} onChange={cambiar} />
          </label>
          <label>
            Departamento
            <select name="departamento" required value={form.departamento} onChange={cambiar}>
              <option value="" disabled>
                Elegí uno
              </option>
              {DEPARTAMENTOS.map((d) => (
                <option key={d}>{d}</option>
              ))}
            </select>
          </label>
        </fieldset>
        {error && <p className="error">{error}</p>}
        <button type="submit">{editando ? 'Guardar cambios' : 'Agregar complejo'}</button>{' '}
        {editando && (
          <button type="button" className="secondary" onClick={limpiar}>
            Cancelar
          </button>
        )}
      </form>

      <Tabla
        columnas={[
          { campo: 'nombre', titulo: 'Nombre' },
          { campo: 'direccion', titulo: 'Dirección' },
          { campo: 'departamento', titulo: 'Departamento' },
        ]}
        filas={complejos}
        acciones={(complejo) => (
          <>
            <button className="secondary" onClick={() => editar(complejo)}>
              Editar
            </button>
            <button className="contrast" onClick={() => borrar(complejo)}>
              Borrar
            </button>
          </>
        )}
      />
    </>
  )
}
