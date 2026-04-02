import { Player, GamePageParams, WinPageParams } from '../model/GameTypes'

@Component
export struct WinPage {
  @State winner: Player = Player.WHITE
  @State whiteMatchScore: number = 0
  @State blackMatchScore: number = 0
  @State matchLength: number = 1
  @State winnerStreak: number = 0
  private navStack: NavPathStack = new NavPathStack()

  private isMatchOver(): boolean {
    return this.whiteMatchScore >= this.matchLength || this.blackMatchScore >= this.matchLength
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 0 }) {
          Column().height(16)

          // Trophy
          Image($r('app.media.trophy'))
            .width(52).height(52)
            .opacity(0.9)
            .margin({ bottom: 6 })

          // Winner name
          Text(this.winner === Player.WHITE ? 'White Wins!' : 'Black Wins!')
            .fontSize(20).fontWeight(FontWeight.Bold)
            .fontColor(this.winner === Player.WHITE ? '#F0EDE0' : '#9090A0')
            .margin({ bottom: 2 })

          // Match score
          Row({ space: 16 }) {
            Column({ space: 2 }) {
              Text('White').fontSize(10).fontColor('#A09080')
              Text(this.whiteMatchScore.toString())
                .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#F0EDE0')
            }.alignItems(HorizontalAlign.Center)
            Text(':').fontSize(18).fontColor('#7A6A50')
            Column({ space: 2 }) {
              Text('Black').fontSize(10).fontColor('#A09080')
              Text(this.blackMatchScore.toString())
                .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#9090A0')
            }.alignItems(HorizontalAlign.Center)
          }
          .margin({ bottom: 2 })

          Text(`(${this.matchLength}-game match)`)
            .fontSize(10).fontColor('#5A5050').margin({ bottom: 4 })

          // Streak indicator
          if (this.winnerStreak > 1) {
            Row({ space: 4 }) {
              Text('🔥').fontSize(12)
              Text(`${this.winnerStreak}-game streak!`)
                .fontSize(12).fontColor('#FF8040')
            }
            .margin({ bottom: 4 })
          }

          // Match over
          if (this.isMatchOver()) {
            Text(this.whiteMatchScore >= this.matchLength ? 'White wins the match!' : 'Black wins the match!')
              .fontSize(13).fontColor(this.winner === Player.WHITE ? '#C8A060' : '#8090B0')
              .fontWeight(FontWeight.Bold).margin({ bottom: 10 })
          }

          // Buttons
          Button() { Text('Play Again').fontSize(15).fontColor('#F5F0E8').textAlign(TextAlign.Center) }
          .width(160).height(36)
          .backgroundColor('#8B5A2B')
          .borderRadius(18).margin({ bottom: 8 })
          .onClick(() => {
            if (this.isMatchOver()) {
              // Match finished — go to setup to choose new settings
              this.navStack.clear()
            } else {
              // Same match, next game
              const gp: GamePageParams = {
                whiteMatchScore: this.whiteMatchScore,
                blackMatchScore: this.blackMatchScore,
                matchLength: this.matchLength,
                resumeGame: false
              }
              this.navStack.pop()
              this.navStack.replacePathByName('GamePage', gp)
            }
          })

          Button() { Text('Main Menu').fontSize(13).fontColor('#A09080').textAlign(TextAlign.Center) }
          .width(160).height(32)
          .backgroundColor('#2A1A08')
          .borderRadius(16).margin({ bottom: 16 })
          .onClick(() => {
            this.navStack.clear()
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%').height('100%')
      .scrollBar(BarState.Off)
      .backgroundColor('#1A0F05')
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.navStack = context.pathStack
      const params = context.pathInfo.param as WinPageParams | undefined
      if (params) {
        this.winner = params.winner as Player
        this.whiteMatchScore = params.whiteMatchScore ?? 0
        this.blackMatchScore = params.blackMatchScore ?? 0
        this.matchLength = params.matchLength ?? 1
        this.winnerStreak = this.winner === Player.WHITE
          ? (params.whiteStreak ?? 0)
          : (params.blackStreak ?? 0)
      }
    })
  }
}
