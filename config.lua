local config = {
  physicsDebug = false,
  fullscreen = false,

  borderColor = { 9 / 255, 18 / 255, 26 / 255 },
  windowWidth = 800,
  windowHeight = 600,

  levelGen = {
    rooms = { 2, 8 },
    enemies = { 2, 10 },
    maxLevel = 5,
  },

  uiSizing = {
    margin = 16,
    strokeWidth = 2,
    barPadding = 2,
    barHeight = 26,
    healthWidth = 300,
  },

  uiPalette = {
    text = { 1, 1, 1 },
    gameOver = { 1, 1, 1 },
    mutedText = { 0.8, 0.8, 0.8 },
    health = { 0.9, 0, 0 },
    timeLeft = { 0.9, 0.6, 0 },
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
