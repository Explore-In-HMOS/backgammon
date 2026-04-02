import cryptoFramework from '@ohos.security.cryptoFramework'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN: number = 0x0000
const TAG: string = 'CryptoRandom'
const UINT32_DIVISOR: number = 4294967296

export function getRandomValue(): number {
  try {
    const random: cryptoFramework.Random = cryptoFramework.createRandom()
    const randomBytes: cryptoFramework.DataBlob = random.generateRandomSync(4)
    const view = new DataView(randomBytes.data.buffer, randomBytes.data.byteOffset, 4)
    const randomUint32: number = view.getUint32(0, false)
    return randomUint32 / UINT32_DIVISOR
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Secure random generation failed: %{public}s', JSON.stringify(error))
    return 0.5
  }
}

export function getRandomInt(maxExclusive: number): number {
  if (maxExclusive <= 0) {
    return 0
  }

  return Math.min(maxExclusive - 1, Math.floor(getRandomValue() * maxExclusive))
}

export function rollSecureDie(): number {
  return getRandomInt(6) + 1
}
