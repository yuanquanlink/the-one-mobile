import { AppColors } from '../ui/Theme';

@Component
export struct ControlCard {
  eyebrow: string = '';
  title: string = '';
  value: number = 0;
  valueText: string = '';
  unit: string = '项待处理';
  onOpen: () => void = (): void => {};

  build() {
    Column() {
      Row() {
        Text(this.eyebrow)
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_MUTED)
          .letterSpacing(1)
        Blank()
        Text('›')
          .fontSize(24)
          .fontColor(AppColors.TEXT_MUTED)
      }
      .width('100%')

      Blank()

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT)
        .width('100%')

      Row({ space: 7 }) {
        Text(this.valueText.length > 0 ? this.valueText : `${this.value}`)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)
        Text(this.unit)
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .width('100%')
      .margin({ top: 6 })
    }
    .height(142)
    .padding(16)
    .backgroundColor(AppColors.SURFACE)
    .border({ width: 1, color: AppColors.BORDER })
    .borderRadius(18)
    .onClick(this.onOpen)
  }
}
