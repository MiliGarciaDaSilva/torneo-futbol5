// Datos de prueba para las rutas que el backend todavía no tiene (los usa api.js).
// Siguen el contrato de rutas acordado y los datos de sql/11_inserts.sql, pero viven en memoria:
// al recargar la página vuelven a estar como acá. Antes de entregar se borra este archivo.

const FACULTADES = [
  'Ingeniería y Tecnologías', 'Ciencias Empresariales', 'Derecho',
  'Psicología', 'Ciencias de la Salud', 'Ciencias Humanas',
].map((nombre, i) => ({ id_facultad: i + 1, nombre }))

const db = {
  facultades: FACULTADES,
  turnos: [18, 19, 20, 21, 22].map((h, i) => ({ id_turno: i + 1, hora_inicio: `${h}:00`, hora_fin: `${h + 1}:00` })),
  complejos: [
    { id_complejo: 1, nombre: 'Malvín 5', direccion: 'Alejandro Gallinal 2111', departamento: 'Montevideo' },
    { id_complejo: 2, nombre: 'El Clásico Fútbol 5', direccion: 'Alejandro Gallinal 2014', departamento: 'Montevideo' },
  ],
  canchas: [
    { nombre_cancha: 'Camp Nou', id_complejo: 1, superficie: 'sintetico', techada: true },
    { nombre_cancha: 'Gran Parque Central', id_complejo: 1, superficie: 'sintetico', techada: false },
    { nombre_cancha: 'Camp Nou', id_complejo: 2, superficie: 'parquet', techada: true },
    { nombre_cancha: 'Gran Parque Central', id_complejo: 2, superficie: 'sintetico', techada: true },
  ],
  torneos: [
    { id_torneo: 1, nombre: 'Torneo Interfacultades de Fútbol 5', anio: 2026, semestre: 2,
      fecha_inicio: '2026-09-07', fecha_fin: '2026-11-27', estado: 'en curso' },
  ],
  jugadores: [
    ['45000001', 'Cristiano', 'Ronaldo', '2003-03-13', 1, 'grado'],
    ['45000038', 'Luka', 'Modric', '1998-02-27', 1, 'grado'],
    ['45000075', 'Vinicius', 'Junior', '1999-06-19', 1, 'grado'],
    ['45000112', 'Toni', 'Kroos', '1998-09-07', 1, 'grado'],
    ['45000149', 'Sergio', 'Ramos', '1993-02-14', 1, 'posgrado'],
    ['45000186', 'Zinedine', 'Zidane', '1986-02-08', 1, 'docente'],
    ['45000223', 'Iker', 'Casillas', '1981-09-14', 1, 'funcionario'],
    ['45005037', 'Wayne', 'Rooney', '2005-07-02', 5, 'grado'],
    ['45005074', 'Steven', 'Gerrard', '1999-09-19', 5, 'grado'],
    ['45005111', 'Frank', 'Lampard', '2003-06-23', 5, 'grado'],
    ['45005148', 'David', 'Beckham', '2003-10-16', 5, 'grado'],
    ['45005185', 'Paul', 'Scholes', '2005-01-20', 5, 'grado'],
    ['45005222', 'Rio', 'Ferdinand', '1990-11-07', 5, 'docente'],
  ].map(([ci, nombre, apellido, fecha_nacimiento, id_facultad, tipo]) => ({
    ci, nombre, apellido, fecha_nacimiento, id_facultad, tipo,
    email: `${nombre}.${apellido}@ucu.edu.uy`.toLowerCase(),
  })),
  equipos: [
    { id_equipo: 1, nombre: 'Ingecapos', id_torneo: 1, id_facultad: 1, ci_capitan: '45000001' },
    { id_equipo: 5, nombre: 'Manchester Perifar', id_torneo: 1, id_facultad: 5, ci_capitan: '45005037' },
  ],
  plantel: [
    ...['45000001', '45000038', '45000075', '45000112', '45000149', '45000186']
      .map((ci, i) => ({ id_equipo: 1, ci_jugador: ci, numero_camiseta: i + 1 })),
    ...['45005037', '45005074', '45005111', '45005148', '45005185', '45005222']
      .map((ci, i) => ({ id_equipo: 5, ci_jugador: ci, numero_camiseta: i + 1 })),
  ],
  partidos: [
    { id_partido: 10, id_torneo: 1, numero_fecha: 4, id_equipo_local: 1, id_equipo_visitante: 5,
      dia: ayer(), id_turno: 1, nombre_cancha: 'Camp Nou', id_complejo: 1, estado: 'jugado' },
    { id_partido: 13, id_torneo: 1, numero_fecha: 5, id_equipo_local: 5, id_equipo_visitante: 1,
      dia: '2026-11-11', id_turno: 2, nombre_cancha: 'Camp Nou', id_complejo: 2, estado: 'programado' },
  ],
  planilla: [], // { id_partido, ci_jugador, id_equipo }
  goles: [], // { id_gol, id_partido, ci_jugador, minuto, autogol }
  tarjetas: [], // { id_tarjeta, id_partido, ci_jugador, minuto, color }
  sanciones: [
    { id_sancion: 1, ci_jugador: '45000149', id_torneo: 1, motivo: 'roja', numero_fecha_inicio: 4,
      cantidad_fechas: 1, id_tarjeta: null },
  ],
}

const REPORTES = {
  posiciones: [
    { equipo: 'Manchester Perifar', pj: 3, pg: 3, pe: 0, pp: 0, gf: 9, gc: 2, dg: 7, puntos: 9 },
    { equipo: 'Ingecapos', pj: 3, pg: 1, pe: 1, pp: 1, gf: 5, gc: 5, dg: 0, puntos: 4 },
  ],
  goleadores: [
    { nombre: 'Wayne', apellido: 'Rooney', equipo: 'Manchester Perifar', goles: 4 },
    { nombre: 'Cristiano', apellido: 'Ronaldo', equipo: 'Ingecapos', goles: 3 },
  ],
  'fair-play': [
    { equipo: 'Manchester Perifar', amarillas: 1, rojas: 0, puntos: 1 },
    { equipo: 'Ingecapos', amarillas: 2, rojas: 1, puntos: 5 },
  ],
  estados: [
    { estado: 'jugado', cantidad: 10, porcentaje: 62.5 },
    { estado: 'programado', cantidad: 5, porcentaje: 31.25 },
    { estado: 'postergado', cantidad: 1, porcentaje: 6.25 },
  ],
}

const RUTAS = [
  ['POST', '/auth/login', (_, __, b) => ({
    token: 'prueba', correo: b.correo, rol: b.correo.startsWith('planillero') ? 'planillero' : 'administrador',
  })],
  ['GET', '/facultades', () => db.facultades],
  ['GET', '/turnos', () => db.turnos],
  ...abm('/complejos', 'complejos', 'id_complejo'),
  ...abm('/torneos', 'torneos', 'id_torneo', { estado: 'inscripcion' }),
  ['PATCH', '/torneos/:id/estado', (p, _, b) => Object.assign(buscar('torneos', 'id_torneo', p.id), b)],
  ...abm('/jugadores', 'jugadores', 'ci', {}, (j) => ({ ...j, facultad: nombreFacultad(j.id_facultad) })),
  ...abm('/equipos', 'equipos', 'id_equipo', {}, conDatosDeEquipo),
  ['GET', '/equipos/:id/plantel', (p) => plantelDe(Number(p.id))],
  ['POST', '/equipos/:id/plantel', (p, _, b) => {
    db.plantel.push({ id_equipo: Number(p.id), ...b })
    return plantelDe(Number(p.id))
  }],
  ['DELETE', '/equipos/:id/plantel/:ci', (p) => {
    db.plantel = db.plantel.filter((x) => !(x.id_equipo === Number(p.id) && x.ci_jugador === p.ci))
    return null
  }],
  ['GET', '/canchas', (_, q) => db.canchas
    .filter((c) => !q.id_complejo || c.id_complejo === Number(q.id_complejo))
    .map((c) => ({ ...c, complejo: buscar('complejos', 'id_complejo', c.id_complejo).nombre }))],
  ['POST', '/canchas', (_, __, b) => (db.canchas.push(b), b)],
  ['PUT', '/canchas/:complejo/:nombre', (p, _, b) => Object.assign(buscarCancha(p), b)],
  ['DELETE', '/canchas/:complejo/:nombre', (p) => {
    db.canchas = db.canchas.filter((c) => c !== buscarCancha(p))
    return null
  }],
  ...abm('/sanciones', 'sanciones', 'id_sancion', { id_tarjeta: null }, (s) => {
    const j = buscar('jugadores', 'ci', s.ci_jugador)
    const e = db.plantel.find((x) => x.ci_jugador === s.ci_jugador)
    return { ...s, nombre: j?.nombre, apellido: j?.apellido,
      equipo: e && buscar('equipos', 'id_equipo', e.id_equipo).nombre }
  }),
  ['GET', '/partidos', (_, q) => db.partidos
    .filter((p) => (!q.id_torneo || p.id_torneo === Number(q.id_torneo))
      && (!q.numero_fecha || p.numero_fecha === Number(q.numero_fecha))
      && (!q.estado || p.estado === q.estado))
    .map(conDatosDePartido)],
  ['GET', '/partidos/:id', (p) => conDatosDePartido(buscar('partidos', 'id_partido', p.id))],
  ['PATCH', '/partidos/:id/estado', (p, _, b) =>
    conDatosDePartido(Object.assign(buscar('partidos', 'id_partido', p.id), b))],
  ['GET', '/partidos/:id/planilla', (p) => planillaDe(Number(p.id))],
  ['POST', '/partidos/:id/planilla', (p, _, b) => {
    const id = Number(p.id)
    const enPlantel = db.plantel.find((x) => x.ci_jugador === b.ci_jugador)
    db.planilla.push({ id_partido: id, ci_jugador: b.ci_jugador, id_equipo: enPlantel.id_equipo })
    return planillaDe(id)
  }],
  ['DELETE', '/partidos/:id/planilla/:ci', (p) => {
    const id = Number(p.id)
    db.planilla = db.planilla.filter((x) => !(x.id_partido === id && x.ci_jugador === p.ci))
    return planillaDe(id)
  }],
  ...cargaDePlanilla('goles', 'id_gol'),
  ...cargaDePlanilla('tarjetas', 'id_tarjeta'),
  ['GET', '/reportes/jugadores-por-facultad', () => db.facultades.map((f) => ({
    facultad: f.nombre, cantidad_jugadores: db.jugadores.filter((j) => j.id_facultad === f.id_facultad).length,
  }))],
  ['GET', '/reportes/:clave', (p) => REPORTES[p.clave] ?? []],
]

// Devuelve lo que respondería el backend, o undefined si no hay datos de prueba para esa ruta
export function datoDePrueba(method, ruta, body) {
  const [camino, consulta] = ruta.split('?')
  const query = Object.fromEntries(new URLSearchParams(consulta))
  for (const [m, patron, responder] of RUTAS) {
    const params = m === method && coincide(patron, camino)
    if (params) return structuredClone(responder(params, query, body) ?? null)
  }
  return undefined
}

// '/equipos/:id/plantel' contra '/equipos/5/plantel' → { id: '5' }
function coincide(patron, camino) {
  const a = patron.split('/')
  const b = camino.split('/').map(decodeURIComponent)
  if (a.length !== b.length) return null
  const params = {}
  for (let i = 0; i < a.length; i++) {
    if (a[i].startsWith(':')) params[a[i].slice(1)] = b[i]
    else if (a[i] !== b[i]) return null
  }
  return params
}

// Las 5 rutas de un ABM sobre una lista de db. extra: valores por defecto del alta; ver: agrega datos al leer
function abm(ruta, lista, clave, extra = {}, ver = (x) => x) {
  return [
    ['GET', ruta, (_, q) => db[lista]
      .filter((x) => Object.entries(q).every(([k, v]) => String(x[k]) === v))
      .map(ver)],
    ['GET', `${ruta}/:id`, (p) => ver(buscar(lista, clave, p.id))],
    ['POST', ruta, (_, __, b) => {
      const nuevo = { [clave]: Math.max(0, ...db[lista].map((x) => Number(x[clave]) || 0)) + 1, ...extra, ...b }
      db[lista].push(nuevo)
      return ver(nuevo)
    }],
    ['PUT', `${ruta}/:id`, (p, _, b) => ver(Object.assign(buscar(lista, clave, p.id), b))],
    ['DELETE', `${ruta}/:id`, (p) => {
      db[lista] = db[lista].filter((x) => String(x[clave]) !== p.id)
      return null
    }],
  ]
}

function cargaDePlanilla(lista, clave) {
  return [
    ['POST', `/partidos/:id/${lista}`, (p, _, b) => {
      const nuevo = { [clave]: Math.max(0, ...db[lista].map((x) => x[clave])) + 1, id_partido: Number(p.id), autogol: false, ...b }
      db[lista].push(nuevo)
      return planillaDe(Number(p.id))
    }],
    ['DELETE', `/partidos/:id/${lista}/:otro`, (p) => {
      db[lista] = db[lista].filter((x) => String(x[clave]) !== p.otro)
      return planillaDe(Number(p.id))
    }],
  ]
}

function buscar(lista, clave, valor) {
  return db[lista].find((x) => String(x[clave]) === String(valor))
}

function buscarCancha(p) {
  return db.canchas.find((c) => c.id_complejo === Number(p.complejo) && c.nombre_cancha === p.nombre)
}

function nombreFacultad(id) {
  return buscar('facultades', 'id_facultad', id)?.nombre
}

function plantelDe(id_equipo) {
  return db.plantel
    .filter((x) => x.id_equipo === id_equipo)
    .map((x) => {
      const j = buscar('jugadores', 'ci', x.ci_jugador)
      return { ci: j.ci, nombre: j.nombre, apellido: j.apellido, tipo: j.tipo, numero_camiseta: x.numero_camiseta }
    })
}

function conDatosDeEquipo(e) {
  const capitan = buscar('jugadores', 'ci', e.ci_capitan)
  return {
    ...e,
    torneo: buscar('torneos', 'id_torneo', e.id_torneo)?.nombre,
    facultad: nombreFacultad(e.id_facultad),
    capitan: capitan && `${capitan.nombre} ${capitan.apellido}`,
    cantidad_jugadores: plantelDe(e.id_equipo).length,
  }
}

function conDatosDePartido(p) {
  const turno = buscar('turnos', 'id_turno', p.id_turno)
  return {
    ...p,
    equipo_local: buscar('equipos', 'id_equipo', p.id_equipo_local).nombre,
    equipo_visitante: buscar('equipos', 'id_equipo', p.id_equipo_visitante).nombre,
    hora_inicio: turno.hora_inicio,
    hora_fin: turno.hora_fin,
    complejo: buscar('complejos', 'id_complejo', p.id_complejo).nombre,
  }
}

// Igual que GET /partidos/{id}/planilla del backend
function planillaDe(id_partido) {
  const partido = conDatosDePartido(buscar('partidos', 'id_partido', id_partido))
  const sancionados = db.sanciones.filter((s) => partido.numero_fecha >= s.numero_fecha_inicio
    && partido.numero_fecha < s.numero_fecha_inicio + s.cantidad_fechas)
  const enPlanilla = db.planilla.filter((x) => x.id_partido === id_partido)
  const conJugador = (x) => {
    const j = buscar('jugadores', 'ci', x.ci_jugador)
    const pp = enPlanilla.find((y) => y.ci_jugador === x.ci_jugador)
    return { ...x, nombre: j.nombre, apellido: j.apellido, id_equipo: pp?.id_equipo }
  }
  return {
    partido,
    se_puede_editar: partido.estado === 'jugado',
    equipos: [partido.id_equipo_local, partido.id_equipo_visitante].map((id) => ({
      id_equipo: id,
      nombre: buscar('equipos', 'id_equipo', id).nombre,
      jugadores: plantelDe(id).map((j) => ({
        id_equipo: id,
        ...j,
        es_capitan: buscar('equipos', 'id_equipo', id).ci_capitan === j.ci,
        suspendido: sancionados.some((s) => s.ci_jugador === j.ci),
        en_planilla: enPlanilla.some((x) => x.ci_jugador === j.ci),
      })),
    })),
    goles: db.goles.filter((g) => g.id_partido === id_partido).map(conJugador),
    tarjetas: db.tarjetas.filter((t) => t.id_partido === id_partido).map(conJugador),
  }
}

function ayer() {
  const d = new Date()
  d.setDate(d.getDate() - 1)
  return d.toLocaleDateString('sv') // AAAA-MM-DD en hora local
}
