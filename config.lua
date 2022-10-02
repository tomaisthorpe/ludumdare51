local config = {
  physicsDebug = false,
  fullscreen = true,

  borderColor = { 9 / 255, 18 / 255, 26 / 255 },
  windowWidth = 800,
  windowHeight = 600,

  uiSizing = {
    margin = 16,
    strokeWidth = 2,
    barPadding = 2,
    barHeight = 26,
    healthWidth = 300,
  },

  uiPalette = {
    text = { 1, 1, 1 },
    health = { 0.9, 0, 0 },
    level = { 1, 0, 1 },
  },

  gridScale = 16,
  wallWidth = 2,
  doorWidth = 3,


  enemyShootDistance = 200,
  enemyChaseDistance = {
    max = 250,
    min = 150,
  },
  enemyPathInterval = 0.5,


  wallColor = { 0.5, 0.5, 0.5 },
  doorColor = { 0.7, 0.7, 0.7 },

  generator = {
    maxRoomWidth = 40,
    maxRoomHeight = 40,
    maxRoomArea = 30 * 20,
  }
}

return config
