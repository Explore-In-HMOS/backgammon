import { GamePhase, Decoration } from '../model/GameTypes'
import { GameStateModel } from '../model/GameStateModel'
import { BoardCanvas } from './BoardCanvas'
import { DiceFace } from './DiceComponent'
import { doFirstRoll, rollDice } from '../engine/GameDiceLogic'
import { handlePointTap, handleBarTap, undo, handleCrownRotation } from '../engine/GameMoveLogic'
import { acceptDouble, declineDouble } from '../engine/GameCubeLogic'
import { resign } from '../utils/GamePersistLogic'

@Component
export struct GameView {
  @ObjectLink model: GameStateModel

  build() {
    Stack() {
      Column() {
        // ── Top: Dice row ────────────────────────────────────────
        Row({ space: 4 }) {
          if (this.model.displayDiceValues.length >= 1) {
            DiceFace({
              value: this.model.displayDiceValues[0],
              used: this.model.diceUsed[0] ?? false,
              faceSize: this.model.displayDiceValues.length <= 2 ? 22 : 17,
              accentColor: '#C8A060'
            })
          }
          if (this.model.displayDiceValues.length >= 2) {
            DiceFace({
              value: this.model.displayDiceValues[1],
              used: this.model.diceUsed[1] ?? false,
              faceSize: this.model.displayDiceValues.length <= 2 ? 22 : 17,
              accentColor: '#C8A060'
            })
          }
          if (this.model.displayDiceValues.length >= 3) {
            DiceFace({
              value: this.model.displayDiceValues[2],
              used: this.model.diceUsed[2] ?? false,
              faceSize: 17,
              accentColor: '#C8A060'
            })
          }
          if (this.model.displayDiceValues.length >= 4) {
            DiceFace({
              value: this.model.displayDiceValues[3],
              used: this.model.diceUsed[3] ?? false,
              faceSize: 17,
              accentColor: '#C8A060'
            })
          }
        }
        .width('100%').height(36)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .hitTestBehavior(HitTestMode.None)

        // ── Board ────────────────────────────────────────────────
        BoardCanvas({
          board: this.model.board,
          selectedPoint: this.model.selectedPoint,
          validTargets: this.model.validTargets,
          whiteOff: this.model.whiteOff,
          blackOff: this.model.blackOff,
          cubeValue: this.model.cubeValue,
          showCube: this.model.enableDoubling && this.model.cubeValue > 1,
          pipWhite: this.model.pipWhite,
          pipBlack: this.model.pipBlack,
          showPip: this.model.showPipCount,
          animActive: this.model.animActive,
          animFromPoint: this.model.animFromPoint,
          animToPoint: this.model.animToPoint,
          animIsHit: this.model.animIsHit,
          animIsWhite: this.model.animIsWhite,
          animProgress: this.model.animProgress,
          themeId: this.model.themeId,
          whiteDecoration: this.model.whiteDecoration as Decoration,
          blackDecoration: this.model.blackDecoration as Decoration,
          crownFocusPoint: this.model.crownFocusPoint,
          currentPlayer: this.model.currentPlayer,
          onPointTap: (pt: number) => { handlePointTap(this.model, pt) },
          onBarTap: (p: number) => { handleBarTap(this.model, p) }
        })
          .width('100%')
          .layoutWeight(1)

        // ── Bottom bar ───────────────────────────────────────────
        Row() {
          if (this.model.phase === GamePhase.DOUBLING) {
            Button() {
              Text('Accept').fontSize(12).fontColor('#F5F0E8').textAlign(TextAlign.Center)
            }
            .layoutWeight(1).height(24).backgroundColor('#4A8A4A').borderRadius(12)
            .onClick(() => { acceptDouble(this.model) })
            Button() {
              Text('Decline').fontSize(12).fontColor('#F5F0E8').textAlign(TextAlign.Center)
            }
            .layoutWeight(1).height(24).backgroundColor('#8A3A3A').borderRadius(12)
            .onClick(() => { declineDouble(this.model) })
          } else {
            // Left: GG
            Button() {
              Text('GG').fontSize(12).fontColor('#806060').textAlign(TextAlign.Center)
            }
            .width(42).height(24).backgroundColor('#2A1A08').borderRadius(12)
            .onClick(() => { this.model.showResignDialog = true })

            // Center: Roll / Undo / placeholder
            if ((this.model.phase === GamePhase.FIRST_ROLL || this.model.phase === GamePhase.ROLLING) &&
              !this.model.aiThinking) {
              Button() {
                Row({ space: 2 }) {
                  DiceFace({ value: 5, used: false, faceSize: 11, accentColor: '#C8A060' })
                  DiceFace({ value: 3, used: false, faceSize: 11, accentColor: '#C8A060' })
                }
              }
              .width(34).height(24).margin({ left: 6, right: 6 })
              .backgroundColor('#8B5A2B').borderRadius(12)
              .onClick(() => {
                if (this.model.phase === GamePhase.FIRST_ROLL) {
                  doFirstRoll(this.model)
                } else {
                  rollDice(this.model)
                }
              })
            } else if (this.model.undoAvailable && this.model.phase === GamePhase.MOVING && !this.model.aiThinking) {
              Button() {
                Text('Undo').fontSize(12).fontColor('#C8A060').textAlign(TextAlign.Center)
              }
              .width(42).height(24).margin({ left: 6, right: 6 })
              .backgroundColor('#2A1A08').borderRadius(12)
              .onClick(() => { undo(this.model) })
            } else {
              Blank().width(46).margin({ left: 6, right: 6 })
            }

            // Right: Exit
            Button() {
              Text('Exit').fontSize(12).fontColor('#A09080').textAlign(TextAlign.Center)
            }
            .width(42).height(24).backgroundColor('#2A1A08').borderRadius(12)
            .onClick(() => { this.model.saveGame(); this.model.cbNavPop() })
          }
        }
        .width('100%').height(26)
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .padding({ left: 10, right: 10 })
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%').height('100%')
      .padding({ bottom: 12 })
      .onDigitalCrown((event: CrownEvent) => {
        handleCrownRotation(this.model, event.angularVelocity)
      })

      // ── Overlays ─────────────────────────────────────────────
      if (this.model.showResignDialog) {
        this.ConfirmDialog(
          'Resign?',
          () => { resign(this.model) },
          () => { this.model.showResignDialog = false }
        )
      }
    }
    .width('100%').height('100%')
    .backgroundColor('#0D0801')
  }

  @Builder
  ConfirmDialog(msg: string, onYes: () => void, onNo: () => void) {
    Column({ space: 12 }) {
      Text(msg)
        .fontSize(15).fontColor('#F5F0E8').textAlign(TextAlign.Center)
      Row({ space: 12 }) {
        Button('Yes')
          .width(80).height(36).fontSize(14)
          .fontColor('#F5F0E8').backgroundColor('#8B5A2B').borderRadius(18)
          .onClick(onYes)
        Button('No')
          .width(80).height(36).fontSize(14)
          .fontColor('#A09080').backgroundColor('#2A1A08').borderRadius(18)
          .onClick(onNo)
      }
    }
    .padding(20).backgroundColor('#2A1A08')
    .borderRadius(16).border({ width: 1, color: '#5A3A14' })
  }
}
