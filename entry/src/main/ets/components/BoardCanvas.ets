import { ThemeConfig, THEMES, Decoration, Point } from '../model/GameTypes'
import { BoardCanvasContext } from './BoardCanvasTypes'
import {
  fillBoardCanvasRoundRect,
  getBoardCanvasBarCenter,
  getBoardCanvasCheckerCenter,
  getBoardCanvasPointX,
  handleBoardCanvasTap
} from './BoardCanvasGeometry'
import { drawBoardCanvasFrame, drawBoardCanvasPieces } from './BoardCanvasBaseDraw'
import { drawBoardCanvasAtmosphere, drawBoardCanvasOverlays } from './BoardCanvasOverlayDraw'

@Component
export struct BoardCanvas {
  @Prop board: number[] = []
  @Prop @Watch('onSelChange') selectedPoint: number = -1
  @Prop @Watch('onSelChange') validTargets: number[] = []
  @Prop whiteOff: number = 0
  @Prop blackOff: number = 0
  @Prop cubeValue: number = 1
  @Prop showCube: boolean = false
  @Prop pipWhite: number = 0
  @Prop pipBlack: number = 0
  @Prop showPip: boolean = true
  @Prop animActive: boolean = false
  @Prop animFromPoint: number = -1
  @Prop animToPoint: number = -1
  @Prop animIsHit: boolean = false
  @Prop animIsWhite: boolean = true
  @Prop animProgress: number = 0
  @Prop themeId: string = 'classic'
  @Prop whiteDecoration: Decoration = 'none'
  @Prop blackDecoration: Decoration = 'none'
  @Prop crownFocusPoint: number = -1
  @Prop currentPlayer: number = 1

  onPointTap: (point: number) => void = () => {}
  onBarTap: (playerSign: number) => void = () => {}

  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private cw: number = 0
  private ch: number = 0
  private ready: boolean = false

  private pad: number = 5
  private hPad: number = 5
  private trayH: number = 10
  private barW: number = 30
  private ptW: number = 30
  private boardTop: number = 10
  private boardBot: number = 0
  private halfH: number = 110
  private checkerR: number = 12
  private resolvedTheme: ThemeConfig = THEMES[0]

  private glowPhase: number = 0
  private glowTimer: number = -1
  private renderTimer: number = -1

  onSelChange(): void {
    if (this.ready) {
      setTimeout(() => { this.draw() }, 10)
    }
  }

  aboutToUpdate(): void {
    if (this.ready) {
      this.draw()
    }
  }

  aboutToDisappear(): void {
    if (this.glowTimer !== -1) {
      clearInterval(this.glowTimer)
      this.glowTimer = -1
    }
    if (this.renderTimer !== -1) {
      clearInterval(this.renderTimer)
      this.renderTimer = -1
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.ready = true
        this.draw()
        if (this.renderTimer === -1) {
          this.renderTimer = setInterval(() => {
            if (this.ready) {
              this.draw()
            }
          }, 100)
        }
      })
      .onAreaChange((_old: Area, newVal: Area) => {
        this.cw = newVal.width as number
        this.ch = newVal.height as number
        if (this.ready) {
          this.draw()
        }
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Up) {
          const touch: TouchObject = event.changedTouches[0]
          this.handleTap(touch.x, touch.y)
        }
      })
  }

  private draw(): void {
    if (this.cw <= 0 || this.ch <= 0) {
      return
    }

    this.updateGlowState()
    this.resolveTheme()
    this.computeLayout()
    this.ctx.clearRect(0, 0, this.cw, this.ch)

    const canvas = this.asContext()
    drawBoardCanvasFrame(canvas)
    drawBoardCanvasAtmosphere(canvas)
    drawBoardCanvasPieces(canvas)
    drawBoardCanvasOverlays(canvas)
  }

  private updateGlowState(): void {
    if (this.validTargets.length > 0 && this.glowTimer === -1) {
      this.glowTimer = setInterval(() => {
        this.glowPhase = (this.glowPhase + 0.1) % (Math.PI * 2)
        this.draw()
      }, 40)
    } else if (this.validTargets.length === 0 && this.glowTimer !== -1) {
      clearInterval(this.glowTimer)
      this.glowTimer = -1
      this.glowPhase = 0
    }
  }

  private resolveTheme(): void {
    for (let i: number = 0; i < THEMES.length; i++) {
      if (THEMES[i].id === this.themeId) {
        this.resolvedTheme = THEMES[i]
        break
      }
    }
  }

  private fillRoundRect(x: number, y: number, w: number, h: number, r: number): void {
    fillBoardCanvasRoundRect(this.asContext(), x, y, w, h, r)
  }

  private computeLayout(): void {
    this.pad = 6
    this.hPad = this.pad + Math.floor(this.cw * 0.09)
    this.trayH = 7
    this.boardTop = this.pad + this.trayH + 4
    this.boardBot = this.ch - this.pad - this.trayH - 2
    const innerH: number = this.boardBot - this.boardTop
    const innerW: number = this.cw - 2 * this.hPad
    this.barW = Math.floor(innerW / 14)
    this.ptW = Math.floor((innerW - this.barW) / 12)
    this.halfH = Math.floor(innerH / 2) - 2
    this.checkerR = Math.min(Math.floor(this.ptW / 2) - 1, 13)
  }

  private getPointX(col: number): number {
    return getBoardCanvasPointX(this.asContext(), col)
  }

  private getCheckerCenter(pointIndex: number, stackPos: number): Point {
    return getBoardCanvasCheckerCenter(this.asContext(), pointIndex, stackPos)
  }

  private getBarCenter(isWhite: boolean): Point {
    return getBoardCanvasBarCenter(this.asContext(), isWhite)
  }

  private drawOneChecker(cx: number, cy: number, r: number, isWhite: boolean, glow: boolean): void {
    const c = this.ctx
    const th = this.resolvedTheme
    if (glow) {
      c.shadowColor = th.accentColor
      c.shadowBlur = 10
    }
    c.fillStyle = isWhite ? th.checkerWhite : th.checkerBlack
    c.beginPath()
    c.arc(cx, cy, r, 0, Math.PI * 2)
    c.fill()
    c.shadowBlur = 0
    c.strokeStyle = isWhite ? th.checkerWhiteStroke : th.checkerBlackStroke
    c.lineWidth = 1.2
    c.beginPath()
    c.arc(cx, cy, r - 0.6, 0, Math.PI * 2)
    c.stroke()
  }

  private handleTap(tx: number, ty: number): void {
    handleBoardCanvasTap(this.asContext(), tx, ty)
  }

  private asContext(): BoardCanvasContext {
    return {
      board: this.board,
      selectedPoint: this.selectedPoint,
      validTargets: this.validTargets,
      whiteOff: this.whiteOff,
      blackOff: this.blackOff,
      cubeValue: this.cubeValue,
      showCube: this.showCube,
      pipWhite: this.pipWhite,
      pipBlack: this.pipBlack,
      showPip: this.showPip,
      animActive: this.animActive,
      animFromPoint: this.animFromPoint,
      animToPoint: this.animToPoint,
      animIsHit: this.animIsHit,
      animIsWhite: this.animIsWhite,
      animProgress: this.animProgress,
      whiteDecoration: this.whiteDecoration,
      blackDecoration: this.blackDecoration,
      crownFocusPoint: this.crownFocusPoint,
      currentPlayer: this.currentPlayer,
      ctx: this.ctx,
      cw: this.cw,
      ch: this.ch,
      pad: this.pad,
      hPad: this.hPad,
      trayH: this.trayH,
      barW: this.barW,
      ptW: this.ptW,
      boardTop: this.boardTop,
      boardBot: this.boardBot,
      halfH: this.halfH,
      checkerR: this.checkerR,
      resolvedTheme: this.resolvedTheme,
      glowPhase: this.glowPhase,
      onPointTap: this.onPointTap,
      onBarTap: this.onBarTap,
      fillRoundRect: (x: number, y: number, w: number, h: number, r: number): void => {
        this.fillRoundRect(x, y, w, h, r)
      },
      getPointX: (col: number): number => {
        return this.getPointX(col)
      },
      getCheckerCenter: (pointIndex: number, stackPos: number): Point => {
        return this.getCheckerCenter(pointIndex, stackPos)
      },
      getBarCenter: (isWhite: boolean): Point => {
        return this.getBarCenter(isWhite)
      },
      drawOneChecker: (cx: number, cy: number, r: number, isWhite: boolean, glow: boolean): void => {
        this.drawOneChecker(cx, cy, r, isWhite, glow)
      }
    }
  }
}
