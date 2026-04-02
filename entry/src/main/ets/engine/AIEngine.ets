import { Player, AILevel, Move, GameStateCore, GamePhase } from '../model/GameTypes'
import { MoveEngine } from './MoveEngine'
import { getRandomInt } from '../utils/CryptoRandom'

export class AIEngine {

  // Entry point: returns full move sequence for the AI's turn
  static selectMoves(state: GameStateCore, level: AILevel): Move[] {
    switch (level) {
      case AILevel.EASY:
        return AIEngine.selectMovesEasy(state)
      case AILevel.MEDIUM:
        return AIEngine.selectMovesMedium(state)
      default:
        return AIEngine.selectMovesHard(state)
    }
  }

  // Easy: pick random valid moves
  private static selectMovesEasy(state: GameStateCore): Move[] {
    const result: Move[] = []
    let cur: GameStateCore = {
      board: [...state.board],
      currentPlayer: state.currentPlayer,
      dice: { values: [...state.dice.values], used: [...state.dice.used], rolled: state.dice.rolled },
      phase: state.phase,
      whiteOff: state.whiteOff,
      blackOff: state.blackOff,
      winner: state.winner
    }

    for (let iter = 0; iter < 4; iter++) {
      const all: Move[] = MoveEngine.getAllValidMoves(cur)
      if (all.length === 0) {
        break
      }
      const move: Move = all[getRandomInt(all.length)]
      result.push(move)
      cur = MoveEngine.applyMove(cur, move)
      if (cur.phase === GamePhase.GAME_OVER) {
        break
      }
      if (MoveEngine.allDiceUsed(cur)) {
        break
      }
    }

    return result
  }

  // Medium: greedy — pick highest-scoring immediate move at each step
  private static selectMovesMedium(state: GameStateCore): Move[] {
    const result: Move[] = []
    let cur: GameStateCore = {
      board: [...state.board],
      currentPlayer: state.currentPlayer,
      dice: { values: [...state.dice.values], used: [...state.dice.used], rolled: state.dice.rolled },
      phase: state.phase,
      whiteOff: state.whiteOff,
      blackOff: state.blackOff,
      winner: state.winner
    }

    for (let iter = 0; iter < 4; iter++) {
      const all: Move[] = MoveEngine.getAllValidMoves(cur)
      if (all.length === 0) {
        break
      }

      let bestMove: Move = all[0]
      let bestScore: number = -999999

      for (const m of all) {
        const next: GameStateCore = MoveEngine.applyMove(cur, m)
        const score: number = AIEngine.evaluatePosition(next, cur.currentPlayer)
        if (score > bestScore) {
          bestScore = score
          bestMove = m
        }
      }

      result.push(bestMove)
      cur = MoveEngine.applyMove(cur, bestMove)
      if (cur.phase === GamePhase.GAME_OVER) {
        break
      }
      if (MoveEngine.allDiceUsed(cur)) {
        break
      }
    }

    return result
  }

  // Hard: find best full move sequence using recursive lookahead
  private static selectMovesHard(state: GameStateCore): Move[] {
    return AIEngine.findBestSequence(state, state.currentPlayer)
  }

  private static findBestSequence(state: GameStateCore, forPlayer: Player): Move[] {
    const all: Move[] = MoveEngine.getAllValidMoves(state)
    if (all.length === 0) {
      return []
    }

    let bestSeq: Move[] = []
    let bestScore: number = -999999

    for (const move of all) {
      const next: GameStateCore = MoveEngine.applyMove(state, move)
      let score: number

      if (next.phase === GamePhase.GAME_OVER) {
        score = next.winner === forPlayer ? 100000 : -100000
      } else if (MoveEngine.allDiceUsed(next)) {
        score = AIEngine.evaluatePosition(next, forPlayer)
      } else {
        const subSeq: Move[] = AIEngine.findBestSequence(next, forPlayer)
        let finalState: GameStateCore = next
        for (const sm of subSeq) {
          finalState = MoveEngine.applyMove(finalState, sm)
        }
        score = AIEngine.evaluatePosition(finalState, forPlayer)
      }

      if (score > bestScore) {
        bestScore = score
        // Rebuild sequence
        const next2: GameStateCore = MoveEngine.applyMove(state, move)
        if (!MoveEngine.allDiceUsed(next2) && next2.phase !== GamePhase.GAME_OVER) {
          bestSeq = [move, ...AIEngine.findBestSequence(next2, forPlayer)]
        } else {
          bestSeq = [move]
        }
      }
    }

    return bestSeq
  }

  static evaluatePosition(state: GameStateCore, forPlayer: Player): number {
    const b: number[] = state.board
    let score: number = 0

    if (forPlayer === Player.WHITE) {
      // Borne-off bonus
      score += state.whiteOff * 50

      let pip: number = 0
      for (let i = 0; i <= 23; i++) {
        if (b[i] > 0) {
          pip += (i + 1) * b[i]
        }
      }
      pip += b[24] * 25   // bar is worst
      score -= pip

      // Penalize blots
      for (let i = 0; i <= 23; i++) {
        if (b[i] === 1) {
          score -= 8
        }
      }
      // Bonus for making a point (2+ checkers)
      for (let i = 0; i <= 23; i++) {
        if (b[i] >= 2) {
          score += 4
        }
      }
      // Penalty for opponent blots (they can hit us back)
      for (let i = 0; i <= 23; i++) {
        if (b[i] === -1) {
          score += 3  // opponent blot nearby is good
        }
      }
      // Penalty for being on bar
      score -= b[24] * 20

    } else {
      // Black
      score += state.blackOff * 50

      let pip: number = 0
      for (let i = 0; i <= 23; i++) {
        if (b[i] < 0) {
          pip += (24 - i) * (-b[i])
        }
      }
      pip += b[25] * 25
      score -= pip

      for (let i = 0; i <= 23; i++) {
        if (b[i] === -1) {
          score -= 8
        }
      }
      for (let i = 0; i <= 23; i++) {
        if (b[i] <= -2) {
          score += 4
        }
      }
      for (let i = 0; i <= 23; i++) {
        if (b[i] === 1) {
          score += 3
        }
      }
      score -= b[25] * 20
    }

    return score
  }
}
