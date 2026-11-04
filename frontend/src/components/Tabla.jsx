// Tabla genérica para listados y reportes.
// columnas: [{ campo: 'nombre', titulo: 'Nombre' }]. Si no se pasan, usa los campos de la primera fila
// (sirve para mostrar un reporte tal cual lo devuelve la API).
// acciones: función opcional que recibe la fila y devuelve botones o links (editar, borrar, ...).
// Los números salen a la derecha y en letra monoespaciada.
// numerar: agrega la posición (1, 2, 3...) y resalta la primera fila, para tablas de posiciones y rankings.
export default function Tabla({ columnas, filas, acciones, numerar }) {
  if (filas.length === 0) return <p>Todavía no hay nada para mostrar.</p>

  const cols = columnas ?? Object.keys(filas[0]).map((campo) => ({ campo, titulo: tituloDe(campo) }))
  const esNumero = (campo) => filas.every((f) => f[campo] == null || typeof f[campo] === 'number')

  return (
    <div className="overflow-auto">
      <table className={numerar ? 'ranking' : undefined}>
        <thead>
          <tr>
            {numerar && <th className="num">#</th>}
            {cols.map((c) => (
              <th key={c.campo} className={esNumero(c.campo) ? 'num' : undefined}>
                {c.titulo}
              </th>
            ))}
            {acciones && <th />}
          </tr>
        </thead>
        <tbody>
          {filas.map((fila, i) => (
            <tr key={i}>
              {numerar && <td className="num">{i + 1}</td>}
              {cols.map((c) => (
                <td key={c.campo} className={esNumero(c.campo) ? 'num' : esFecha(fila[c.campo]) ? 'fecha' : undefined}>
                  {mostrar(fila[c.campo])}
                </td>
              ))}
              {acciones && <td>{acciones(fila)}</td>}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function esFecha(valor) {
  return typeof valor === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(valor)
}

function tituloDe(campo) {
  const texto = campo.replaceAll('_', ' ')
  return texto.charAt(0).toUpperCase() + texto.slice(1)
}

function mostrar(valor) {
  if (valor === true) return 'Sí'
  if (valor === false) return 'No'
  return String(valor ?? '')
}
