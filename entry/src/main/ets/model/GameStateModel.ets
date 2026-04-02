import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import {
  Player, GamePhase, AILevel, GameMode,
  Move, GameStateCore, UndoRecord,
  INITIAL_BOARD, Decoration,
  GamePageParams, WinPageParams
} from './GameTypes'
import { MoveEngine } from '../engine/MoveEngine'
import { SoundHapticManager } from '../utils/SoundHapticManager'

@Observed
export class GameStateModel {
  // ── Game state ───────────────────────────────────────────────
  board: number[] = [...INITIAL_BOARD]
  currentPlayer: Player = Player.WHITE
  diceValues: number[] = []
  displayDiceValues: number[] = []
  diceUsed: boolean[] = []
  diceRolled: boolean = false
  phase: GamePhase = GamePhase.FIRST_ROLL
  whiteOff: number = 0
  blackOff: number = 0

  // ── Selection & valid moves ──────────────────────────────────
  selectedPoint: number = -1
  validTargets: number[] = []
  crownFocusPoint: number = -1

  // ── Pip counts ───────────────────────────────────────────────
  pipWhite: number = 0
  pipBlack: number = 0

  // ── Doubling cube ────────────────────────────────────────────
  cubeValue: number = 1
  cubeOwner: Player = Player.NONE
  cubeOffered: boolean = false

  // ── Undo ─────────────────────────────────────────────────────
  undoAvailable: boolean = false

  // ── Match & score ────────────────────────────────────────────
  whiteMatchScore: number = 0
  blackMatchScore: number = 0
  matchLength: number = 1

  // ── Game settings ────────────────────────────────────────────
  gameMode: GameMode = GameMode.VS_AI
  aiLevel: AILevel = AILevel.MEDIUM
  themeId: string = 'classic'
  whiteDecoration: Decoration = 'none'
  blackDecoration: Decoration = 'none'
  autoBearOff: boolean = true
  showPipCount: boolean = true
  enableDoubling: boolean = false

  // ── UI states ────────────────────────────────────────────────
  statusMsg: string = 'Roll to start'
  aiThinking: boolean = false
  showResignDialog: boolean = false

  // ── Animation ────────────────────────────────────────────────
  animActive: boolean = false
  animFromPoint: number = -1
  animToPoint: number = -1
  animIsHit: boolean = false
  animIsWhite: boolean = true
  animProgress: number = 0

  // ── Internal non-reactive fields ─────────────────────────────
  diceRolling: boolean = false
  animTimer: number = -1
  pendingMoveAfterAnim: Move | null = null
  undoRecord: UndoRecord | null = null
  crownSelectables: number[] = []
  crownSelectIdx: number = 0
  crownTargetIdx: number = -1
  isCrawford: boolean = false
  whiteStreak: number = 0
  blackStreak: number = 0
  pref: preferences.Preferences | null = null
  ctx: common.UIAbilityContext | null = null
  gameInited: boolean = false

  // ── Callbacks (injected by GamePage) ─────────────────────────
  cbNavigateWin: (p: WinPageParams) => void = (_p: WinPageParams) => {}
  cbNavPop: () => void = () => {}
  cbScheduleAITurn: () => void = () => {}
  cbEndTurn: () => void = () => {}

  // ── Core state helpers ───────────────────────────────────────
  buildState(): GameStateCore {
    return {
      board: [...this.board],
      currentPlayer: this.currentPlayer,
      dice: { values: [...this.diceValues], used: [...this.diceUsed], rolled: this.diceRolled },
      phase: this.phase,
      whiteOff: this.whiteOff,
      blackOff: this.blackOff,
      winner: Player.NONE
    }
  }

  applyState(s: GameStateCore): void {
    this.board = [...s.board]
    this.currentPlayer = s.currentPlayer
    this.diceValues = [...s.dice.values]
    this.displayDiceValues = [...s.dice.values]
    this.diceUsed = [...s.dice.used]
    this.diceRolled = s.dice.rolled
    this.phase = s.phase
    this.whiteOff = s.whiteOff
    this.blackOff = s.blackOff
    this.updatePipCounts()
  }

  updatePipCounts(): void {
    this.pipWhite = MoveEngine.calculatePipCount(this.board, Player.WHITE)
    this.pipBlack = MoveEngine.calculatePipCount(this.board, Player.BLACK)
  }

  // ── Game initialisation ──────────────────────────────────────
  initGame(params: GamePageParams | undefined): void {
    if (this.gameInited) {
      return
    }
    this.gameInited = true

    if (params) {
      this.whiteMatchScore = params.whiteMatchScore ?? 0
      this.blackMatchScore = params.blackMatchScore ?? 0
      this.matchLength = params.matchLength ?? 1
      this.gameMode = (params.gameMode ?? GameMode.VS_AI) as GameMode
      this.aiLevel = (params.aiLevel ?? AILevel.MEDIUM) as AILevel
      this.themeId = params.themeId ?? 'classic'
      this.whiteDecoration = (params.whiteDecoration ?? 'none') as Decoration
      this.blackDecoration = (params.blackDecoration ?? 'none') as Decoration
      this.autoBearOff = params.autoBearOff ?? true
      this.showPipCount = params.showPipCount ?? true
      this.enableDoubling = params.enableDoubling ?? false

      SoundHapticManager.configure(
        params.soundEnabled ?? true,
        params.hapticEnabled ?? true
      )

      if (params.resumeGame) {
        this.loadGameFromPrefs()
        return
      }
    }

    this.startNewGame()
  }

  startNewGame(): void {
    this.board = [...INITIAL_BOARD]
    this.currentPlayer = Player.WHITE
    this.diceValues = []
    this.displayDiceValues = []
    this.diceUsed = []
    this.diceRolled = false
    this.phase = GamePhase.FIRST_ROLL
    this.whiteOff = 0
    this.blackOff = 0
    this.selectedPoint = -1
    this.validTargets = []
    this.crownFocusPoint = -1
    this.undoRecord = null
    this.undoAvailable = false
    this.cubeValue = 1
    this.cubeOwner = Player.NONE
    this.cubeOffered = false
    this.aiThinking = false
    this.animActive = false
    this.statusMsg = 'White rolls to start'
    this.updatePipCounts()
    this.clearSavedGame()
    this.isCrawford = MoveEngine.isCrawfordSituation(this.whiteMatchScore, this.blackMatchScore, this.matchLength)
  }

  // ── Persistence (called from logic modules via model ref) ─────
  loadGameFromPrefs(): void {
    const p: preferences.Preferences | null = this.pref
    if (!p) { this.startNewGame(); return }
    try {
      const bs: string = p.getSync('savedBoard', '') as string
      if (!bs) { this.startNewGame(); return }
      this.board = JSON.parse(bs) as number[]
      this.currentPlayer = p.getSync('savedPlayer', Player.WHITE as number) as Player
      this.phase = p.getSync('savedPhase', GamePhase.ROLLING) as GamePhase
      this.whiteOff = p.getSync('savedWhiteOff', 0) as number
      this.blackOff = p.getSync('savedBlackOff', 0) as number
      this.diceValues = JSON.parse(p.getSync('savedDiceValues', '[]') as string) as number[]
      this.displayDiceValues = [...this.diceValues]
      this.diceUsed = JSON.parse(p.getSync('savedDiceUsed', '[]') as string) as boolean[]
      this.diceRolled = p.getSync('savedDiceRolled', false) as boolean
      this.whiteMatchScore = p.getSync('whiteMatchScore', 0) as number
      this.blackMatchScore = p.getSync('blackMatchScore', 0) as number
      this.selectedPoint = -1
      this.validTargets = []
      const name: string = this.currentPlayer === Player.WHITE ? 'White' : 'Black'
      this.statusMsg = this.phase === GamePhase.ROLLING ? `${name} to roll` : `${name} moving`
      this.updatePipCounts()
      this.isCrawford = MoveEngine.isCrawfordSituation(this.whiteMatchScore, this.blackMatchScore, this.matchLength)
    } catch (_e) { this.startNewGame() }
  }

  clearSavedGame(): void {
    if (!this.pref) {
      return
    }
    try { this.pref.putSync('hasSavedGame', false); this.pref.flushSync() } catch (_e) {}
  }

  saveGame(): void {
    const p = this.pref
    if (!p) {
      return
    }
    try {
      p.putSync('savedBoard', JSON.stringify(this.board))
      p.putSync('savedPlayer', this.currentPlayer as number)
      p.putSync('savedPhase', this.phase)
      p.putSync('savedWhiteOff', this.whiteOff)
      p.putSync('savedBlackOff', this.blackOff)
      p.putSync('savedDiceValues', JSON.stringify(this.diceValues))
      p.putSync('savedDiceUsed', JSON.stringify(this.diceUsed))
      p.putSync('savedDiceRolled', this.diceRolled)
      p.putSync('whiteMatchScore', this.whiteMatchScore)
      p.putSync('blackMatchScore', this.blackMatchScore)
      p.putSync('hasSavedGame', true)
      p.flushSync()
    } catch (_e) {}
  }

  refreshCrownSelectables(): void {
    this.crownSelectables = MoveEngine.getSelectablePoints(this.buildState())
    this.crownSelectIdx = 0
    this.crownTargetIdx = -1
  }
}
