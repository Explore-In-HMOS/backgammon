import { Player, GamePhase, Move, DiceState, GameStateCore, GameResult, INITIAL_BOARD } from '../model/GameTypes'
import { rollSecureDie } from '../utils/CryptoRandom'

export class MoveEngine {

  static rollDice(): DiceState {
    const d1: number = rollSecureDie()
    const d2: number = rollSecureDie()
    if (d1 === d2) {
      return { values: [d1, d1, d1, d1], used: [false, false, false, false], rolled: true }
    }
    return { values: [d1, d2], used: [false, false], rolled: true }
  }

  static rollOneDie(): number {
    return rollSecureDie()
  }

  static initialState(): GameStateCore {
    return {
      board: [...INITIAL_BOARD],
      currentPlayer: Player.WHITE,
      dice: { values: [], used: [], rolled: false },
      phase: GamePhase.FIRST_ROLL,
      whiteOff: 0,
      blackOff: 0,
      winner: Player.NONE
    }
  }

  // --- Pip count (total distance each player needs to bear off) ---
  static calculatePipCount(board: number[], player: Player): number {
    let pip: number = 0
    if (player === Player.WHITE) {
      for (let i = 0; i <= 23; i++) {
        if (board[i] > 0) {
          pip += (i + 1) * board[i]   // white needs to reach index -1 (bear off left of point 1)
        }
      }
      pip += board[24] * 25   // bar checkers have worst pip count
    } else {
      for (let i = 0; i <= 23; i++) {
        if (board[i] < 0) {
          pip += (24 - i) * (-board[i]) // black needs to reach index 24 (bear off right of point 24)
        }
      }
      pip += board[25] * 25
    }
    return pip
  }

  // --- Gammon / Backgammon detection ---
  // Call after winner is known. loserOff = how many checkers the loser has borne off.
  static detectGameResult(board: number[], winner: Player, loserOff: number): GameResult {
    if (loserOff > 0) {
      return 'normal'   // loser borne off at least one -> normal win
    }

    const loser: Player = winner === Player.WHITE ? Player.BLACK : Player.WHITE
    // Check backgammon: loser has checker in winner's home board or on bar
    if (loser === Player.BLACK) {
      // Black is loser. Winner's home (white home) = indices 0-5
      if (board[25] > 0) {
        return 'backgammon'  // black still on bar
      }
      for (let i = 0; i <= 5; i++) {
        if (board[i] < 0) {
          return 'backgammon'  // black in white's home board
        }
      }
    } else {
      // White is loser. Winner's home (black home) = indices 18-23
      if (board[24] > 0) {
        return 'backgammon'  // white still on bar
      }
      for (let i = 18; i <= 23; i++) {
        if (board[i] > 0) {
          return 'backgammon'  // white in black's home board
        }
      }
    }
    return 'gammon'  // loser has no borne off but not backgammon
  }

  // --- Bear-off checks ---
  static canBearOff(board: number[], player: Player): boolean {
    if (player === Player.WHITE) {
      if (board[24] > 0) {
        return false
      }
      for (let i = 6; i <= 23; i++) {
        if (board[i] > 0) {
          return false
        }
      }
      return true
    } else {
      if (board[25] > 0) {
        return false
      }
      for (let i = 0; i <= 17; i++) {
        if (board[i] < 0) {
          return false
        }
      }
      return true
    }
  }

  // True when all remaining valid moves are bear-off (to === -1)
  static isOnlyBearOffMoves(state: GameStateCore): boolean {
    if (!MoveEngine.canBearOff(state.board, state.currentPlayer)) {
      return false
    }
    const all: Move[] = MoveEngine.getAllValidMoves(state)
    if (all.length === 0) {
      return false
    }
    return all.every((m: Move) => m.to === -1)
  }

  static canLandOn(board: number[], point: number, player: Player): boolean {
    if (point < 0 || point > 23) {
      return false
    }
    const val: number = board[point]
    if (player === Player.WHITE) {
      return val >= -1
    }
    return val <= 1
  }

  // --- Move generation ---
  static getValidMoves(state: GameStateCore, dieIndex: number): Move[] {
    const player: Player = state.currentPlayer
    if (state.dice.used[dieIndex]) {
      return []
    }
    const dv: number = state.dice.values[dieIndex]
    const board: number[] = state.board
    const moves: Move[] = []

    const barIdx: number = player === Player.WHITE ? 24 : 25
    const hasBar: boolean = board[barIdx] > 0

    if (hasBar) {
      if (player === Player.WHITE) {
        const target: number = 24 - dv
        if (MoveEngine.canLandOn(board, target, player)) {
          moves.push({ from: 24, to: target, dieIndex })
        }
      } else {
        const target: number = dv - 1
        if (MoveEngine.canLandOn(board, target, player)) {
          moves.push({ from: 25, to: target, dieIndex })
        }
      }
      return moves
    }

    const canBO: boolean = MoveEngine.canBearOff(board, player)

    if (player === Player.WHITE) {
      for (let from = 0; from <= 23; from++) {
        if (board[from] <= 0) {
          continue
        }
        const to: number = from - dv
        if (to >= 0) {
          if (MoveEngine.canLandOn(board, to, player)) {
            moves.push({ from, to, dieIndex })
          }
        } else if (canBO) {
          if (to === -1) {
            moves.push({ from, to: -1, dieIndex })
          } else {
            let hasHigher: boolean = false
            for (let j = from + 1; j <= 5; j++) {
              if (board[j] > 0) { hasHigher = true; break }
            }
            if (!hasHigher) {
              moves.push({ from, to: -1, dieIndex })
            }
          }
        }
      }
    } else {
      for (let from = 0; from <= 23; from++) {
        if (board[from] >= 0) {
          continue
        }
        const to: number = from + dv
        if (to <= 23) {
          if (MoveEngine.canLandOn(board, to, player)) {
            moves.push({ from, to, dieIndex })
          }
        } else if (canBO) {
          if (to === 24) {
            moves.push({ from, to: -1, dieIndex })
          } else {
            let hasLower: boolean = false
            for (let j = 18; j < from; j++) {
              if (board[j] < 0) { hasLower = true; break }
            }
            if (!hasLower) {
              moves.push({ from, to: -1, dieIndex })
            }
          }
        }
      }
    }

    return moves
  }

  static getAllValidMoves(state: GameStateCore): Move[] {
    const seen: string[] = []
    const all: Move[] = []
    for (let i = 0; i < state.dice.values.length; i++) {
      const moves: Move[] = MoveEngine.getValidMoves(state, i)
      for (const m of moves) {
        const key: string = `${m.from}-${m.to}`
        if (!seen.includes(key)) { seen.push(key); all.push(m) }
      }
    }
    return all
  }

  static getValidTargets(state: GameStateCore, from: number): number[] {
    const seen: number[] = []
    const targets: number[] = []
    for (let i = 0; i < state.dice.values.length; i++) {
      if (state.dice.used[i]) {
        continue
      }
      const moves: Move[] = MoveEngine.getValidMoves(state, i)
      for (const m of moves) {
        if (m.from === from && !seen.includes(m.to)) {
          seen.push(m.to); targets.push(m.to)
        }
      }
    }
    return targets
  }

  // Returns all unique from-points that have at least one valid move
  static getSelectablePoints(state: GameStateCore): number[] {
    const seen: number[] = []
    const all: Move[] = MoveEngine.getAllValidMoves(state)
    for (const m of all) {
      if (!seen.includes(m.from)) {
        seen.push(m.from)
      }
    }
    return seen
  }

  static getMoveForFromTo(state: GameStateCore, from: number, to: number): Move | null {
    for (let i = 0; i < state.dice.values.length; i++) {
      if (state.dice.used[i]) {
        continue
      }
      const moves: Move[] = MoveEngine.getValidMoves(state, i)
      for (const m of moves) {
        if (m.from === from && m.to === to) {
          return m
        }
      }
    }
    return null
  }

  static hasAnyValidMove(state: GameStateCore): boolean {
    for (let i = 0; i < state.dice.values.length; i++) {
      if (state.dice.used[i]) {
        continue
      }
      if (MoveEngine.getValidMoves(state, i).length > 0) {
        return true
      }
    }
    return false
  }

  static allDiceUsed(state: GameStateCore): boolean {
    return state.dice.used.every((u: boolean) => u)
  }

  // Check if a move would hit an opponent blot
  static isBlotHit(board: number[], move: Move, player: Player): boolean {
    if (move.to < 0 || move.to > 23) {
      return false
    }
    return player === Player.WHITE ? board[move.to] === -1 : board[move.to] === 1
  }

  // --- Crawford rule: if one player is (matchLength-1) wins and no doubling was used yet,
  //     the crawford game disables the doubling cube for that one game only ---
  static isCrawfordSituation(whiteScore: number, blackScore: number, matchLength: number): boolean {
    return (whiteScore === matchLength - 1 || blackScore === matchLength - 1)
  }

  // --- Apply move ---
  static applyMove(state: GameStateCore, move: Move): GameStateCore {
    const board: number[] = [...state.board]
    const player: Player = state.currentPlayer

    if (move.from === 24) {
      board[24]--
    } else if (move.from === 25) {
      board[25]--
    } else {
      if (player === Player.WHITE) {
        board[move.from]--
      } else {
        board[move.from]++
      }
    }

    let whiteOff: number = state.whiteOff
    let blackOff: number = state.blackOff

    if (move.to === -1) {
      if (player === Player.WHITE) {
        whiteOff++
      } else {
        blackOff++
      }
    } else {
      // Blot hit check
      if (player === Player.WHITE && board[move.to] === -1) {
        board[move.to] = 0
        board[25]++
      } else if (player === Player.BLACK && board[move.to] === 1) {
        board[move.to] = 0
        board[24]++
      }
      if (player === Player.WHITE) {
        board[move.to]++
      } else {
        board[move.to]--
      }
    }

    const newUsed: boolean[] = [...state.dice.used]
    newUsed[move.dieIndex] = true
    const newDice: DiceState = {
      values: [...state.dice.values],
      used: newUsed,
      rolled: state.dice.rolled
    }

    let winner: Player = Player.NONE
    let phase: GamePhase = state.phase
    if (whiteOff === 15) { winner = Player.WHITE; phase = GamePhase.GAME_OVER }
    else if (blackOff === 15) { winner = Player.BLACK; phase = GamePhase.GAME_OVER }

    return { board, currentPlayer: state.currentPlayer, dice: newDice, phase, whiteOff, blackOff, winner }
  }

  static switchPlayer(state: GameStateCore): GameStateCore {
    return {
      board: [...state.board],
      currentPlayer: state.currentPlayer === Player.WHITE ? Player.BLACK : Player.WHITE,
      dice: { values: [], used: [], rolled: false },
      phase: GamePhase.ROLLING,
      whiteOff: state.whiteOff,
      blackOff: state.blackOff,
      winner: state.winner
    }
  }
}
