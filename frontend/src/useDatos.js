import { useEffect, useState } from 'react'
import { api } from './api.js'

// Trae datos del backend y los vuelve a pedir cuando cambia la ruta.
// recargar() los pide de nuevo (después de guardar o borrar). Con ruta null no pide nada.
// Uso: const { datos: jugadores, error, recargar } = useDatos('/jugadores')
export function useDatos(ruta, inicial = []) {
  const [datos, setDatos] = useState(inicial)
  const [error, setError] = useState('')
  const [version, setVersion] = useState(0)

  useEffect(() => {
    if (!ruta) return
    let vigente = true // si la ruta cambia antes de que llegue la respuesta, la vieja se descarta
    api(ruta)
      .then((d) => {
        if (!vigente) return
        setDatos(d)
        setError('')
      })
      .catch((err) => vigente && setError(err.message))
    return () => {
      vigente = false
    }
  }, [ruta, version])

  return { datos, error, recargar: () => setVersion((v) => v + 1) }
}
