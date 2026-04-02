import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { AILevel, GameMode, AppSettings, DEFAULT_SETTINGS, Decoration, GamePageParams } from '../model/GameTypes'
import { GamePage } from './GamePage'
import { WinPage } from './WinPage'
import { SettingsPage } from './SettingsPage'
import { StatsPage } from './StatsPage'
import { TutorialPage } from './TutorialPage'
import { GameSetupPage } from './GameSetupPage'

@Entry
@Component
struct Index {
  @State settings: AppSettings = {
    soundEnabled: true,
    hapticEnabled: true,
    aiLevel: AILevel.MEDIUM,
    gameMode: GameMode.VS_AI,
    matchLength: 1,
    whiteMatchScore: 0,
    blackMatchScore: 0,
    themeId: 'classic',
    whiteDecoration: 'none' as Decoration,
    blackDecoration: 'none' as Decoration,
    autoBearOff: true,
    showPipCount: true,
    enableDoubling: false,
    tutorialDone: false
  }
  @State selectedMode: GameMode = GameMode.VS_AI
  @State hasSavedGame: boolean = false
  private prefStore: preferences.Preferences | null = null
  private navStack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext
      this.prefStore = preferences.getPreferencesSync(ctx, { name: 'backgammon_prefs' })
      this.loadSettings()
      this.hasSavedGame = this.prefStore.getSync('hasSavedGame', false) as boolean

      // First-time tutorial
      const done: boolean = this.prefStore.getSync('tutorialDone', false) as boolean
      if (!done) {
        setTimeout(() => {
          this.navStack.pushPathByName('TutorialPage', undefined)
        }, 300)
      }
    } catch (_e) {
      // use defaults
    }
  }

  private loadSettings(): void {
    if (!this.prefStore) {
      return
    }
    try {
      const p = this.prefStore
      this.settings = {
        soundEnabled: p.getSync('soundEnabled', DEFAULT_SETTINGS.soundEnabled) as boolean,
        hapticEnabled: p.getSync('hapticEnabled', DEFAULT_SETTINGS.hapticEnabled) as boolean,
        aiLevel: p.getSync('aiLevel', DEFAULT_SETTINGS.aiLevel) as AILevel,
        gameMode: p.getSync('gameMode', DEFAULT_SETTINGS.gameMode) as GameMode,
        matchLength: p.getSync('matchLength', DEFAULT_SETTINGS.matchLength) as number,
        whiteMatchScore: p.getSync('whiteMatchScore', 0) as number,
        blackMatchScore: p.getSync('blackMatchScore', 0) as number,
        themeId: p.getSync('themeId', DEFAULT_SETTINGS.themeId) as string,
        whiteDecoration: p.getSync('whiteDecoration', DEFAULT_SETTINGS.whiteDecoration) as Decoration,
        blackDecoration: p.getSync('blackDecoration', DEFAULT_SETTINGS.blackDecoration) as Decoration,
        autoBearOff: p.getSync('autoBearOff', DEFAULT_SETTINGS.autoBearOff) as boolean,
        showPipCount: p.getSync('showPipCount', DEFAULT_SETTINGS.showPipCount) as boolean,
        enableDoubling: p.getSync('enableDoubling', DEFAULT_SETTINGS.enableDoubling) as boolean,
        tutorialDone: p.getSync('tutorialDone', false) as boolean
      }
      this.selectedMode = p.getSync('gameMode', DEFAULT_SETTINGS.gameMode) as GameMode
    } catch (_e) {}
  }

  @Builder
  routeMap(name: string) {
    if (name === 'GamePage') {
      GamePage()
    } else if (name === 'WinPage') {
      WinPage()
    } else if (name === 'SettingsPage') {
      SettingsPage()
    } else if (name === 'StatsPage') {
      StatsPage()
    } else if (name === 'TutorialPage') {
      TutorialPage()
    } else if (name === 'GameSetupPage') {
      GameSetupPage()
    }
  }

  build() {
    Navigation(this.navStack) {
      Scroll() {
        Column({ space: 0 }) {
          Column().height(20)

          // Title
          Text('BACKGAMMON')
            .fontSize(15).fontWeight(FontWeight.Bold)
            .fontColor('#C8A060').letterSpacing(4)
          Text('Wearable Edition')
            .fontSize(10).fontColor('#7A6A50').margin({ top: 2, bottom: 8 })

          // ── Mode Selection ─────────────────────────────────────
          Row({ space: 8 }) {
            Button('AI')
              .height(24).layoutWeight(1).fontSize(12)
              .fontColor(this.selectedMode === GameMode.VS_AI ? '#F5F0E8' : '#A09080')
              .backgroundColor(this.selectedMode === GameMode.VS_AI ? '#8B5A2B' : '#2A1A08')
              .borderRadius(12)
              .onClick(() => {
                this.selectedMode = GameMode.VS_AI
                if (this.prefStore) {
                  try {
                    this.prefStore.putSync('gameMode', GameMode.VS_AI)
                    this.prefStore.flushSync()
                  } catch (_e) {}
                }
              })
            Button('P2P')
              .height(24).layoutWeight(1).fontSize(12)
              .fontColor(this.selectedMode === GameMode.TWO_PLAYER ? '#F5F0E8' : '#A09080')
              .backgroundColor(this.selectedMode === GameMode.TWO_PLAYER ? '#8B5A2B' : '#2A1A08')
              .borderRadius(12)
              .onClick(() => {
                this.selectedMode = GameMode.TWO_PLAYER
                if (this.prefStore) {
                  try {
                    this.prefStore.putSync('gameMode', GameMode.TWO_PLAYER)
                    this.prefStore.flushSync()
                  } catch (_e) {}
                }
              })
          }
          .width(150).margin({ bottom: 8 })

          // ── New Game ───────────────────────────────────────────
          Button('New Game')
            .width(150).height(34).fontSize(15).fontWeight(FontWeight.Medium)
            .fontColor('#F5F0E8').backgroundColor('#8B5A2B')
            .borderRadius(17).margin({ bottom: 5 })
            .onClick(() => {
              this.navStack.pushPathByName('GameSetupPage', this.selectedMode)
            })

          if (this.hasSavedGame) {
            Button('Continue')
              .width(150).height(28).fontSize(14)
              .fontColor('#C8A060').backgroundColor('#2A1A08')
              .borderRadius(14).margin({ bottom: 6 })
              .onClick(() => {
                const gp: GamePageParams = {
                  whiteMatchScore: this.settings.whiteMatchScore,
                  blackMatchScore: this.settings.blackMatchScore,
                  matchLength: this.settings.matchLength,
                  gameMode: GameMode.VS_AI,
                  aiLevel: this.settings.aiLevel,
                  themeId: this.settings.themeId,
                  whiteDecoration: this.settings.whiteDecoration,
                  blackDecoration: this.settings.blackDecoration,
                  autoBearOff: this.settings.autoBearOff,
                  showPipCount: this.settings.showPipCount,
                  enableDoubling: this.settings.enableDoubling,
                  soundEnabled: this.settings.soundEnabled,
                  hapticEnabled: this.settings.hapticEnabled,
                  resumeGame: true
                }
                this.navStack.pushPathByName('GamePage', gp)
              })
          }

          // Bottom row: settings + stats
          Row({ space: 8 }) {
            Button('Settings')
              .height(28).layoutWeight(1).fontSize(11)
              .padding({ left: 2, right: 2 })
              .fontColor('#A09080').backgroundColor('#2A1A08').borderRadius(14)
              .onClick(() => this.navStack.pushPathByName('SettingsPage', undefined))

            Button('Stats')
              .height(28).layoutWeight(1).fontSize(11)
              .padding({ left: 2, right: 2 })
              .fontColor('#A09080').backgroundColor('#2A1A08').borderRadius(14)
              .onClick(() => this.navStack.pushPathByName('StatsPage', undefined))
          }
          .width(150).margin({ top: 6, bottom: 16 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%').height('100%')
      .backgroundColor('#1A0F05')
      .scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%').height('100%')
    .hideTitleBar(true)
    .navDestination(this.routeMap)
  }

}
