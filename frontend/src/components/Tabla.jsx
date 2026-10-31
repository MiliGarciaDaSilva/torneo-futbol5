// Tabla genérica para listados y reportes.
// columnas: [{ campo: 'nombre', titulo: 'Nombre' }]. Si no se pasan, usa los campos de la primera fila
// (sirve para mostrar un reporte tal cual lo devuelve la API).
// acciones: función opcional que recibe la fila y devuelve botones (editar, borrar, ...).
export default function Tabla({ columnas, filas, acciones }) {
  if (filas.length === 0) return <p>No hay datos para mostrar.</p>

  const cols = columnas ?? Object.keys(filas[0]).map((campo) => ({ campo, titulo: campo }))

  return (
    <div className="overflow-auto">
      <table className="striped">
        <thead>
          <tr>
            {cols.map((c) => (
              <th key={c.campo}>{c.titulo}</th>
            ))}
            {acciones && <th />}
          </tr>
        </thead>
        <tbody>
          {filas.map((fila, i) => (
            <tr key={i}>
              {cols.map((c) => (
                <td key={c.campo}>{String(fila[c.campo] ?? '')}</td>
              ))}
              {acciones && <td>{acciones(fila)}</td>}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
