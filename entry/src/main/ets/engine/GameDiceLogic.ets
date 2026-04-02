import { Player, GamePhase, DiceState } from '../model/GameTypes'
import { GameStateModel } from '../model/GameStateModel'
import { MoveEngine } from './MoveEngine'
import { SoundHapticManager } from '../utils/SoundHapticManager'
import { rollSecureDie } from '../utils/CryptoRandom'

const ENABLE_ANIMATIONS: boolean = false

export function doFirstRoll(gs: GameStateModel): void {
  if (gs.aiThinking || gs.phase !== GamePhase.FIRST_ROLL) {
    return
  }
  SoundHapticManager.playDiceRoll()
  const final: DiceState = MoveEngine.rollDice()
  runDiceAnimation(gs, final.values, () => {
    gs.diceValues = [...final.values]
    gs.diceUsed = [...final.used]
    gs.diceRolled = true
    gs.currentPlayer = Player.WHITE
    gs.phase = GamePhase.MOVING
    gs.statusMsg = 'White moves'
    if (!MoveEngine.hasAnyValidMove(gs.buildState())) {
      setTimeout(() => { gs.cbEndTurn() }, 800)
    }
  })
}

export function rollDice(gs: GameStateModel): void {
  if (gs.phase !== GamePhase.ROLLING || gs.aiThinking) {
    return
  }
  SoundHapticManager.playDiceRoll()
  animateDiceRoll(gs)
}

export function animateDiceRoll(gs: GameStateModel): void {
  const final: DiceState = MoveEngine.rollDice()
  runDiceAnimation(gs, final.values, () => {
    gs.diceValues = [...final.values]
    gs.diceUsed = [...final.used]
    gs.diceRolled = true
    gs.phase = GamePhase.MOVING
    afterRoll(gs)
  })
}

export function runDiceAnimation(gs: GameStateModel, finalValues: number[], onDone: () => void): void {
  if (!ENABLE_ANIMATIONS) {
    gs.displayDiceValues = [...finalValues]
    gs.diceUsed = finalValues.map(() => false)
    onDone()
    return
  }
  const delays: number[] = [50, 55, 60, 68, 78, 92, 110, 135, 165, 200]
  let step: number = 0
  gs.diceRolling = true
  gs.displayDiceValues = [1, 1]
  gs.diceUsed = [false, false]
  const tick = (): void => {
    if (step >= delays.length) {
      gs.diceRolling = false
      gs.displayDiceValues = [...finalValues]
      gs.diceUsed = finalValues.map(() => false)
      onDone()
      return
    }
    gs.displayDiceValues = [
      rollSecureDie(),
      rollSecureDie()
    ]
    setTimeout(tick, delays[step++])
  }
  tick()
}

export function afterRoll(gs: GameStateModel): void {
  if (!MoveEngine.hasAnyValidMove(gs.buildState())) {
    const name: string = gs.currentPlayer === 1 ? 'White' : 'Black'
    gs.statusMsg = `${name}: pass`
    SoundHapticManager.playAutoPass()
    setTimeout(() => { gs.cbEndTurn() }, 1100)
    return
  }
  const name: string = gs.currentPlayer === 1 ? 'White' : 'Black'
  gs.statusMsg = `${name} moving`
  gs.refreshCrownSelectables()
}
