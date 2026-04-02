// DiceComponent.ets — Dice faces for wearable backgammon
const DICE_PIPS: boolean[][] = [
  [false, false, false,  false, true,  false,  false, false, false], // 1
  [false, false, true,   false, false, false,  true,  false, false], // 2
  [false, false, true,   false, true,  false,  true,  false, false], // 3
  [true,  false, true,   false, false, false,  true,  false, true],  // 4
  [true,  false, true,   false, true,  false,  true,  false, true],  // 5
  [true,  false, true,   true,  false, true,   true,  false, true],  // 6
]

interface PipItem {
  pip: boolean
  key: string
}

const DICE_PIP_ITEMS: PipItem[][] = DICE_PIPS.map((face: boolean[], fi: number) =>
face.map((pip: boolean, pi: number): PipItem => ({ pip, key: `d${fi + 1}p${pi}` }))
)

@Component
// eslint-disable-next-line @performance/avoid-overusing-custom-component-check
export struct DiceFace {
  @Prop value: number = 1
  @Prop used: boolean = false
  @Prop faceSize: number = 44
  @Prop accentColor: string = '#C8A060'

  build() {
    Stack() {
      Rect()
        .width(this.faceSize)
        .height(this.faceSize)
        .borderRadius(this.faceSize * 0.18)
        .fill(this.used ? '#4A4540' : '#F2EFE4')

      if (this.value >= 1 && this.value <= 6) {
        Grid() {
          ForEach(
            DICE_PIP_ITEMS[this.value - 1],
            (item: PipItem) => {
              GridItem() {
                if (item.pip) {
                  Circle()
                    .width(this.faceSize * 0.21)
                    .height(this.faceSize * 0.21)
                    .fill(this.used ? '#888880' : '#2B1F0E')
                } else {
                  Column()
                    .width(this.faceSize * 0.21)
                    .height(this.faceSize * 0.21)
                }
              }
            },
            (item: PipItem) => item.key
          )
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr')
        .width(this.faceSize * 0.82)
        .height(this.faceSize * 0.82)
        .padding(this.faceSize * 0.08)
      }
    }
    .width(this.faceSize)
    .height(this.faceSize)
    .shadow({ radius: this.used ? 0 : 4, color: '#00000044', offsetX: 2, offsetY: 2 })
  }
}
