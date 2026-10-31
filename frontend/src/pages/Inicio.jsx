import { ADMIN, useAuth } from '../auth.jsx'

export default function Inicio() {
  const { usuario } = useAuth()

  return (
    <>
      <h2>Bienvenido</h2>
      <p>
        Entraste como <strong>{usuario.rol}</strong>.{' '}
        {usuario.rol === ADMIN
          ? 'Podés gestionar toda la información del torneo desde el menú.'
          : 'Podés registrar las planillas, goles y tarjetas de los partidos.'}
      </p>
    </>
  )
}
