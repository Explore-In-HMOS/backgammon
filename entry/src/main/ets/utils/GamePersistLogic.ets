import { Player, GamePhase, GameResult, GameStats, WinPageParams } from '../model/GameTypes'
import { GameStateModel } from '../model/GameStateModel'
import { MoveEngine } from '../engine/MoveEngine'
import { SoundHapticManager } from './SoundHapticManager'
import { StatsManager } from './StatsManager'

export function handleGameOver(
  gs: GameStateModel,
  winner: Player,
  wOff: number,
  bOff: number
): void {
  gs.phase = GamePhase.GAME_OVER
  const loserOff: number = winner === Player.WHITE ? bOff : wOff
  const result: GameResult = MoveEngine.detectGameResult(gs.board, winner, loserOff)
  const points: number = gs.cubeValue

  if (winner === Player.WHITE) {
    gs.whiteMatchScore = Math.min(gs.whiteMatchScore + points, gs.matchLength)
    gs.whiteStreak++
    gs.blackStreak = 0
    gs.statusMsg = 'White wins!'
  } else {
    gs.blackMatchScore = Math.min(gs.blackMatchScore + points, gs.matchLength)
    gs.blackStreak++
    gs.whiteStreak = 0
    gs.statusMsg = 'Black wins!'
  }

  SoundHapticManager.playWin()
  gs.clearSavedGame()

  if (gs.ctx) {
    let stats: GameStats = StatsManager.load(gs.ctx)
    stats = StatsManager.recordResult(stats, winner, result)
    StatsManager.save(gs.ctx, stats)
  }

  const pref = gs.pref
  if (pref) {
    try {
      pref.putSync('whiteMatchScore', gs.whiteMatchScore)
      pref.putSync('blackMatchScore', gs.blackMatchScore)
      pref.flushSync()
    } catch (_e) {}
  }

  setTimeout(() => {
    const winParams: WinPageParams = {
      winner: winner as number,
      whiteMatchScore: gs.whiteMatchScore,
      blackMatchScore: gs.blackMatchScore,
      matchLength: gs.matchLength,
      gameResult: result,
      scoreMultiplier: 1,
      whiteStreak: gs.whiteStreak,
      blackStreak: gs.blackStreak
    }
    gs.cbNavigateWin(winParams)
  }, 1800)
}

export function resign(gs: GameStateModel): void {
  gs.showResignDialog = false
  const winner: Player = gs.currentPlayer === Player.WHITE ? Player.BLACK : Player.WHITE
  handleGameOver(gs, winner, gs.whiteOff, gs.blackOff)
}
