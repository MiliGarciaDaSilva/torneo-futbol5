import { Navigate, Route, Routes } from 'react-router-dom'
import { ADMIN, useAuth } from './auth.jsx'
import Layout from './components/Layout.jsx'
import Complejos from './pages/Complejos.jsx'
import Inicio from './pages/Inicio.jsx'
import Login from './pages/Login.jsx'

// Sin sesión manda al login; con un rol que no corresponde manda al inicio
function RutaProtegida({ roles, children }) {
  const { usuario } = useAuth()
  if (!usuario) return <Navigate to="/login" replace />
  if (roles && !roles.includes(usuario.rol)) return <Navigate to="/" replace />
  return children
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
        <Route
          path="complejos"
          element={
            <RutaProtegida roles={[ADMIN]}>
              <Complejos />
            </RutaProtegida>
          }
        />
        {/* Cada pantalla nueva se agrega acá y en el MENU de components/Layout.jsx */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  )
}
