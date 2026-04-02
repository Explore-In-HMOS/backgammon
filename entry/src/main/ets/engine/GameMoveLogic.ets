import { Player, GamePhase, GameMode, Move, GameStateCore } from '../model/GameTypes'
import { GameStateModel } from '../model/GameStateModel'
import { MoveEngine } from './MoveEngine'
import { SoundHapticManager } from '../utils/SoundHapticManager'
import { handleGameOver } from '../utils/GamePersistLogic'
import { doFirstRoll, rollDice } from './GameDiceLogic'

const ENABLE_ANIMATIONS: boolean = false

// ── Selection ────────────────────────────────────────────────────

export function handlePointTap(gs: GameStateModel, pointIndex: number): void {
  if (gs.animActive) { gs.statusMsg = `wait anim p${pointIndex}`; return }
  if (gs.aiThinking) { gs.statusMsg = `wait ai p${pointIndex}`; return }
  if (gs.phase === GamePhase.FIRST_ROLL) { doFirstRoll(gs); return }
  if (gs.phase === GamePhase.ROLLING) { rollDice(gs); return }
  if (gs.phase !== GamePhase.MOVING) { return }

  if (pointIndex === -1) {
    if (gs.selectedPoint !== -1 && gs.validTargets.includes(-1)) {
      initiateMove(gs, gs.selectedPoint, -1)
    }
    return
  }

  const state: GameStateCore = gs.buildState()
  const barIdx: number = gs.currentPlayer === Player.WHITE ? 24 : 25

  if (gs.selectedPoint !== -1 && gs.validTargets.includes(pointIndex)) {
    gs.statusMsg = `move ${gs.selectedPoint}→${pointIndex}`
    initiateMove(gs, gs.selectedPoint, pointIndex)
    return
  }

  if (gs.board[barIdx] > 0) {
    gs.statusMsg = 'Exit bar first!'
    return
  }

  const val: number = gs.board[pointIndex]
  const isMine: boolean = gs.currentPlayer === Player.WHITE ? val > 0 : val < 0

  if (isMine) {
    const targets: number[] = MoveEngine.getValidTargets(state, pointIndex)
    if (targets.length === 0) {
      gs.statusMsg = `no move p${pointIndex}`
      return
    }

    if (gs.selectedPoint === pointIndex && gs.validTargets.includes(-1)) {
      initiateMove(gs, pointIndex, -1)
      return
    }

    if (targets.length === 1 && targets[0] === -1) {
      initiateMove(gs, pointIndex, -1)
      return
    }

    gs.selectedPoint = pointIndex
    gs.validTargets = [...targets]
    gs.crownFocusPoint = pointIndex
  } else {
    gs.selectedPoint = -1
    gs.validTargets = []
    gs.crownFocusPoint = -1
    gs.statusMsg = `empty p${pointIndex} v=${val}`
  }
}

export function handleBarTap(gs: GameStateModel, playerSign: number): void {
  if (gs.animActive || gs.aiThinking) {
    return
  }
  if (gs.phase === GamePhase.FIRST_ROLL) { doFirstRoll(gs); return }
  if (gs.phase !== GamePhase.MOVING) {
    return
  }

  const isWhite: boolean = playerSign === 1
  if ((isWhite && gs.currentPlayer !== Player.WHITE) ||
    (!isWhite && gs.currentPlayer !== Player.BLACK)) {
    return
  }

  const barIdx: number = isWhite ? 24 : 25
  if (gs.board[barIdx] === 0) {
    return
  }

  const state: GameStateCore = gs.buildState()
  const targets: number[] = MoveEngine.getValidTargets(state, barIdx)
  if (targets.length === 0) { gs.statusMsg = 'No bar moves'; return }
  gs.selectedPoint = barIdx
  gs.validTargets = [...targets]
}

// ── Move execution ───────────────────────────────────────────────

export function initiateMove(gs: GameStateModel, from: number, to: number): void {
  const state: GameStateCore = gs.buildState()
  const move: Move | null = MoveEngine.getMoveForFromTo(state, from, to)
  if (!move) {
    return
  }

  saveUndo(gs)

  const isHit: boolean = MoveEngine.isBlotHit(gs.board, move, gs.currentPlayer)
  const isWhite: boolean = gs.currentPlayer === Player.WHITE

  gs.pendingMoveAfterAnim = move
  startCheckerAnimation(gs, from, to, isHit, isWhite)
}

export function startCheckerAnimation(
  gs: GameStateModel,
  from: number,
  to: number,
  isHit: boolean,
  isWhite: boolean
): void {
  if (!ENABLE_ANIMATIONS) {
    applyPendingMove(gs)
    return
  }
  stopAnim(gs)
  gs.animFromPoint = from
  gs.animToPoint = to
  gs.animIsHit = isHit
  gs.animIsWhite = isWhite
  gs.animProgress = 0
  gs.animActive = true
  const totalFrames: number = isHit ? 20 : 14
  let frame: number = 0
  gs.animTimer = setInterval(() => {
    frame++
    gs.animProgress = frame / totalFrames
    if (frame >= totalFrames) {
      stopAnim(gs)
      applyPendingMove(gs)
    }
  }, 16)
}

export function stopAnim(gs: GameStateModel): void {
  if (gs.animTimer !== -1) {
    clearInterval(gs.animTimer)
    gs.animTimer = -1
  }
  gs.animActive = false
  gs.animProgress = 0
}

export function applyPendingMove(gs: GameStateModel): void {
  const move: Move | null = gs.pendingMoveAfterAnim
  gs.pendingMoveAfterAnim = null
  if (!move) {
    return
  }

  const isHit: boolean = MoveEngine.isBlotHit(gs.board, move, gs.currentPlayer)
  const state: GameStateCore = gs.buildState()
  const next: GameStateCore = MoveEngine.applyMove(state, move)
  gs.applyState(next)
  gs.selectedPoint = -1
  gs.validTargets = []
  gs.crownFocusPoint = -1

  if (isHit) {
    SoundHapticManager.playBlotHit()
  } else if (move.to === -1) {
    SoundHapticManager.playBearOff()
  } else {
    SoundHapticManager.playCheckerPlace()
  }

  if (next.phase === GamePhase.GAME_OVER) {
    handleGameOver(gs, next.winner, next.whiteOff, next.blackOff)
    return
  }

  if (gs.autoBearOff && MoveEngine.isOnlyBearOffMoves(next)) {
    setTimeout(() => { runAutoBearOff(gs) }, 400)
    return
  }

  if (MoveEngine.allDiceUsed(next)) {
    endTurn(gs); return
  }

  if (!MoveEngine.hasAnyValidMove(next)) {
    gs.statusMsg = 'Dice unused'
    setTimeout(() => { endTurn(gs) }, 900)
    return
  }

  gs.refreshCrownSelectables()
}

// ── Auto bear-off ────────────────────────────────────────────────

export function runAutoBearOff(gs: GameStateModel): void {
  const state: GameStateCore = gs.buildState()
  if (!MoveEngine.isOnlyBearOffMoves(state)) { checkTurnEnd(gs); return }
  const moves: Move[] = MoveEngine.getAllValidMoves(state)
  if (moves.length === 0) { checkTurnEnd(gs); return }

  const move: Move = moves[0]
  const isWhite: boolean = gs.currentPlayer === Player.WHITE
  gs.pendingMoveAfterAnim = move
  startCheckerAnimation(gs, move.from, move.to, false, isWhite)
}

export function checkTurnEnd(gs: GameStateModel): void {
  if (MoveEngine.allDiceUsed(gs.buildState()) || !MoveEngine.hasAnyValidMove(gs.buildState())) {
    endTurn(gs)
  }
}

// ── Turn management ──────────────────────────────────────────────

export function endTurn(gs: GameStateModel): void {
  gs.undoRecord = null
  gs.undoAvailable = false
  const state: GameStateCore = gs.buildState()
  const next: GameStateCore = MoveEngine.switchPlayer(state)
  gs.applyState(next)
  const name: string = next.currentPlayer === Player.WHITE ? 'White' : 'Black'

  if (gs.gameMode === GameMode.TWO_PLAYER) {
    gs.statusMsg = `${name}'s turn`
  } else {
    gs.statusMsg = `${name} to roll`
    gs.saveGame()
    if (next.currentPlayer === Player.BLACK) {
      gs.cbScheduleAITurn()
    }
  }
}

// ── Undo ─────────────────────────────────────────────────────────

export function saveUndo(gs: GameStateModel): void {
  gs.undoRecord = {
    board: [...gs.board],
    currentPlayer: gs.currentPlayer,
    diceValues: [...gs.diceValues],
    diceUsed: [...gs.diceUsed],
    whiteOff: gs.whiteOff,
    blackOff: gs.blackOff
  }
  gs.undoAvailable = true
}

export function undo(gs: GameStateModel): void {
  const rec = gs.undoRecord
  if (!rec) {
    return
  }
  gs.board = [...rec.board]
  gs.currentPlayer = rec.currentPlayer
  gs.diceValues = [...rec.diceValues]
  gs.displayDiceValues = [...rec.diceValues]
  gs.diceUsed = [...rec.diceUsed]
  gs.whiteOff = rec.whiteOff
  gs.blackOff = rec.blackOff
  gs.phase = GamePhase.MOVING
  gs.selectedPoint = -1
  gs.validTargets = []
  gs.crownFocusPoint = -1
  gs.undoRecord = null
  gs.undoAvailable = false
  gs.updatePipCounts()
  gs.statusMsg = 'Move undone'
}

// ── Crown rotation ───────────────────────────────────────────────

export function handleCrownRotation(gs: GameStateModel, delta: number): void {
  if (gs.phase !== GamePhase.MOVING || gs.aiThinking || gs.animActive) {
    return
  }
  SoundHapticManager.playCrownTick()

  if (gs.selectedPoint === -1) {
    if (gs.crownSelectables.length === 0) {
      return
    }
    const dir: number = delta > 0 ? 1 : -1
    gs.crownSelectIdx = (gs.crownSelectIdx + dir + gs.crownSelectables.length) % gs.crownSelectables.length
    const pt: number = gs.crownSelectables[gs.crownSelectIdx]
    gs.crownFocusPoint = pt
    const state: GameStateCore = gs.buildState()
    const targets: number[] = MoveEngine.getValidTargets(state, pt)
    gs.selectedPoint = pt
    gs.validTargets = [...targets]
  } else {
    if (gs.validTargets.length === 0) {
      return
    }
    const dir: number = delta > 0 ? 1 : -1
    gs.crownTargetIdx = (gs.crownTargetIdx + dir + gs.validTargets.length) % gs.validTargets.length
  }
}
