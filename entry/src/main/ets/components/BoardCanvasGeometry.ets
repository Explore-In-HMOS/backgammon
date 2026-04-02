import { Point } from '../model/GameTypes'
import { BoardCanvasContext } from './BoardCanvasTypes'

export function fillBoardCanvasRoundRect(
  self: BoardCanvasContext,
  x: number,
  y: number,
  w: number,
  h: number,
  r: number
): void {
  const c = self.ctx
  c.beginPath()
  c.moveTo(x + r, y)
  c.lineTo(x + w - r, y)
  c.arcTo(x + w, y, x + w, y + r, r)
  c.lineTo(x + w, y + h - r)
  c.arcTo(x + w, y + h, x + w - r, y + h, r)
  c.lineTo(x + r, y + h)
  c.arcTo(x, y + h, x, y + h - r, r)
  c.lineTo(x, y + r)
  c.arcTo(x, y, x + r, y, r)
  c.closePath()
  c.fill()
}

export function computeBoardCanvasLayout(self: BoardCanvasContext): void {
  self.pad = 6
  self.hPad = self.pad + Math.floor(self.cw * 0.09)
  self.trayH = 7
  self.boardTop = self.pad + self.trayH + 4
  self.boardBot = self.ch - self.pad - self.trayH - 2
  const innerH: number = self.boardBot - self.boardTop
  const innerW: number = self.cw - 2 * self.hPad
  self.barW = Math.floor(innerW / 14)
  self.ptW = Math.floor((innerW - self.barW) / 12)
  self.halfH = Math.floor(innerH / 2) - 2
  self.checkerR = Math.min(Math.floor(self.ptW / 2) - 1, 13)
}

export function getBoardCanvasPointX(self: BoardCanvasContext, col: number): number {
  return self.hPad + (col < 6 ? col * self.ptW : col * self.ptW + self.barW)
}

export function getBoardCanvasCheckerCenter(
  self: BoardCanvasContext,
  pointIndex: number,
  stackPos: number
): Point {
  const isTop: boolean = pointIndex >= 12
  const col: number = isTop ? pointIndex - 12 : 11 - pointIndex
  const cx: number = self.getPointX(col) + self.ptW / 2
  const spacing: number = Math.min(self.checkerR * 1.85, (self.halfH - self.checkerR) / 4.2)
  const cy: number = isTop
    ? self.boardTop + self.checkerR + stackPos * spacing
    : self.boardBot - self.checkerR - stackPos * spacing
  return { x: cx, y: cy }
}

export function getBoardCanvasBarCenter(self: BoardCanvasContext, isWhite: boolean): Point {
  const bx: number = self.hPad + 6 * self.ptW + self.barW / 2
  const by: number = isWhite
    ? self.boardTop + self.halfH / 2
    : self.boardTop + self.halfH + self.halfH / 2
  return { x: bx, y: by }
}

export function handleBoardCanvasTap(self: BoardCanvasContext, tx: number, ty: number): void {
  const relX: number = tx - self.hPad
  const relY: number = ty

  if (tx >= self.cw - self.hPad && relY >= self.boardTop && relY <= self.boardBot) {
    self.onPointTap(-1)
    return
  }

  if (relY < self.boardTop || relY > self.boardBot) {
    return
  }

  const barStart: number = 6 * self.ptW
  const barEnd: number = barStart + self.barW
  if (relX >= barStart && relX <= barEnd) {
    self.onBarTap(relY < (self.boardTop + self.boardBot) / 2 ? 1 : -1)
    return
  }

  let col: number
  if (relX < barStart) {
    col = Math.floor(relX / self.ptW)
  } else {
    col = Math.floor((relX - self.barW) / self.ptW)
  }

  if (col < 0 || col > 11) {
    return
  }

  const isTop: boolean = relY < (self.boardTop + self.boardBot) / 2
  self.onPointTap(isTop ? 12 + col : 11 - col)
}
