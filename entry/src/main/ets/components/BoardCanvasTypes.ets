import { ThemeConfig, Decoration, Point } from '../model/GameTypes'

export const POINT_LAYOUT_COL: number[] = [
  11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0,
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
]

export const POINT_LAYOUT_ISTOP: boolean[] = [
  false, false, false, false, false, false, false, false, false, false, false, false,
  true, true, true, true, true, true, true, true, true, true, true, true
]

export interface BoardCanvasContext {
  board: number[]
  selectedPoint: number
  validTargets: number[]
  whiteOff: number
  blackOff: number
  cubeValue: number
  showCube: boolean
  pipWhite: number
  pipBlack: number
  showPip: boolean
  animActive: boolean
  animFromPoint: number
  animToPoint: number
  animIsHit: boolean
  animIsWhite: boolean
  animProgress: number
  whiteDecoration: Decoration
  blackDecoration: Decoration
  crownFocusPoint: number
  currentPlayer: number
  ctx: CanvasRenderingContext2D
  cw: number
  ch: number
  pad: number
  hPad: number
  trayH: number
  barW: number
  ptW: number
  boardTop: number
  boardBot: number
  halfH: number
  checkerR: number
  resolvedTheme: ThemeConfig
  glowPhase: number
  onPointTap: (point: number) => void
  onBarTap: (playerSign: number) => void
  fillRoundRect: (x: number, y: number, w: number, h: number, r: number) => void
  getPointX: (col: number) => number
  getCheckerCenter: (pointIndex: number, stackPos: number) => Point
  getBarCenter: (isWhite: boolean) => Point
  drawOneChecker: (cx: number, cy: number, r: number, isWhite: boolean, glow: boolean) => void
}
