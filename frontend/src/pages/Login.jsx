import { useState } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../auth.jsx'

export default function Login() {
  const { usuario, login } = useAuth()
  const [correo, setCorreo] = useState('')
  const [contrasena, setContrasena] = useState('')
  const [error, setError] = useState('')
  const [enviando, setEnviando] = useState(false)

  if (usuario) return <Navigate to="/" replace />

  async function enviar(e) {
    e.preventDefault()
    setError('')
    setEnviando(true)
    try {
      await login(correo.trim(), contrasena)
    } catch (err) {
      setError(err.message)
    } finally {
      setEnviando(false)
    }
  }

  return (
    <main className="container login">
      <article>
        <h2>Torneo Interfacultades de Fútbol 5</h2>
        <form onSubmit={enviar}>
          <label>
            Correo
            <input
              type="email"
              required
              maxLength={100}
              autoComplete="username"
              value={correo}
              onChange={(e) => setCorreo(e.target.value)}
            />
          </label>
          <label>
            Contraseña
            <input
              type="password"
              required
              maxLength={100}
              autoComplete="current-password"
              value={contrasena}
              onChange={(e) => setContrasena(e.target.value)}
            />
          </label>
          {error && <p className="error">{error}</p>}
          <button type="submit" aria-busy={enviando} disabled={enviando}>
            Entrar
          </button>
        </form>
      </article>
    </main>
  )
}
