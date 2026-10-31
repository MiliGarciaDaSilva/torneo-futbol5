import { createContext, useContext, useState } from 'react'
import { api } from './api'

export const ADMIN = 'administrador'
export const PLANILLERO = 'planillero'

const AuthContext = createContext(null)

function leerUsuario() {
  try {
    return JSON.parse(localStorage.getItem('usuario'))
  } catch {
    return null
  }
}

// Guarda quién está logueado ({ correo, rol }) y el token, y los mantiene si se recarga la página
export function AuthProvider({ children }) {
  const [usuario, setUsuario] = useState(leerUsuario)

  async function login(correo, contrasena) {
    const datos = await api('/auth/login', { method: 'POST', body: { correo, contrasena } })
    const nuevo = { correo: datos.correo, rol: datos.rol }
    localStorage.setItem('token', datos.token)
    localStorage.setItem('usuario', JSON.stringify(nuevo))
    setUsuario(nuevo)
  }

  function logout() {
    localStorage.removeItem('token')
    localStorage.removeItem('usuario')
    setUsuario(null)
  }

  return <AuthContext.Provider value={{ usuario, login, logout }}>{children}</AuthContext.Provider>
}

// eslint-disable-next-line react/only-export-components
export function useAuth() {
  return useContext(AuthContext)
}
