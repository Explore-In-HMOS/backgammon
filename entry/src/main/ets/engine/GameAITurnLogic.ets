import { GamePhase, Player, Move, GameStateCore } from '../model/GameTypes'
import { GameStateModel } from '../model/GameStateModel'
import { MoveEngine } from './MoveEngine'
import { AIEngine } from './AIEngine'
import { SoundHapticManager } from '../utils/SoundHapticManager'
import { handleGameOver } from '../utils/GamePersistLogic'
import { endTurn, startCheckerAnimation, stopAnim } from './GameMoveLogic'
import { runDiceAnimation } from './GameDiceLogic'

const ENABLE_ANIMATIONS: boolean = false

export function runAITurn(gs: GameStateModel): void {
  if (gs.phase !== GamePhase.ROLLING || gs.currentPlayer !== Player.BLACK) {
    return
  }
  gs.aiThinking = true
  gs.statusMsg = 'Black thinking...'
  SoundHapticManager.playDiceRoll()
  animateDiceRollAI(gs)
}

function animateDiceRollAI(gs: GameStateModel): void {
  const final = MoveEngine.rollDice()
  runDiceAnimation(gs, final.values, () => {
    gs.diceValues = [...final.values]
    gs.displayDiceValues = [...final.values]
    gs.diceUsed = [...final.used]
    gs.diceRolled = true
    gs.phase = GamePhase.MOVING
    setTimeout(() => { startAIMoves(gs) }, 700)
  })
}

function startAIMoves(gs: GameStateModel): void {
  const state: GameStateCore = gs.buildState()
  if (!MoveEngine.hasAnyValidMove(state)) {
    gs.statusMsg = 'Black: pass'
    SoundHapticManager.playAutoPass()
    gs.aiThinking = false
    setTimeout(() => { endTurn(gs) }, 1000)
    return
  }

  const aiMoves: Move[] = AIEngine.selectMoves(state, gs.aiLevel)
  applyAIMoves(gs, aiMoves, 0)
}

function applyAIMoves(gs: GameStateModel, moves: Move[], idx: number): void {
  if (idx >= moves.length) {
    gs.aiThinking = false
    endTurn(gs)
    return
  }

  const moveDelay: number = idx === 0 ? 100 : 380
  setTimeout(() => {
    const move: Move = moves[idx]
    const isHit: boolean = MoveEngine.isBlotHit(gs.board, move, gs.currentPlayer)

    if (!ENABLE_ANIMATIONS) {
      const s2: GameStateCore = gs.buildState()
      const n2: GameStateCore = MoveEngine.applyMove(s2, move)
      gs.applyState(n2)
      if (isHit) {
        SoundHapticManager.playBlotHit()
      } else if (move.to === -1) {
        SoundHapticManager.playBearOff()
      } else {
        SoundHapticManager.playCheckerPlace()
      }
      if (n2.phase === GamePhase.GAME_OVER) {
        gs.aiThinking = false
        handleGameOver(gs, n2.winner, n2.whiteOff, n2.blackOff)
        return
      }
      applyAIMoves(gs, moves, idx + 1)
      return
    }

    // Animated path
    startCheckerAnimation(gs, move.from, move.to, isHit, false)
    const animDelay: number = isHit ? 340 : 260
    setTimeout(() => {
      stopAnim(gs)
      gs.pendingMoveAfterAnim = null
      const s2: GameStateCore = gs.buildState()
      const n2: GameStateCore = MoveEngine.applyMove(s2, move)
      gs.applyState(n2)
      if (isHit) {
        SoundHapticManager.playBlotHit()
      } else if (move.to === -1) {
        SoundHapticManager.playBearOff()
      } else {
        SoundHapticManager.playCheckerPlace()
      }
      if (n2.phase === GamePhase.GAME_OVER) {
        gs.aiThinking = false
        handleGameOver(gs, n2.winner, n2.whiteOff, n2.blackOff)
        return
      }
      applyAIMoves(gs, moves, idx + 1)
    }, animDelay)
  }, moveDelay)
}
