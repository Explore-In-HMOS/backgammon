import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { AILevel, GameMode, DEFAULT_SETTINGS, Decoration, GamePageParams } from '../model/GameTypes'

@Component
export struct GameSetupPage {
  @State gameMode: GameMode = GameMode.VS_AI
  @State aiLevel: AILevel = AILevel.MEDIUM
  @State matchLength: number = 1

  // Appearance/gameplay prefs read from store (not changed here)
  private themeId: string = DEFAULT_SETTINGS.themeId
  private whiteDecoration: Decoration = DEFAULT_SETTINGS.whiteDecoration
  private blackDecoration: Decoration = DEFAULT_SETTINGS.blackDecoration
  private autoBearOff: boolean = DEFAULT_SETTINGS.autoBearOff
  private showPipCount: boolean = DEFAULT_SETTINGS.showPipCount
  private enableDoubling: boolean = DEFAULT_SETTINGS.enableDoubling
  private soundEnabled: boolean = DEFAULT_SETTINGS.soundEnabled
  private hapticEnabled: boolean = DEFAULT_SETTINGS.hapticEnabled

  private pref: preferences.Preferences | null = null
  private navStack: NavPathStack = new NavPathStack()

  private load(): void {
    const p = this.pref
    if (!p) {
      return
    }
    try {
      this.gameMode = p.getSync('gameMode', DEFAULT_SETTINGS.gameMode) as GameMode
      this.aiLevel = p.getSync('aiLevel', DEFAULT_SETTINGS.aiLevel) as AILevel
      this.matchLength = p.getSync('matchLength', DEFAULT_SETTINGS.matchLength) as number
      this.themeId = p.getSync('themeId', DEFAULT_SETTINGS.themeId) as string
      this.whiteDecoration = p.getSync('whiteDecoration', DEFAULT_SETTINGS.whiteDecoration) as Decoration
      this.blackDecoration = p.getSync('blackDecoration', DEFAULT_SETTINGS.blackDecoration) as Decoration
      this.autoBearOff = p.getSync('autoBearOff', DEFAULT_SETTINGS.autoBearOff) as boolean
      this.showPipCount = p.getSync('showPipCount', DEFAULT_SETTINGS.showPipCount) as boolean
      this.enableDoubling = p.getSync('enableDoubling', DEFAULT_SETTINGS.enableDoubling) as boolean
      this.soundEnabled = p.getSync('soundEnabled', DEFAULT_SETTINGS.soundEnabled) as boolean
      this.hapticEnabled = p.getSync('hapticEnabled', DEFAULT_SETTINGS.hapticEnabled) as boolean
    } catch (_e) {}
  }

  private startGame(): void {
    // Persist selections so next time defaults are set
    if (this.pref) {
      try {
        this.pref.putSync('gameMode', this.gameMode)
        this.pref.putSync('aiLevel', this.aiLevel)
        this.pref.putSync('matchLength', this.matchLength)
        this.pref.putSync('hasSavedGame', false)
        this.pref.flushSync()
      } catch (_e) {}
    }

    const gp: GamePageParams = {
      whiteMatchScore: 0,
      blackMatchScore: 0,
      matchLength: this.matchLength,
      gameMode: this.gameMode,
      aiLevel: this.aiLevel,
      themeId: this.themeId,
      whiteDecoration: this.whiteDecoration,
      blackDecoration: this.blackDecoration,
      autoBearOff: this.autoBearOff,
      showPipCount: this.showPipCount,
      enableDoubling: this.enableDoubling,
      soundEnabled: this.soundEnabled,
      hapticEnabled: this.hapticEnabled,
      resumeGame: false
    }
    this.navStack.pushPathByName('GamePage', gp)
  }

  build() {
    NavDestination() {
      Column({ space: 0 }) {
        // Header
        Text(this.gameMode === GameMode.VS_AI ? 'AI' : 'P2P')
          .fontSize(17).fontWeight(FontWeight.Bold)
          .fontColor('#F5F0E8').width('100%').textAlign(TextAlign.Center)
          .height(32).padding({ top: 6 })

        Divider().color('#3A2A14')

        Scroll() {
          Column({ space: 0 }) {
            // ── AI Difficulty (only for VS_AI) ─────────────────────
            if (this.gameMode === GameMode.VS_AI) {
              Text('Difficulty')
                .fontSize(12).fontColor('#A09080')
                .width('100%').padding({ left: 16, top: 10, bottom: 4 })
              Row({ space: 6 }) {
                Button() { Text('Easy').fontSize(13).fontColor(this.aiLevel === AILevel.EASY ? '#F5F0E8' : '#A09080').textAlign(TextAlign.Center) }
                .height(34).layoutWeight(1)
                .backgroundColor(this.aiLevel === AILevel.EASY ? '#8B5A2B' : '#2A1A08')
                .borderRadius(17)
                .onClick(() => { this.aiLevel = AILevel.EASY })
                Button() { Text('Medium').fontSize(13).fontColor(this.aiLevel === AILevel.MEDIUM ? '#F5F0E8' : '#A09080').textAlign(TextAlign.Center) }
                .height(34).layoutWeight(1)
                .backgroundColor(this.aiLevel === AILevel.MEDIUM ? '#8B5A2B' : '#2A1A08')
                .borderRadius(17)
                .onClick(() => { this.aiLevel = AILevel.MEDIUM })
                Button() { Text('Hard').fontSize(13).fontColor(this.aiLevel === AILevel.HARD ? '#F5F0E8' : '#A09080').textAlign(TextAlign.Center) }
                .height(34).layoutWeight(1)
                .backgroundColor(this.aiLevel === AILevel.HARD ? '#8B5A2B' : '#2A1A08')
                .borderRadius(17)
                .onClick(() => { this.aiLevel = AILevel.HARD })
              }
              .width('100%').padding({ left: 16, right: 16, bottom: 8 })

              Divider().color('#3A2A14').margin({ top: 4, bottom: 4 })
            }

            // ── Match Length ───────────────────────────────────────
            Text('Match Length')
              .fontSize(12).fontColor('#A09080')
              .width('100%').padding({ left: 16, top: 10, bottom: 4 })
            Row({ space: 6 }) {
              Button('1')
                .fontSize(13).height(34).layoutWeight(1)
                .fontColor(this.matchLength === 1 ? '#F5F0E8' : '#A09080')
                .backgroundColor(this.matchLength === 1 ? '#8B5A2B' : '#2A1A08')
                .borderRadius(17).onClick(() => { this.matchLength = 1 })
              Button('3')
                .fontSize(13).height(34).layoutWeight(1)
                .fontColor(this.matchLength === 3 ? '#F5F0E8' : '#A09080')
                .backgroundColor(this.matchLength === 3 ? '#8B5A2B' : '#2A1A08')
                .borderRadius(17).onClick(() => { this.matchLength = 3 })
              Button('5')
                .fontSize(13).height(34).layoutWeight(1)
                .fontColor(this.matchLength === 5 ? '#F5F0E8' : '#A09080')
                .backgroundColor(this.matchLength === 5 ? '#8B5A2B' : '#2A1A08')
                .borderRadius(17).onClick(() => { this.matchLength = 5 })
              Button('7')
                .fontSize(13).height(34).layoutWeight(1)
                .fontColor(this.matchLength === 7 ? '#F5F0E8' : '#A09080')
                .backgroundColor(this.matchLength === 7 ? '#8B5A2B' : '#2A1A08')
                .borderRadius(17).onClick(() => { this.matchLength = 7 })
            }
            .width('100%').padding({ left: 16, right: 16, bottom: 8 })

            Divider().color('#3A2A14').margin({ top: 4, bottom: 4 })

            // ── Doubling Cube ──────────────────────────────────────
            Row() {
              Text('Doubling Cube')
                .fontSize(14).fontColor('#F5F0E8').layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.enableDoubling })
                .width(44).height(24).selectedColor('#8B5A2B')
                .onChange((v: boolean) => { this.enableDoubling = v })
            }
            .width('100%').height(46).padding({ left: 16, right: 16 })

            Blank().height(16)
          }
          .width('100%').alignItems(HorizontalAlign.Center)
        }
        .layoutWeight(1)
        .scrollable(ScrollDirection.Vertical)
        .edgeEffect(EdgeEffect.Spring)

        // Play button fixed at bottom
        Button('Play')
          .width('40%').height(32).fontSize(16).fontWeight(FontWeight.Bold)
          .fontColor('#F5F0E8').backgroundColor('#4A8A4A')
          .borderRadius(16).margin({ top: 2, bottom: 10 })
          .onClick(() => this.startGame())
      }
      .width('100%').height('100%')
      .backgroundColor('#1A0F05')
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.navStack = context.pathStack
      // Mode is passed from Index
      const mode = context.pathInfo.param as GameMode | undefined
      if (mode !== undefined) {
        this.gameMode = mode
      }
      try {
        const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext
        this.pref = preferences.getPreferencesSync(ctx, { name: 'backgammon_prefs' })
        this.load()
        // Param overrides loaded pref
        if (mode !== undefined) {
          this.gameMode = mode
        }
      } catch (_e) {}
    })
  }

}
