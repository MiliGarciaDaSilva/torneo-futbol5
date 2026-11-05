import { useEffect } from 'react'
import { useDatos } from '../useDatos.js'

// Desplegable de torneos para filtrar. Si todavía no hay uno elegido, elige el que está en curso (o el más nuevo).
export default function ElegirTorneo({ valor, onCambio }) {
  const { datos: torneos, error } = useDatos('/torneos')

  useEffect(() => {
    if (!valor && torneos.length > 0) {
      onCambio((torneos.find((t) => t.estado === 'en curso') ?? torneos[0]).id_torneo)
    }
  }, [valor, torneos, onCambio])

  return (
    <label className="filtro-torneo">
      Torneo
      <select value={valor ?? ''} onChange={(e) => onCambio(Number(e.target.value))}>
        {torneos.map((t) => (
          <option key={t.id_torneo} value={t.id_torneo}>
            {t.nombre} ({t.anio}-{t.semestre})
          </option>
        ))}
      </select>
      {error && <small className="error">{error}</small>}
    </label>
  )
}
