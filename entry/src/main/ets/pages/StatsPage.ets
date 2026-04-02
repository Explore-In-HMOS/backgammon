import { common } from '@kit.AbilityKit'
import { GameStats, EMPTY_STATS, cloneStats } from '../model/GameTypes'
import { StatsManager } from '../utils/StatsManager'

@Component
export struct StatsPage {
  @State stats: GameStats = {
    gamesPlayed: 0,
    whiteWins: 0,
    blackWins: 0,
    gammonCount: 0,
    backgammonCount: 0,
    currentStreak: 0,
    longestStreak: 0,
    lastWinner: 0
  }
  @State showResetConfirm: boolean = false
  private navStack: NavPathStack = new NavPathStack()

  private winRate(): string {
    if (this.stats.gamesPlayed === 0) {
      return '—'
    }
    const rate = Math.round((this.stats.whiteWins / this.stats.gamesPlayed) * 100)
    return `${rate}%`
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 0 }) {
          // Header
          Row() {
            Button('←')
              .width(36).height(36).fontSize(18)
              .backgroundColor(Color.Transparent)
              .fontColor('#C8A060')
              .onClick(() => this.navStack.pop())

            Text('Statistics')
              .fontSize(17).fontWeight(FontWeight.Bold)
              .fontColor('#F5F0E8').layoutWeight(1)
              .textAlign(TextAlign.Center)

            Blank().width(36)
          }
          .width('100%').height(48).padding({ left: 8, right: 8 })

          Divider().color('#3A2A14').strokeWidth(1)

          // Total games
          Row() {
            this.StatCard('Total Games', this.stats.gamesPlayed.toString(), '🎲')
          }
          .width('100%').padding({ left: 12, right: 12, top: 4, bottom: 4 })

          // Win breakdown
          Row({ space: 0 }) {
            this.HalfCard('White\nWins', this.stats.whiteWins.toString(), '#F0EDE0')
            this.HalfCard('Black\nWins', this.stats.blackWins.toString(), '#4A4040')
          }
          .width('100%').padding({ left: 12, right: 12, bottom: 8 })

          Row() {
            this.StatCard('Win Rate', this.winRate(), '📊')
          }
          .width('100%').padding({ left: 12, right: 12, top: 4, bottom: 4 })

          // Gammon/Backgammon
          Row({ space: 0 }) {
            this.HalfCard('Gammon', this.stats.gammonCount.toString(), '#C8A060')
            this.HalfCard('Backgammon', this.stats.backgammonCount.toString(), '#E06040')
          }
          .width('100%').padding({ left: 12, right: 12, bottom: 8 })

          // Streak
          Row({ space: 0 }) {
            this.HalfCard('Current Streak', this.stats.currentStreak.toString(), '#60C060')
            this.HalfCard('Best Streak', this.stats.longestStreak.toString(), '#FFD700')
          }
          .width('100%').padding({ left: 12, right: 12, bottom: 16 })

          Divider().color('#3A2A14').strokeWidth(1).margin({ bottom: 12 })

          // Reset button
          if (!this.showResetConfirm) {
            Button('Reset Stats')
              .width(160).height(38).fontSize(13)
              .fontColor('#E06040')
              .backgroundColor('#2A1A08')
              .borderRadius(19)
              .margin({ bottom: 20 })
              .onClick(() => { this.showResetConfirm = true })
          } else {
            Column({ space: 8 }) {
              Text('Are you sure?')
                .fontSize(14).fontColor('#F5F0E8')
              Row({ space: 12 }) {
                Button('Yes')
                  .width(70).height(34).fontSize(13)
                  .fontColor('#F5F0E8').backgroundColor('#C04030').borderRadius(17)
                  .onClick(() => {
                    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext
                    StatsManager.reset(ctx)
                    this.stats = cloneStats(EMPTY_STATS)
                    this.showResetConfirm = false
                  })
                Button('No')
                  .width(70).height(34).fontSize(13)
                  .fontColor('#A09080').backgroundColor('#2A1A08').borderRadius(17)
                  .onClick(() => { this.showResetConfirm = false })
              }
            }
            .margin({ bottom: 20 })
          }
        }
      }
      .width('100%').height('100%')
      .backgroundColor('#1A0F05')
      .scrollable(ScrollDirection.Vertical)
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.navStack = context.pathStack
      try {
        const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext
        this.stats = StatsManager.load(ctx)
      } catch (_e) {}
    })
  }

  @Builder
  StatCard(label: string, value: string, icon: string) {
    Row() {
      Text(icon).fontSize(18).width(30)
      Text(label).fontSize(13).fontColor('#A09080').layoutWeight(1)
      Text(value).fontSize(20).fontWeight(FontWeight.Bold).fontColor('#F5F0E8')
    }
    .width('100%').height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#2A1A08')
    .borderRadius(10)
  }

  @Builder
  HalfCard(label: string, value: string, color: string) {
    Column({ space: 2 }) {
      Text(value)
        .fontSize(22).fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(10).fontColor('#A09080')
        .textAlign(TextAlign.Center)
        .maxLines(2)
    }
    .layoutWeight(1).height(60)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#2A1A08')
    .borderRadius(10)
    .margin({ right: 4 })
  }
}
