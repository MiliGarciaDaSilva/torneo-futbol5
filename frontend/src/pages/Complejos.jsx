// ABM de ejemplo: las demás pantallas de ABM se arman copiando esta.
import { useState } from 'react'
import { api } from '../api.js'
import Formulario from '../components/Formulario.jsx'
import Tabla from '../components/Tabla.jsx'
import { useDatos } from '../useDatos.js'

const DEPARTAMENTOS = [
  'Artigas', 'Canelones', 'Cerro Largo', 'Colonia', 'Durazno', 'Flores', 'Florida',
  'Lavalleja', 'Maldonado', 'Montevideo', 'Paysandú', 'Río Negro', 'Rivera', 'Rocha',
  'Salto', 'San José', 'Soriano', 'Tacuarembó', 'Treinta y Tres',
]

const CAMPOS = [
  { nombre: 'nombre', etiqueta: 'Nombre', requerido: true, maxLength: 100 },
  { nombre: 'direccion', etiqueta: 'Dirección', requerido: true, maxLength: 200 },
  {
    nombre: 'departamento', etiqueta: 'Departamento', tipo: 'select', requerido: true,
    opciones: DEPARTAMENTOS.map((d) => ({ valor: d, texto: d })),
  },
]

export default function Complejos() {
  const { datos: complejos, error: errorCarga, recargar } = useDatos('/complejos')
  const [editando, setEditando] = useState(null) // complejo que se está editando; null = alta
  const [error, setError] = useState('')

  // Si el backend rechaza algo, el error lo muestra el formulario
  async function guardar(valores) {
    if (editando) {
      await api(`/complejos/${editando.id_complejo}`, { method: 'PUT', body: valores })
    } else {
      await api('/complejos', { method: 'POST', body: valores })
    }
    setEditando(null)
    recargar()
  }

  async function borrar(complejo) {
    if (!confirm(`¿Borrar el complejo ${complejo.nombre}?`)) return
    setError('')
    try {
      await api(`/complejos/${complejo.id_complejo}`, { method: 'DELETE' })
      recargar()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <>
      <h2>Complejos deportivos</h2>

      <Formulario
        key={editando?.id_complejo ?? 'alta'}
        campos={CAMPOS}
        inicial={editando}
        onGuardar={guardar}
        onCancelar={() => setEditando(null)}
        textoAlta="Agregar complejo"
      />

      {(errorCarga || error) && <p className="error">{errorCarga || error}</p>}
      <Tabla
        columnas={[
          { campo: 'nombre', titulo: 'Nombre' },
          { campo: 'direccion', titulo: 'Dirección' },
          { campo: 'departamento', titulo: 'Departamento' },
        ]}
        filas={complejos}
        acciones={(complejo) => (
          <>
            <button className="secondary" onClick={() => setEditando(complejo)}>
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
