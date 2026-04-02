import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { AILevel, GameMode, AppSettings, DEFAULT_SETTINGS, THEMES, ThemeConfig, Decoration, cloneSettings, TutorialParams } from '../model/GameTypes'

@Component
export struct SettingsPage {
  @State s: AppSettings = {
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
  private pref: preferences.Preferences | null = null
  private navStack: NavPathStack = new NavPathStack()

  private load(): void {
    if (!this.pref) {
      return
    }
    try {
      const p = this.pref
      this.s = {
        soundEnabled: p.getSync('soundEnabled', DEFAULT_SETTINGS.soundEnabled) as boolean,
        hapticEnabled: p.getSync('hapticEnabled', DEFAULT_SETTINGS.hapticEnabled) as boolean,
        aiLevel: p.getSync('aiLevel', DEFAULT_SETTINGS.aiLevel) as AILevel,
        gameMode: p.getSync('gameMode', DEFAULT_SETTINGS.gameMode) as GameMode,
        matchLength: p.getSync('matchLength', DEFAULT_SETTINGS.matchLength) as number,
        whiteMatchScore: p.getSync('whiteMatchScore', 0) as number,
        blackMatchScore: p.getSync('blackMatchScore', 0) as number,
        themeId: p.getSync('themeId', DEFAULT_SETTINGS.themeId) as string,
        whiteDecoration: p.getSync('whiteDecoration', 'none') as Decoration,
        blackDecoration: p.getSync('blackDecoration', 'none') as Decoration,
        autoBearOff: p.getSync('autoBearOff', true) as boolean,
        showPipCount: p.getSync('showPipCount', true) as boolean,
        enableDoubling: p.getSync('enableDoubling', false) as boolean,
        tutorialDone: p.getSync('tutorialDone', false) as boolean
      }
    } catch (_e) {}
  }

  private save(): void {
    if (!this.pref) {
      return
    }
    try {
      const p = this.pref
      p.putSync('soundEnabled', this.s.soundEnabled)
      p.putSync('hapticEnabled', this.s.hapticEnabled)
      p.putSync('aiLevel', this.s.aiLevel)
      p.putSync('gameMode', this.s.gameMode)
      p.putSync('matchLength', this.s.matchLength)
      p.putSync('themeId', this.s.themeId)
      p.putSync('whiteDecoration', this.s.whiteDecoration)
      p.putSync('blackDecoration', this.s.blackDecoration)
      p.putSync('autoBearOff', this.s.autoBearOff)
      p.putSync('showPipCount', this.s.showPipCount)
      p.putSync('enableDoubling', this.s.enableDoubling)
      p.flushSync()
    } catch (_e) {}
  }

  private apply(s: AppSettings): void {
    this.s = s
    this.save()
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 0 }) {
          // Header
          Row() {
            Button('←').width(36).height(36).fontSize(18)
              .backgroundColor(Color.Transparent).fontColor('#C8A060')
              .onClick(() => this.navStack.pop())
            Text('Settings').fontSize(18).fontWeight(FontWeight.Bold)
              .fontColor('#F5F0E8').layoutWeight(1).textAlign(TextAlign.Center)
            Blank().width(36)
          }
          .width('100%').height(48).padding({ left: 8, right: 8 })

          Divider().color('#3A2A14')

          // --- Sound & Haptics ---
          this.SectionLabel('Sound & Haptics')
          this.ToggleRow('Sound Effects', this.s.soundEnabled, (v: boolean) => {
            const s: AppSettings = cloneSettings(this.s)
            s.soundEnabled = v
            this.apply(s)
          })
          this.ToggleRow('Haptics', this.s.hapticEnabled, (v: boolean) => {
            const s: AppSettings = cloneSettings(this.s)
            s.hapticEnabled = v
            this.apply(s)
          })

          Divider().color('#3A2A14').margin({ top: 4, bottom: 4 })

          // --- Game Options ---
          this.SectionLabel('Game Options')
          this.ToggleRow('Auto Bear-Off', this.s.autoBearOff, (v: boolean) => {
            const s: AppSettings = cloneSettings(this.s)
            s.autoBearOff = v
            this.apply(s)
          })
          this.ToggleRow('Pip Counter', this.s.showPipCount, (v: boolean) => {
            const s: AppSettings = cloneSettings(this.s)
            s.showPipCount = v
            this.apply(s)
          })

          Divider().color('#3A2A14').margin({ top: 4, bottom: 4 })

          // --- Board Theme ---
          this.SectionLabel('Board Theme')
          Grid() {
            ForEach(THEMES, (th: ThemeConfig) => {
              GridItem() {
                Column({ space: 4 }) {
                  Stack() {
                    Rect().width(40).height(28).borderRadius(4).fill(th.boardColor)
                    Row({ space: 2 }) {
                      Rect().width(7).height(18).fill(th.triColorA)
                      Rect().width(7).height(18).fill(th.triColorB)
                      Rect().width(7).height(18).fill(th.triColorA)
                    }
                    .position({ x: 3, y: 5 })
                  }
                  .width(44).height(30)
                  .border({ width: this.s.themeId === th.id ? 2 : 0, color: '#FFD700' })
                  .borderRadius(6)
                  Text(th.name)
                    .fontSize(9).width('100%').textAlign(TextAlign.Center)
                    .fontColor(this.s.themeId === th.id ? '#C8A060' : '#808070')
                }
                .width('100%').alignItems(HorizontalAlign.Center)
                .onClick(() => {
                  const s: AppSettings = cloneSettings(this.s)
                  s.themeId = th.id
                  this.apply(s)
                })
              }
            }, (th: ThemeConfig) => th.id)
          }
          .columnsTemplate('1fr 1fr 1fr 1fr')
          .width('100%').height(90)
          .padding({ left: 12, right: 12, bottom: 8 })

          Divider().color('#3A2A14').margin({ top: 4, bottom: 4 })

          // --- Decoration ---
          this.SectionLabel('White Decoration')
          Row({ space: 8 }) {
            Button('None')
              .fontSize(11).height(30).layoutWeight(1)
              .fontColor(this.s.whiteDecoration === 'none' ? '#F5F0E8' : '#A09080')
              .backgroundColor(this.s.whiteDecoration === 'none' ? '#8B5A2B' : '#2A1A08')
              .borderRadius(15)
              .onClick(() => { const s = cloneSettings(this.s); s.whiteDecoration = 'none'; this.apply(s) })
            Button('☕\nTea')
              .fontSize(11).height(30).layoutWeight(1)
              .fontColor(this.s.whiteDecoration === 'tea' ? '#F5F0E8' : '#A09080')
              .backgroundColor(this.s.whiteDecoration === 'tea' ? '#8B5A2B' : '#2A1A08')
              .borderRadius(15)
              .onClick(() => { const s = cloneSettings(this.s); s.whiteDecoration = 'tea'; this.apply(s) })
            Button('☕\nCoffee')
              .fontSize(11).height(30).layoutWeight(1)
              .fontColor(this.s.whiteDecoration === 'coffee' ? '#F5F0E8' : '#A09080')
              .backgroundColor(this.s.whiteDecoration === 'coffee' ? '#8B5A2B' : '#2A1A08')
              .borderRadius(15)
              .onClick(() => { const s = cloneSettings(this.s); s.whiteDecoration = 'coffee'; this.apply(s) })
          }
          .width('100%').padding({ left: 16, right: 16, bottom: 8 })

          this.SectionLabel('Black Decoration')
          Row({ space: 8 }) {
            Button('None')
              .fontSize(11).height(30).layoutWeight(1)
              .fontColor(this.s.blackDecoration === 'none' ? '#F5F0E8' : '#A09080')
              .backgroundColor(this.s.blackDecoration === 'none' ? '#8B5A2B' : '#2A1A08')
              .borderRadius(15)
              .onClick(() => { const s = cloneSettings(this.s); s.blackDecoration = 'none'; this.apply(s) })
            Button('☕ Tea')
              .fontSize(11).height(30).layoutWeight(1)
              .fontColor(this.s.blackDecoration === 'tea' ? '#F5F0E8' : '#A09080')
              .backgroundColor(this.s.blackDecoration === 'tea' ? '#8B5A2B' : '#2A1A08')
              .borderRadius(15)
              .onClick(() => { const s = cloneSettings(this.s); s.blackDecoration = 'tea'; this.apply(s) })
            Button('☕ Coffee')
              .fontSize(11).height(30).layoutWeight(1)
              .fontColor(this.s.blackDecoration === 'coffee' ? '#F5F0E8' : '#A09080')
              .backgroundColor(this.s.blackDecoration === 'coffee' ? '#8B5A2B' : '#2A1A08')
              .borderRadius(15)
              .onClick(() => { const s = cloneSettings(this.s); s.blackDecoration = 'coffee'; this.apply(s) })
          }
          .width('100%').padding({ left: 16, right: 16, bottom: 8 })

          Divider().color('#3A2A14').margin({ top: 4, bottom: 4 })

          // --- Tutorial reset ---
          Row() {
            Text('Show Tutorial Again')
              .fontSize(14).fontColor('#F5F0E8').layoutWeight(1)
            Button('Start')
              .width(70).height(30).fontSize(12)
              .fontColor('#C8A060').backgroundColor('#2A1A08').borderRadius(15)
              .onClick(() => {
                const tp: TutorialParams = { fromSettings: true }
                this.navStack.pushPathByName('TutorialPage', tp)
              })
          }
          .width('100%').height(46).padding({ left: 16, right: 16 })

          Blank().height(60)
        }
      }
      .width('100%').height('100%')
      .backgroundColor('#1A0F05')
      .scrollable(ScrollDirection.Vertical)
      .edgeEffect(EdgeEffect.Spring)
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.navStack = context.pathStack
      try {
        const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext
        this.pref = preferences.getPreferencesSync(ctx, { name: 'backgammon_prefs' })
        this.load()
      } catch (_e) {}
    })
  }

  @Builder SectionLabel(label: string) {
    Text(label)
      .fontSize(12).fontColor('#A09080')
      .width('100%').padding({ left: 16, top: 8, bottom: 4 })
  }

  @Builder ToggleRow(label: string, value: boolean, onChange: (v: boolean) => void) {
    Row() {
      Text(label).fontSize(14).fontColor('#F5F0E8').layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: value })
        .width(44).height(24).selectedColor('#8B5A2B')
        .onChange((on: boolean) => onChange(on))
    }
    .width('100%').height(46).padding({ left: 16, right: 16 })
  }

  @Builder ModeBtn(label: string, active: boolean, onClick: () => void) {
    Button(label)
      .fontSize(12).height(32).layoutWeight(1)
      .fontColor(active ? '#F5F0E8' : '#A09080')
      .backgroundColor(active ? '#8B5A2B' : '#2A1A08')
      .borderRadius(16).onClick(onClick)
  }

  @Builder DecoBtn(label: string, _val: string, active: boolean, onClick: () => void) {
    Button(label)
      .fontSize(11).height(30).layoutWeight(1)
      .fontColor(active ? '#F5F0E8' : '#A09080')
      .backgroundColor(active ? '#8B5A2B' : '#2A1A08')
      .borderRadius(15).onClick(onClick)
  }
}
