import { Player, GamePhase } from '../model/GameTypes'
import { GameStateModel } from '../model/GameStateModel'
import { SoundHapticManager } from '../utils/SoundHapticManager'
import { handleGameOver } from '../utils/GamePersistLogic'

export function offerDouble(gs: GameStateModel): void {
  if (gs.isCrawford || !gs.enableDoubling) {
    return
  }
  if (gs.cubeOwner !== Player.NONE && gs.cubeOwner !== gs.currentPlayer) {
    return
  }
  gs.cubeOffered = true
  gs.phase = GamePhase.DOUBLING
  SoundHapticManager.playDoublingOffer()
  gs.statusMsg = 'Double offered!'
}

export function acceptDouble(gs: GameStateModel): void {
  gs.cubeValue *= 2
  gs.cubeOwner = gs.currentPlayer === Player.WHITE ? Player.BLACK : Player.WHITE
  gs.cubeOffered = false
  gs.phase = GamePhase.ROLLING
  gs.statusMsg = 'Double accepted'
}

export function declineDouble(gs: GameStateModel): void {
  const loser: Player = gs.currentPlayer === Player.WHITE ? Player.BLACK : Player.WHITE
  const winner: Player = gs.currentPlayer
  gs.cubeOffered = false
  gs.phase = GamePhase.GAME_OVER
  gs.statusMsg = `${loser === Player.WHITE ? 'White' : 'Black'} declined — loses`
  setTimeout(() => {
    handleGameOver(gs, winner, gs.whiteOff, gs.blackOff)
  }, 1000)
}
