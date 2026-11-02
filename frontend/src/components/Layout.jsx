import { NavLink, Outlet } from 'react-router-dom'
import { ADMIN, PLANILLERO, useAuth } from '../auth.jsx'

// Opciones del menú y qué roles las ven
const MENU = [
  { ruta: '/', texto: 'Inicio', roles: [ADMIN, PLANILLERO] },
  { ruta: '/torneos', texto: 'Torneos', roles: [ADMIN] },
  { ruta: '/jugadores', texto: 'Jugadores', roles: [ADMIN] },
  { ruta: '/complejos', texto: 'Complejos', roles: [ADMIN] },
  { ruta: '/reportes', texto: 'Reportes', roles: [ADMIN] },
]

export default function Layout() {
  const { usuario, logout } = useAuth()

  return (
    <>
      <header className="container">
        <nav>
          <ul>
            <li>
              <strong>Torneo Fútbol 5</strong>
            </li>
          </ul>
          <ul>
            {MENU.filter((opcion) => opcion.roles.includes(usuario.rol)).map((opcion) => (
              <li key={opcion.ruta}>
                <NavLink to={opcion.ruta} end>
                  {opcion.texto}
                </NavLink>
              </li>
            ))}
            <li>
              <small>{usuario.correo}</small>
            </li>
            <li>
              <button className="secondary outline" onClick={logout}>
                Salir
              </button>
            </li>
          </ul>
        </nav>
      </header>
      <main className="container">
        <Outlet />
      </main>
    </>
  )
}
