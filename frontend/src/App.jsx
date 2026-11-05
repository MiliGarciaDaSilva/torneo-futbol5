import { Navigate, Route, Routes } from 'react-router-dom'
import { ADMIN, useAuth } from './auth.jsx'
import Layout from './components/Layout.jsx'
import Complejos from './pages/Complejos.jsx'
import Equipos from './pages/Equipos.jsx'
import Inicio from './pages/Inicio.jsx'
import Jugadores from './pages/Jugadores.jsx'
import Login from './pages/Login.jsx'
import Partidos from './pages/Partidos.jsx'
import Planilla from './pages/Planilla.jsx'
import Reportes from './pages/Reportes.jsx'
import Torneos from './pages/Torneos.jsx'

// Sin sesión manda al login; con un rol que no corresponde manda al inicio
function RutaProtegida({ roles, children }) {
  const { usuario } = useAuth()
  if (!usuario) return <Navigate to="/login" replace />
  if (roles && !roles.includes(usuario.rol)) return <Navigate to="/" replace />
  return children
}

function SoloAdmin({ children }) {
  return <RutaProtegida roles={[ADMIN]}>{children}</RutaProtegida>
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        element={
          <RutaProtegida>
            <Layout />
          </RutaProtegida>
        }
      >
        <Route index element={<Inicio />} />
        <Route path="partidos" element={<Partidos />} />
        <Route path="partidos/:id/planilla" element={<Planilla />} />
        <Route path="torneos" element={<SoloAdmin><Torneos /></SoloAdmin>} />
        <Route path="equipos" element={<SoloAdmin><Equipos /></SoloAdmin>} />
        <Route path="jugadores" element={<SoloAdmin><Jugadores /></SoloAdmin>} />
        <Route path="complejos" element={<SoloAdmin><Complejos /></SoloAdmin>} />
        <Route path="reportes" element={<SoloAdmin><Reportes /></SoloAdmin>} />
        {/* Cada pantalla nueva se agrega acá y en el MENU de components/Layout.jsx */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  )
}
