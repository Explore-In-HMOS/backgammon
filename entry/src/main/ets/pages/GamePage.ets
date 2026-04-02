import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { GamePageParams } from '../model/GameTypes'
import { GameStateModel } from '../model/GameStateModel'
import { GameView } from '../components/GameView'
import { runAITurn } from '../engine/GameAITurnLogic'
import { endTurn, stopAnim } from '../engine/GameMoveLogic'

@Component
export struct GamePage {
  @State model: GameStateModel = new GameStateModel()
  private navStack: NavPathStack = new NavPathStack()

  aboutToAppear(): void {
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext
      this.model.ctx = ctx
      this.model.pref = preferences.getPreferencesSync(ctx, { name: 'backgammon_prefs' })
    } catch (_e) {}

    this.model.cbNavigateWin = (p) => { this.navStack.pushPathByName('WinPage', p) }
    this.model.cbNavPop = () => { this.navStack.pop() }
    this.model.cbScheduleAITurn = () => { setTimeout(() => { runAITurn(this.model) }, 500) }
    this.model.cbEndTurn = () => { endTurn(this.model) }
  }

  aboutToDisappear(): void {
    stopAnim(this.model)
  }

  build() {
    NavDestination() {
      GameView({ model: this.model })
    }
    .hideTitleBar(true)
    .onBackPressed((): boolean => { return true })
    .onReady((context: NavDestinationContext) => {
      this.navStack = context.pathStack
      this.model.initGame(context.pathInfo.param as GamePageParams | undefined)
    })
    .onAppear(() => {
      if (!this.model.gameInited) {
        this.model.initGame(undefined)
      }
    })
  }
}
