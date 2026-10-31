// Todas las llamadas al backend pasan por acá: agrega el token y convierte los errores en un mensaje.
// Uso: const complejos = await api('/complejos')
//      await api('/complejos', { method: 'POST', body: { nombre, direccion, departamento } })
export async function api(ruta, { method = 'GET', body } = {}) {
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
  if (!respuesta.ok) throw new Error(mensajeDeError(datos))
  return datos
}

function mensajeDeError(datos) {
  const detalle = datos?.detail
  // Los errores de validación de FastAPI (422) vienen como lista, uno por campo
  if (Array.isArray(detalle)) {
    return detalle.map((e) => `${e.loc.at(-1)}: ${e.msg}`).join('. ')
  }
  return detalle ?? 'Error inesperado, probá de nuevo'
}
