import { Link } from 'react-router-dom'
import { ADMIN, useAuth } from '../auth.jsx'

export default function Inicio() {
  const { usuario } = useAuth()

  return (
    <>
      <h2>Inicio</h2>
      <p>
        Entraste como {usuario.rol}.{' '}
        {usuario.rol === ADMIN
          ? 'Desde el menú podés gestionar todo el torneo.'
          : 'Podés registrar las planillas, los goles y las tarjetas de los partidos.'}
      </p>
      <p>
        <Link to="/partidos">Ver los partidos</Link>
      </p>
    </>
  )
}
