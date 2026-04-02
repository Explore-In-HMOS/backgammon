import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { GameStats, EMPTY_STATS, GameResult, Player, cloneStats } from '../model/GameTypes'

export class StatsManager {

  static load(ctx: common.UIAbilityContext): GameStats {
    try {
      const p: preferences.Preferences = preferences.getPreferencesSync(ctx, { name: 'backgammon_stats' })
      return {
        gamesPlayed: p.getSync('gamesPlayed', 0) as number,
        whiteWins: p.getSync('whiteWins', 0) as number,
        blackWins: p.getSync('blackWins', 0) as number,
        gammonCount: p.getSync('gammonCount', 0) as number,
        backgammonCount: p.getSync('backgammonCount', 0) as number,
        currentStreak: p.getSync('currentStreak', 0) as number,
        longestStreak: p.getSync('longestStreak', 0) as number,
        lastWinner: p.getSync('lastWinner', 0) as number
      }
    } catch (_e) {
      return cloneStats(EMPTY_STATS)
    }
  }

  static save(ctx: common.UIAbilityContext, stats: GameStats): void {
    try {
      const p: preferences.Preferences = preferences.getPreferencesSync(ctx, { name: 'backgammon_stats' })
      p.putSync('gamesPlayed', stats.gamesPlayed)
      p.putSync('whiteWins', stats.whiteWins)
      p.putSync('blackWins', stats.blackWins)
      p.putSync('gammonCount', stats.gammonCount)
      p.putSync('backgammonCount', stats.backgammonCount)
      p.putSync('currentStreak', stats.currentStreak)
      p.putSync('longestStreak', stats.longestStreak)
      p.putSync('lastWinner', stats.lastWinner)
      p.flushSync()
    } catch (_e) {
      // ignore
    }
  }

  // Record a game result and return updated stats
  static recordResult(stats: GameStats, winner: Player, result: GameResult): GameStats {
    const updated: GameStats = cloneStats(stats)
    updated.gamesPlayed++

    if (winner === Player.WHITE) {
      updated.whiteWins++
    } else if (winner === Player.BLACK) {
      updated.blackWins++
    }

    if (result === 'gammon') {
      updated.gammonCount++
    } else if (result === 'backgammon') {
      updated.backgammonCount++
    }

    if (winner === updated.lastWinner && updated.lastWinner !== 0) {
      updated.currentStreak++
    } else {
      updated.currentStreak = 1
    }
    updated.lastWinner = winner as number

    if (updated.currentStreak > updated.longestStreak) {
      updated.longestStreak = updated.currentStreak
    }

    return updated
  }

  static reset(ctx: common.UIAbilityContext): void {
    try {
      const p: preferences.Preferences = preferences.getPreferencesSync(ctx, { name: 'backgammon_stats' })
      p.clearSync()
      p.flushSync()
    } catch (_e) {
      // ignore
    }
  }
}
