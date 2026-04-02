export enum Player {
  NONE = 0,
  WHITE = 1,
  BLACK = -1
}

export enum GamePhase {
  FIRST_ROLL = 'FIRST_ROLL',    // Initial single-die roll to determine who goes first
  ROLLING = 'ROLLING',
  MOVING = 'MOVING',
  PASS_DEVICE = 'PASS_DEVICE',  // 2P: hand device to next player
  DOUBLING = 'DOUBLING',        // Doubling cube offer pending
  GAME_OVER = 'GAME_OVER'
}

export enum AILevel {
  EASY = 'EASY',
  MEDIUM = 'MEDIUM',
  HARD = 'HARD'
}

export enum GameMode {
  VS_AI = 'VS_AI',
  TWO_PLAYER = 'TWO_PLAYER'
}

export type GameResult = 'normal' | 'gammon' | 'backgammon'

export type Decoration = 'none' | 'tea' | 'coffee'

export interface Move {
  from: number      // 0-23 = board point, 24 = white bar, 25 = black bar
  to: number        // 0-23 = board point, -1 = bear off
  dieIndex: number
}

export interface DiceState {
  values: number[]  // [d1,d2] or [d,d,d,d] for doubles
  used: boolean[]
  rolled: boolean
}

export interface DoublingCube {
  value: number     // 1,2,4,8,16,32,64
  owner: Player     // who can offer next (NONE = both can)
  offered: boolean  // pending offer awaiting accept/decline
}

export interface UndoRecord {
  board: number[]
  currentPlayer: Player
  diceValues: number[]
  diceUsed: boolean[]
  whiteOff: number
  blackOff: number
}

export interface GameStateCore {
  board: number[]       // 26: 0-23 points (+white/-black), 24=white bar, 25=black bar
  currentPlayer: Player
  dice: DiceState
  phase: GamePhase
  whiteOff: number
  blackOff: number
  winner: Player
}

export interface ThemeConfig {
  id: string
  name: string
  boardColor: string
  barColor: string
  triColorA: string        // dark triangle color
  triColorB: string        // light triangle color
  frameColor: string
  bgColor: string
  accentColor: string
  checkerWhite: string     // white checker body
  checkerBlack: string     // black checker body
  checkerWhiteStroke: string   // white checker border/rim
  checkerBlackStroke: string   // black checker border/rim
  bgColorUI: string        // outer UI background behind canvas
}

export const THEMES: ThemeConfig[] = [
  {
    // Classic: traditional board — cream background, medium brown surface, red & gold points
    id: 'classic', name: 'Classic',
    boardColor: '#7B4020',
    barColor: '#4A2010',
    triColorA: '#8C1C1C',
    triColorB: '#C8A030',
    frameColor: '#C49660',
    bgColor: '#E8D4A8',
    accentColor: '#C8A030',
    checkerWhite: '#F8F6F0',
    checkerBlack: '#180808',
    checkerWhiteStroke: '#402010',
    checkerBlackStroke: '#905030',
    bgColorUI: '#E8D4A8'
  },
  {
    // Slate: light steel-blue background, navy board, royal & powder blue points
    id: 'slate', name: 'Slate',
    boardColor: '#1E3C6A',
    barColor: '#0E2040',
    triColorA: '#1A3488',
    triColorB: '#7AAAD0',
    frameColor: '#8AAAC8',
    bgColor: '#C8D4E8',
    accentColor: '#3A80C8',
    checkerWhite: '#EEF4FC',
    checkerBlack: '#080E20',
    checkerWhiteStroke: '#3A68A0',
    checkerBlackStroke: '#204870',
    bgColorUI: '#C8D4E8'
  },
  {
    // Forest: soft sage background, deep green board, pine & lime points
    id: 'forest', name: 'Forest',
    boardColor: '#1E4A18',
    barColor: '#0E2A08',
    triColorA: '#1A5010',
    triColorB: '#88C058',
    frameColor: '#68A048',
    bgColor: '#C8D8A8',
    accentColor: '#48A028',
    checkerWhite: '#F0F8E8',
    checkerBlack: '#081408',
    checkerWhiteStroke: '#386828',
    checkerBlackStroke: '#488038',
    bgColorUI: '#C8D8A8'
  },
  {
    // Night: soft lavender background, deep purple board, violet & lilac points
    id: 'night', name: 'Night',
    boardColor: '#3A1060',
    barColor: '#200840',
    triColorA: '#5810A0',
    triColorB: '#C090E0',
    frameColor: '#9060C0',
    bgColor: '#D0C0E8',
    accentColor: '#9840D0',
    checkerWhite: '#F0E8FC',
    checkerBlack: '#100818',
    checkerWhiteStroke: '#7030B0',
    checkerBlackStroke: '#5020A0',
    bgColorUI: '#D0C0E8'
  }
]

export interface GameStats {
  gamesPlayed: number
  whiteWins: number
  blackWins: number
  gammonCount: number
  backgammonCount: number
  currentStreak: number
  longestStreak: number
  lastWinner: number
}

export const EMPTY_STATS: GameStats = {
  gamesPlayed: 0,
  whiteWins: 0,
  blackWins: 0,
  gammonCount: 0,
  backgammonCount: 0,
  currentStreak: 0,
  longestStreak: 0,
  lastWinner: 0
}

export interface AppSettings {
  soundEnabled: boolean
  hapticEnabled: boolean
  aiLevel: AILevel
  gameMode: GameMode
  matchLength: number
  whiteMatchScore: number
  blackMatchScore: number
  themeId: string
  whiteDecoration: Decoration
  blackDecoration: Decoration
  autoBearOff: boolean
  showPipCount: boolean
  enableDoubling: boolean
  tutorialDone: boolean
}

// Standard backgammon starting position
// Index 0-23 = points 1-24. Positive = white, negative = black.
export const INITIAL_BOARD: number[] = [
  -2, 0, 0, 0, 0, 5,   // points 1-6   (index 0-5)
  0, 3, 0, 0, 0,-5,   // points 7-12  (index 6-11)
  5, 0, 0, 0,-3, 0,   // points 13-18 (index 12-17)
  -5, 0, 0, 0, 0, 2,   // points 19-24 (index 18-23)
  0, 0                 // white bar (24), black bar (25)
]

export const DEFAULT_SETTINGS: AppSettings = {
  soundEnabled: true,
  hapticEnabled: true,
  aiLevel: AILevel.MEDIUM,
  gameMode: GameMode.VS_AI,
  matchLength: 1,
  whiteMatchScore: 0,
  blackMatchScore: 0,
  themeId: 'classic',
  whiteDecoration: 'none',
  blackDecoration: 'none',
  autoBearOff: true,
  showPipCount: true,
  enableDoubling: false,
  tutorialDone: false
}

export interface Point {
  x: number
  y: number
}

export function cloneSettings(s: AppSettings): AppSettings {
  return {
    soundEnabled: s.soundEnabled,
    hapticEnabled: s.hapticEnabled,
    aiLevel: s.aiLevel,
    gameMode: s.gameMode,
    matchLength: s.matchLength,
    whiteMatchScore: s.whiteMatchScore,
    blackMatchScore: s.blackMatchScore,
    themeId: s.themeId,
    whiteDecoration: s.whiteDecoration,
    blackDecoration: s.blackDecoration,
    autoBearOff: s.autoBearOff,
    showPipCount: s.showPipCount,
    enableDoubling: s.enableDoubling,
    tutorialDone: s.tutorialDone
  }
}

export interface GamePageParams {
  whiteMatchScore?: number
  blackMatchScore?: number
  matchLength?: number
  gameMode?: string
  aiLevel?: string
  themeId?: string
  whiteDecoration?: string
  blackDecoration?: string
  autoBearOff?: boolean
  showPipCount?: boolean
  enableDoubling?: boolean
  soundEnabled?: boolean
  hapticEnabled?: boolean
  resumeGame?: boolean
}

export interface WinPageParams {
  winner: number
  whiteMatchScore: number
  blackMatchScore: number
  matchLength: number
  gameResult: string
  scoreMultiplier: number
  whiteStreak: number
  blackStreak: number
}

export interface TutorialParams {
  fromSettings?: boolean
}

export function cloneStats(s: GameStats): GameStats {
  return {
    gamesPlayed: s.gamesPlayed,
    whiteWins: s.whiteWins,
    blackWins: s.blackWins,
    gammonCount: s.gammonCount,
    backgammonCount: s.backgammonCount,
    currentStreak: s.currentStreak,
    longestStreak: s.longestStreak,
    lastWinner: s.lastWinner
  }
}
