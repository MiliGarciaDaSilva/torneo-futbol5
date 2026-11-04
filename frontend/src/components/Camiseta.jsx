// Camiseta dibujada en SVG (silueta de un vector de Vecteezy, recoloreado). Los colores salen del id del equipo:
// el mismo equipo siempre tiene la misma camiseta, sin guardar nada en la base.
const JUEGOS = [
  ['#c8102e', '#ffffff'],
  ['#1f4e9c', '#f2c200'],
  ['#f2c200', '#23241f'],
  ['#ffffff', '#c8102e'],
  ['#7a1f3d', '#1f4e9c'],
  ['#2f6a3d', '#ffffff'],
]

export default function Camiseta({ idEquipo, tam = 32 }) {
  const [cuerpo, detalle] = JUEGOS[Math.abs(idEquipo - 1) % JUEGOS.length]
  const linea = { stroke: '#23241f', strokeWidth: 4, strokeLinejoin: 'round' }

  return (
    <svg viewBox="96 72 297 300" width={tam} height={tam} aria-hidden="true" className="camiseta-icono">
      <path
        fill={cuerpo}
        {...linea}
        d="M345.3,112.4c-2.3-1.4-68.5-35.2-68.5-35.2s-10.3,9.7-32.6,9.7c-22.3,0-32.6-9.7-32.6-9.7s-66.2,33.8-68.5,35.2s-43.4,91.2-43.4,91.2c5.7,4.6,44.4,21.1,44.4,21.1l25.7-58.4v194.5c0,0-0.3,5.2,74.5,5.2s74.5-5.2,74.5-5.2V166.4l25.7,58.4c0,0,38.6-16.5,44.4-21.1C388.8,203.6,347.6,113.7,345.3,112.4z"
      />
      <path
        fill={detalle}
        {...linea}
        d="M244.2,92.4c16.7,0,31.5-4.5,40.1-11.4c-4.6-2.3-7.5-3.8-7.5-3.8s-10.3,9.7-32.6,9.7c-22.3,0-32.6-9.7-32.6-9.7s-2.9,1.5-7.5,3.8C212.8,87.9,227.5,92.4,244.2,92.4z"
      />
      <path fill={detalle} {...linea} d="M101,200.8l44.5,20.8l3-6.9l-44.4-20.7C102.8,196.8,101.7,199.1,101,200.8z" />
      <path fill={detalle} {...linea} d="M343.1,221.7l44.5-20.8c-0.8-1.6-1.8-4-3.2-6.9L340,214.8L343.1,221.7z" />
    </svg>
  )
}
