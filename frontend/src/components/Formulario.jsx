import { useState } from 'react'

// Formulario genérico de alta y modificación. La validación va en atributos HTML: el navegador no deja enviar
// si falta algo o está mal escrito.
// campos: [{ nombre, etiqueta, tipo, requerido, opciones, soloAlta: _soloAlta, ...atributos }]
//   tipo: 'text' (por defecto), 'email', 'number', 'date', 'select' o 'checkbox'
//   opciones (select): [{ valor, texto }]
//   soloAlta: no se puede cambiar al editar (por ejemplo la cédula, que es la clave)
//   lo demás (maxLength, min, max, pattern, title, ...) se pasa tal cual al input
// inicial: valores de lo que se edita; sin inicial es un alta (al editar aparece el botón Cancelar → onCancelar).
// onGuardar(valores) puede tirar un error: se muestra abajo. Si sale bien, el alta queda vacía para cargar otro.
// Para pasar a editar otra fila hay que cambiarle la key al formulario: <Formulario key={id} ... />
export default function Formulario({ campos, inicial, onGuardar, onCancelar, textoAlta = 'Agregar' }) {
  const [valores, setValores] = useState(() => valoresDe(campos, inicial))
  const [error, setError] = useState('')
  const [enviando, setEnviando] = useState(false)
  const editando = Boolean(inicial)

  function cambiar(campo, e) {
    let valor = e.target.value
    if (campo.tipo === 'checkbox') valor = e.target.checked
    else if (campo.tipo === 'number') valor = valor === '' ? '' : Number(valor)
    else if (campo.tipo === 'select') {
      // El select devuelve texto: buscamos la opción para conservar el tipo (los id son números)
      valor = campo.opciones.find((o) => String(o.valor) === valor)?.valor ?? ''
    }
    setValores({ ...valores, [campo.nombre]: valor })
  }

  async function enviar(e) {
    e.preventDefault()
    setError('')
    setEnviando(true)
    try {
      await onGuardar(valores)
      if (!editando) setValores(valoresDe(campos))
    } catch (err) {
      setError(err.message)
    } finally {
      setEnviando(false)
    }
  }

  return (
    <form onSubmit={enviar}>
      <div className="campos">
        {campos.map((campo) => (
          <Campo
            key={campo.nombre}
            campo={campo}
            valor={valores[campo.nombre]}
            bloqueado={editando && campo.soloAlta}
            onChange={(e) => cambiar(campo, e)}
          />
        ))}
      </div>
      {error && <p className="error">{error}</p>}
      <button type="submit" aria-busy={enviando} disabled={enviando}>
        {editando ? 'Guardar cambios' : textoAlta}
      </button>{' '}
      {editando && (
        <button type="button" className="secondary" onClick={onCancelar}>
          Cancelar
        </button>
      )}
    </form>
  )
}

function Campo({ campo, valor, bloqueado, onChange }) {
  const { nombre, etiqueta, tipo = 'text', requerido, opciones, soloAlta: _soloAlta, ...atributos } = campo

  if (tipo === 'checkbox') {
    return (
      <label className="campo-check">
        <input type="checkbox" role="switch" name={nombre} checked={valor} disabled={bloqueado} onChange={onChange} />
        {etiqueta}
      </label>
    )
  }

  if (tipo === 'select') {
    return (
      <label>
        {etiqueta}
        <select name={nombre} required={requerido} disabled={bloqueado} value={valor} onChange={onChange}>
          <option value="" disabled>
            Elegí uno
          </option>
          {opciones.map((o) => (
            <option key={o.valor} value={o.valor}>
              {o.texto}
            </option>
          ))}
        </select>
      </label>
    )
  }

  return (
    <label>
      {etiqueta}
      <input
        type={tipo}
        name={nombre}
        required={requerido}
        disabled={bloqueado}
        value={valor}
        onChange={onChange}
        {...atributos}
      />
    </label>
  )
}

// Solo los campos del formulario (la fila puede traer más, como el nombre de la facultad), vacíos si no hay fila
function valoresDe(campos, fila) {
  return Object.fromEntries(
    campos.map((c) => [c.nombre, fila?.[c.nombre] ?? (c.tipo === 'checkbox' ? false : '')]),
  )
}
