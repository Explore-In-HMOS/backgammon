import { BoardCanvasContext, POINT_LAYOUT_COL, POINT_LAYOUT_ISTOP } from './BoardCanvasTypes'

export function drawBoardCanvasFrame(self: BoardCanvasContext): void {
  drawBearOffTray(self, true)
  drawBearOffTray(self, false)

  const c = self.ctx
  const th = self.resolvedTheme
  c.fillStyle = th.frameColor
  self.fillRoundRect(
    self.hPad - 3,
    self.boardTop - 3,
    self.cw - 2 * (self.hPad - 3),
    self.boardBot - self.boardTop + 6,
    6
  )

  c.fillStyle = th.boardColor
  self.fillRoundRect(
    self.hPad,
    self.boardTop,
    self.cw - 2 * self.hPad,
    self.boardBot - self.boardTop,
    4
  )

  for (let i = 0; i < 24; i++) {
    drawTriangle(self, i)
  }

  const barX: number = self.hPad + 6 * self.ptW
  c.fillStyle = th.barColor
  c.fillRect(barX, self.boardTop, self.barW, self.boardBot - self.boardTop)
  c.strokeStyle = `${th.accentColor}44`
  c.lineWidth = 1
  c.beginPath()
  c.moveTo(barX + self.barW / 2, self.boardTop + 8)
  c.lineTo(barX + self.barW / 2, self.boardBot - 8)
  c.stroke()
}

export function drawBoardCanvasPieces(self: BoardCanvasContext): void {
  for (let i = 0; i < 24; i++) {
    drawCheckersAt(self, i)
  }
  drawBarCheckers(self)
  drawPlayerIndicator(self)
}

function drawPlayerIndicator(self: BoardCanvasContext): void {
  const c = self.ctx
  const th = self.resolvedTheme
  const midY: number = (self.boardTop + self.boardBot) / 2
  const cx: number = self.hPad / 2
  const isWhiteTurn: boolean = self.currentPlayer === 1
  const r: number = 7
  const totalH: number = 20

  c.beginPath()
  if (isWhiteTurn) {
    const capY: number = midY - totalH / 2 + r
    const tipY: number = midY + totalH / 2
    c.arc(cx, capY, r, 0, Math.PI, true)
    c.quadraticCurveTo(cx - r * 0.4, capY + (tipY - capY) * 0.8, cx, tipY)
    c.quadraticCurveTo(cx + r * 0.4, capY + (tipY - capY) * 0.8, cx + r, capY)
    c.closePath()
    c.fillStyle = th.checkerWhite
    c.fill()
    c.strokeStyle = th.checkerWhiteStroke
    c.lineWidth = 1.5
    c.stroke()
  } else {
    const capY: number = midY + totalH / 2 - r
    const tipY: number = midY - totalH / 2
    c.arc(cx, capY, r, Math.PI, 0, false)
    c.quadraticCurveTo(cx + r * 0.4, capY - (capY - tipY) * 0.8, cx, tipY)
    c.quadraticCurveTo(cx - r * 0.4, capY - (capY - tipY) * 0.8, cx - r, capY)
    c.closePath()
    c.fillStyle = '#5A3820'
    c.fill()
    c.strokeStyle = th.accentColor
    c.lineWidth = 2
    c.stroke()
  }
}

function drawTriangle(self: BoardCanvasContext, pointIndex: number): void {
  const col: number = POINT_LAYOUT_COL[pointIndex]
  const isTop: boolean = POINT_LAYOUT_ISTOP[pointIndex]
  const x: number = self.getPointX(col)
  const triH: number = self.halfH - 2
  const th = self.resolvedTheme
  const c = self.ctx
  const baseColor: string = col % 2 === 0 ? th.triColorA : th.triColorB

  c.fillStyle = baseColor
  c.globalAlpha = 0.75
  c.beginPath()
  if (isTop) {
    c.moveTo(x + 1, self.boardTop)
    c.lineTo(x + self.ptW - 1, self.boardTop)
    c.lineTo(x + self.ptW / 2, self.boardTop + triH)
  } else {
    c.moveTo(x + 1, self.boardBot)
    c.lineTo(x + self.ptW - 1, self.boardBot)
    c.lineTo(x + self.ptW / 2, self.boardBot - triH)
  }
  c.closePath()
  c.fill()
  c.globalAlpha = 1.0

  c.fillStyle = '#00000066'
  c.font = `${Math.max(8, self.checkerR - 4)}px sans-serif`
  c.textAlign = 'center'
  c.textBaseline = 'middle'
  const labelY: number = isTop ? self.boardTop + triH + 5 : self.boardBot - triH - 5
  c.fillText((pointIndex + 1).toString(), x + self.ptW / 2, labelY)
}

function drawCheckersAt(self: BoardCanvasContext, pointIndex: number): void {
  const count: number = self.board[pointIndex]
  if (count === 0) {
    return
  }

  const isWhite: boolean = count > 0
  const absCount: number = Math.abs(count)
  const visible: number = Math.min(absCount, 5)
  const skipTop: boolean = self.animActive && self.animFromPoint === pointIndex

  for (let i = 0; i < visible; i++) {
    if (skipTop && i === 0) {
      continue
    }
    const pos = self.getCheckerCenter(pointIndex, i)
    self.drawOneChecker(pos.x, pos.y, self.checkerR, isWhite, false)

    if (i === 4 && absCount > 5) {
      const c = self.ctx
      c.fillStyle = '#FFD700'
      c.font = `bold ${self.checkerR}px sans-serif`
      c.textAlign = 'center'
      c.textBaseline = 'middle'
      c.fillText(absCount.toString(), pos.x, pos.y)
    }
  }
}

function drawBarCheckers(self: BoardCanvasContext): void {
  const bx: number = self.hPad + 6 * self.ptW + self.barW / 2
  const spacing: number = Math.min(self.checkerR * 2, 22)

  const wCount: number = self.board[24]
  const skipW: boolean = self.animActive && self.animFromPoint === 24
  for (let i = 0; i < Math.min(wCount, 4); i++) {
    if (skipW && i === 0) {
      continue
    }
    const cy: number =
      self.boardTop + self.halfH / 2 - (Math.min(wCount, 4) - 1) * spacing / 2 + i * spacing
    self.drawOneChecker(bx, cy, self.checkerR, true, false)
  }

  const bCount: number = self.board[25]
  const skipB: boolean = self.animActive && self.animFromPoint === 25
  for (let i = 0; i < Math.min(bCount, 4); i++) {
    if (skipB && i === 0) {
      continue
    }
    const cy: number =
      self.boardTop + self.halfH + self.halfH / 2 - (Math.min(bCount, 4) - 1) * spacing / 2 + i * spacing
    self.drawOneChecker(bx, cy, self.checkerR, false, false)
  }
}

function drawBearOffTray(self: BoardCanvasContext, isWhite: boolean): void {
  const c = self.ctx
  const count: number = isWhite ? self.whiteOff : self.blackOff
  const trayX: number = self.hPad + 6
  const trayW: number = self.cw - 2 * self.hPad - 12
  const trayY: number = isWhite ? self.boardBot + 2 : self.boardTop - self.trayH - 2
  const y: number = trayY + self.trayH / 2
  const r: number = 3
  const gap: number = 8
  const th = self.resolvedTheme

  c.fillStyle = '#5C1A20'
  self.fillRoundRect(trayX, trayY, trayW, self.trayH, 3)

  for (let i = 0; i < count && i < 15; i++) {
    const x: number = trayX + 4 + i * gap
    c.fillStyle = isWhite ? th.checkerWhite : th.checkerBlack
    c.strokeStyle = isWhite ? th.checkerWhiteStroke : th.checkerBlackStroke
    c.lineWidth = 1
    c.beginPath()
    c.arc(x, y, r, 0, Math.PI * 2)
    c.fill()
    c.stroke()
  }

  if (count > 0) {
    c.fillStyle = isWhite ? `${th.checkerWhite}AA` : `${th.accentColor}AA`
    c.font = 'bold 8px sans-serif'
    c.textAlign = 'right'
    c.textBaseline = 'middle'
    c.fillText(`${count}/15`, trayX + trayW - 2, y)
  }
}
