import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { TutorialParams } from '../model/GameTypes'

interface TutorialStep {
  title: string
  body: string
  icon: string
}

const STEPS: TutorialStep[] = [
  {
    title: 'Welcome!',
    body: 'Race to bear off all 15 checkers first. White moves right→left, Black moves left→right.',
    icon: '🎲'
  },
  {
    title: 'Roll the Dice',
    body: 'Press Roll each turn. Doubles give 4 moves. Move checkers the number of points on the dice.',
    icon: '🎯'
  },
  {
    title: 'Select a Checker',
    body: 'Tap a checker to select it. Valid moves highlight green. Use the crown to cycle pieces.',
    icon: '⚫'
  },
  {
    title: 'Bar & Bear-Off',
    body: 'Hit a lone opponent checker to send it to the bar. Re-enter from bar before other moves.',
    icon: '🏆'
  },
  {
    title: 'AI Difficulty',
    body: 'Set difficulty in Settings: Easy, Medium, or Hard. In 2-player mode, pass the device each turn.',
    icon: '🤖'
  }
]

@Component
export struct TutorialPage {
  @State step: number = 0
  @State fromSettings: boolean = false
  private navStack: NavPathStack = new NavPathStack()

  private markDone(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext
      const p: preferences.Preferences = preferences.getPreferencesSync(ctx, { name: 'backgammon_prefs' })
      p.putSync('tutorialDone', true)
      p.flushSync()
    } catch (_e) {}
    this.navStack.pop()
  }

  build() {
    NavDestination() {
      Stack() {
        Column({ space: 0 }) {
          Blank().height(18)

          // Step indicator dots
          Row({ space: 6 }) {
            ForEach(STEPS, (_s: TutorialStep) => {
              Circle()
                .width(STEPS.indexOf(_s) === this.step ? 10 : 6)
                .height(STEPS.indexOf(_s) === this.step ? 10 : 6)
                .fill(STEPS.indexOf(_s) === this.step ? '#C8A060' : '#5A4030')
            }, (_s: TutorialStep) => _s.title)
          }
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 8 })

          // Icon
          Text(STEPS[this.step].icon)
            .fontSize(32)
            .margin({ bottom: 4 })

          // Title
          Text(STEPS[this.step].title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#C8A060')
            .textAlign(TextAlign.Center)
            .padding({ left: 20, right: 20 })
            .margin({ bottom: 6 })

          // Body — fixed height keeps button position stable
          Column() {
            Text(STEPS[this.step].body)
              .fontSize(12)
              .fontColor('#D0C8B8')
              .textAlign(TextAlign.Center)
              .lineHeight(18)
              .padding({ left: 28, right: 28 })
          }
          .height(60)
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 14 })

          // Navigation
          Row({ space: 12 }) {
            if (this.step > 0) {
              Button('Back')
                .height(34).layoutWeight(1).fontSize(13)
                .fontColor('#A09080').backgroundColor('#2A1A08')
                .borderRadius(17)
                .onClick(() => { this.step-- })
            } else {
              Blank().layoutWeight(1)
            }

            if (this.step < STEPS.length - 1) {
              Button('Next')
                .height(34).layoutWeight(1).fontSize(13)
                .fontColor('#F5F0E8').backgroundColor('#8B5A2B')
                .borderRadius(17)
                .onClick(() => { this.step++ })
            } else {
              Button('Play!')
                .height(34).layoutWeight(1).fontSize(13)
                .fontColor('#F5F0E8').backgroundColor('#4A8A4A')
                .borderRadius(17)
                .onClick(() => { this.markDone() })
            }
          }
          .width('100%')
          .padding({ left: 36, right: 36 })

          Blank().layoutWeight(1)
        }
        .width('100%').height('100%')
        .backgroundColor('#1A0F05')
        .alignItems(HorizontalAlign.Center)

        // Skip button
        Button('Skip')
          .width(50).height(28).fontSize(11)
          .fontColor('#5A4030').backgroundColor(Color.Transparent)
          .position({ x: '75%', y: 10 })
          .onClick(() => { this.markDone() })
      }
      .width('100%').height('100%')
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.navStack = context.pathStack
      const params = context.pathInfo.param as TutorialParams | undefined
      this.fromSettings = params?.fromSettings ?? false
    })
  }
}
