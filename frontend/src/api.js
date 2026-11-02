import { datoDePrueba } from './mocks.js'

// Con VITE_SIN_BACKEND=1 en frontend/.env.local se usan siempre los datos de prueba (incluso el login)
const SIN_BACKEND = import.meta.env.VITE_SIN_BACKEND === '1'

// Todas las llamadas al backend pasan por acá: agrega el token y convierte los errores en un mensaje.
// Uso: const complejos = await api('/complejos')
//      await api('/complejos', { method: 'POST', body: { nombre, direccion, departamento } })
export async function api(ruta, { method = 'GET', body } = {}) {
  if (SIN_BACKEND) {
    const prueba = datoDePrueba(method, ruta, body)
    if (prueba === undefined) throw new Error(`No hay datos de prueba para ${method} ${ruta}`)
    return prueba
  }

  const token = localStorage.getItem('token')
  const respuesta = await fetch(`/api${ruta}`, {
    method,
    headers: {
      ...(body !== undefined && { 'Content-Type': 'application/json' }),
      ...(token && { Authorization: `Bearer ${token}` }),
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  })

  if (respuesta.status === 401 && token) {
    // La sesión venció: borramos todo y volvemos al login
    localStorage.removeItem('token')
    localStorage.removeItem('usuario')
    window.location.href = '/login'
    return
  }
  if (respuesta.status === 204) return null

  const datos = await respuesta.json().catch(() => null)
  // Mientras falten rutas en el backend: si la ruta todavía no existe y hay datos de prueba, se usan esos
  if (rutaInexistente(respuesta.status, datos)) {
    const prueba = datoDePrueba(method, ruta, body)
    if (prueba !== undefined) return prueba
  }
  if (!respuesta.ok) throw new Error(mensajeDeError(datos))
  return datos
}

// FastAPI responde así cuando no tiene la ruta (no cuando la ruta existe y no encuentra el dato)
function rutaInexistente(status, datos) {
  return (status === 404 && datos?.detail === 'Not Found') || status === 405
}

function mensajeDeError(datos) {
  const detalle = datos?.detail
  // Los errores de validación de FastAPI (422) vienen como lista, uno por campo
  if (Array.isArray(detalle)) {
    return detalle.map((e) => `${e.loc.at(-1)}: ${e.msg}`).join('. ')
  }
  return detalle ?? 'Error inesperado, probá de nuevo'
}
