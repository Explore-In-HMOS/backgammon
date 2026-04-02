import { BoardCanvasContext, POINT_LAYOUT_COL, POINT_LAYOUT_ISTOP } from './BoardCanvasTypes'

export function drawBoardCanvasAtmosphere(self: BoardCanvasContext): void {
  drawBoardVignette(self)
  drawDecoration(self, true)
  drawDecoration(self, false)
}

export function drawBoardCanvasOverlays(self: BoardCanvasContext): void {
  if (self.crownFocusPoint >= 0) {
    drawCrownFocus(self, self.crownFocusPoint)
  }

  if (self.selectedPoint >= 0 && self.selectedPoint <= 23) {
    drawSelectionRing(self, self.selectedPoint)
  } else if (self.selectedPoint === 24 || self.selectedPoint === 25) {
    drawBarSelectionRing(self, self.selectedPoint === 24)
  }

  for (const target of self.validTargets) {
    drawTargetMark(self, target)
  }

  if (self.showPip) {
    drawPipCounts(self)
  }
  if (self.showCube) {
    drawDoublingCube(self)
  }
  if (self.animActive) {
    drawAnimatedChecker(self)
  }
}

function drawSelectionRing(self: BoardCanvasContext, pointIndex: number): void {
  const col: number = POINT_LAYOUT_COL[pointIndex]
  const isTop: boolean = POINT_LAYOUT_ISTOP[pointIndex]
  const x: number = self.getPointX(col)
  const triH: number = self.halfH - 2
  const c = self.ctx
  const cx: number = x + self.ptW / 2

  c.fillStyle = 'rgba(255, 210, 80, 0.10)'
  c.beginPath()
  if (isTop) {
    c.moveTo(x, self.boardTop)
    c.lineTo(x + self.ptW, self.boardTop)
    c.lineTo(cx, self.boardTop + triH)
  } else {
    c.moveTo(x, self.boardBot)
    c.lineTo(x + self.ptW, self.boardBot)
    c.lineTo(cx, self.boardBot - triH)
  }
  c.closePath()
  c.fill()

  c.strokeStyle = 'rgba(255, 210, 80, 0.55)'
  c.lineWidth = 1.5
  c.beginPath()
  if (isTop) {
    c.moveTo(x + 2, self.boardTop)
    c.lineTo(x + self.ptW - 2, self.boardTop)
    c.lineTo(cx, self.boardTop + triH)
  } else {
    c.moveTo(x + 2, self.boardBot)
    c.lineTo(x + self.ptW - 2, self.boardBot)
    c.lineTo(cx, self.boardBot - triH)
  }
  c.closePath()
  c.stroke()
}

function drawBarSelectionRing(self: BoardCanvasContext, isWhite: boolean): void {
  const barX: number = self.hPad + 6 * self.ptW
  const startY: number = isWhite ? self.boardTop : self.boardTop + self.halfH
  const c = self.ctx
  c.strokeStyle = '#FFD700'
  c.lineWidth = 2.5
  c.strokeRect(barX + 1, startY + 1, self.barW - 2, self.halfH - 2)
}

function drawTargetMark(self: BoardCanvasContext, pointIndex: number): void {
  const c = self.ctx
  const pulse: number = 0.5 + 0.5 * Math.sin(self.glowPhase)
  if (pointIndex === -1) {
    return
  }

  const col: number = POINT_LAYOUT_COL[pointIndex]
  const isTop: boolean = POINT_LAYOUT_ISTOP[pointIndex]
  const x: number = self.getPointX(col)
  const triH: number = self.halfH - 2
  const cx: number = x + self.ptW / 2

  c.fillStyle = '#40C870'
  c.globalAlpha = 0.18 + pulse * 0.12
  c.beginPath()
  if (isTop) {
    c.moveTo(x, self.boardTop)
    c.lineTo(x + self.ptW, self.boardTop)
    c.lineTo(cx, self.boardTop + triH)
  } else {
    c.moveTo(x, self.boardBot)
    c.lineTo(x + self.ptW, self.boardBot)
    c.lineTo(cx, self.boardBot - triH)
  }
  c.closePath()
  c.fill()
  c.globalAlpha = 1.0

  c.strokeStyle = `rgba(80, 220, 130, ${0.45 + pulse * 0.25})`
  c.lineWidth = 1.5
  c.beginPath()
  if (isTop) {
    c.moveTo(x + 1, self.boardTop)
    c.lineTo(x + self.ptW - 1, self.boardTop)
    c.lineTo(cx, self.boardTop + triH)
  } else {
    c.moveTo(x + 1, self.boardBot)
    c.lineTo(x + self.ptW - 1, self.boardBot)
    c.lineTo(cx, self.boardBot - triH)
  }
  c.closePath()
  c.stroke()

  const count: number = Math.abs(self.board[pointIndex])
  const spacing: number = Math.min(self.checkerR * 1.85, (self.halfH - self.checkerR) / 4.2)
  const landY: number = isTop
    ? self.boardTop + self.checkerR + count * spacing
    : self.boardBot - self.checkerR - count * spacing

  c.strokeStyle = '#00FF7F'
  c.lineWidth = 2.5
  c.beginPath()
  c.arc(cx, landY, self.checkerR - 1, 0, Math.PI * 2)
  c.stroke()

  c.fillStyle = '#00FF7F'
  c.globalAlpha = 0.6 + pulse * 0.4
  c.beginPath()
  c.arc(cx, landY, 4, 0, Math.PI * 2)
  c.fill()
  c.globalAlpha = 1.0
}

function drawCrownFocus(self: BoardCanvasContext, pointIndex: number): void {
  if (pointIndex < 0 || pointIndex > 25) {
    return
  }

  const col: number = POINT_LAYOUT_COL[pointIndex]
  const isTop: boolean = POINT_LAYOUT_ISTOP[pointIndex]
  const x: number = self.getPointX(col)
  const triH: number = self.halfH - 2
  const c = self.ctx

  c.strokeStyle = '#00FFFF'
  c.lineWidth = 1.5
  c.setLineDash([3, 3])
  c.beginPath()
  if (isTop) {
    c.moveTo(x + 2, self.boardTop)
    c.lineTo(x + self.ptW - 2, self.boardTop)
    c.lineTo(x + self.ptW / 2, self.boardTop + triH)
  } else {
    c.moveTo(x + 2, self.boardBot)
    c.lineTo(x + self.ptW - 2, self.boardBot)
    c.lineTo(x + self.ptW / 2, self.boardBot - triH)
  }
  c.closePath()
  c.stroke()
  c.setLineDash([])
}

function drawPipCounts(self: BoardCanvasContext): void {
  const c = self.ctx
  const th = self.resolvedTheme
  const midY: number = self.boardTop + self.halfH
  c.font = '7px sans-serif'
  c.textBaseline = 'middle'
  c.fillStyle = `${th.checkerWhite}99`
  c.textAlign = 'left'
  c.fillText(`${self.pipWhite}`, self.hPad + 2, midY - 6)
  c.fillStyle = `${th.accentColor}99`
  c.textAlign = 'right'
  c.fillText(`${self.pipBlack}`, self.cw - self.hPad - 2, midY + 6)
}

function drawDoublingCube(self: BoardCanvasContext): void {
  const bx: number = self.hPad + 6 * self.ptW + self.barW / 2
  const by: number = self.boardTop + self.halfH
  const s: number = 18
  const c = self.ctx
  c.fillStyle = '#F0F0F0'
  c.strokeStyle = '#888'
  c.lineWidth = 1
  c.fillRect(bx - s / 2, by - s / 2, s, s)
  c.strokeRect(bx - s / 2, by - s / 2, s, s)
  c.fillStyle = '#1A1A1A'
  c.font = `bold ${s * 0.55}px sans-serif`
  c.textAlign = 'center'
  c.textBaseline = 'middle'
  c.fillText(self.cubeValue.toString(), bx, by)
}

function drawAnimatedChecker(self: BoardCanvasContext): void {
  const t: number = self.animProgress
  let fromX: number = 0
  let fromY: number = 0
  let toX: number = 0
  let toY: number = 0

  if (self.animFromPoint === 24 || self.animFromPoint === 25) {
    const barCenter = self.getBarCenter(self.animFromPoint === 24)
    fromX = barCenter.x
    fromY = barCenter.y
  } else if (self.animFromPoint >= 0 && self.animFromPoint <= 23) {
    const source = self.getCheckerCenter(self.animFromPoint, 0)
    fromX = source.x
    fromY = source.y
  }

  if (self.animToPoint === -1) {
    toX = self.hPad + 16
    toY = self.animIsWhite
      ? self.boardBot + 2 + self.trayH / 2
      : self.boardTop - self.trayH / 2 - 2
  } else if (self.animToPoint === 24 || self.animToPoint === 25) {
    const barCenter = self.getBarCenter(self.animToPoint === 24)
    toX = barCenter.x
    toY = barCenter.y
  } else if (self.animToPoint >= 0) {
    const target = self.getCheckerCenter(self.animToPoint, 0)
    toX = target.x
    toY = target.y
  }

  let cx: number
  let cy: number
  if (self.animIsHit) {
    const peakX: number = (fromX + toX) / 2
    const peakY: number = Math.min(fromY, toY) - self.halfH * 0.5
    cx = (1 - t) * (1 - t) * fromX + 2 * (1 - t) * t * peakX + t * t * toX
    cy = (1 - t) * (1 - t) * fromY + 2 * (1 - t) * t * peakY + t * t * toY
  } else {
    cx = fromX + (toX - fromX) * t
    cy = fromY + (toY - fromY) * t - Math.sin(t * Math.PI) * 10
  }

  self.drawOneChecker(cx, cy, self.checkerR + 1, self.animIsWhite, true)
}

function drawBoardVignette(self: BoardCanvasContext): void {
  const c = self.ctx
  const midX: number = self.cw / 2
  const midY: number = (self.boardTop + self.boardBot) / 2
  const innerR: number = Math.min(self.cw, self.boardBot - self.boardTop) * 0.28
  const outerR: number = Math.max(self.cw, self.boardBot - self.boardTop) * 0.72
  const vignette: CanvasGradient = c.createRadialGradient(midX, midY, innerR, midX, midY, outerR)
  vignette.addColorStop(0.0, '#00000000')
  vignette.addColorStop(0.7, '#00000018')
  vignette.addColorStop(1.0, '#00000058')
  c.fillStyle = vignette
  c.fillRect(self.hPad, self.boardTop, self.cw - 2 * self.hPad, self.boardBot - self.boardTop)
}

function drawDecoration(self: BoardCanvasContext, isWhiteSide: boolean): void {
  const deco = isWhiteSide ? self.whiteDecoration : self.blackDecoration
  if (deco === 'none') {
    return
  }

  const c = self.ctx
  const x: number = self.cw - self.hPad - 22
  const midBoard: number = (self.boardTop + self.boardBot) / 2
  const y: number = isWhiteSide
    ? midBoard + self.halfH * 0.25
    : midBoard - self.halfH * 0.25 - 18
  const isTea: boolean = deco === 'tea'

  c.fillStyle = isTea ? '#C8A060' : '#5A3010'
  c.beginPath()
  c.moveTo(x + 2, y + 2)
  c.lineTo(x + 2, y + 14)
  c.quadraticCurveTo(x + 8, y + 17, x + 14, y + 14)
  c.lineTo(x + 14, y + 2)
  c.closePath()
  c.fill()

  c.strokeStyle = isTea ? '#C8A060' : '#5A3010'
  c.lineWidth = 1.5
  c.beginPath()
  c.arc(x + 16, y + 8, 4, -Math.PI / 2, Math.PI / 2)
  c.stroke()

  c.strokeStyle = '#FFFFFF44'
  c.lineWidth = 1
  for (let i = 0; i < 3; i++) {
    c.beginPath()
    c.moveTo(x + 4 + i * 4, y + 1)
    c.quadraticCurveTo(x + 6 + i * 4, y - 2, x + 4 + i * 4, y - 4)
    c.stroke()
  }
}
