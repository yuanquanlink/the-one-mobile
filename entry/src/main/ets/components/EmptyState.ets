import { AppColors } from '../ui/Theme';

@Component
export struct EmptyState {
  title: string = '';
  message: string = '';

  build() {
    Column({ space: 10 }) {
      Stack() {
        Text('·')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)
      }
      .width(52)
      .height(52)
      .borderRadius(26)
      .backgroundColor(AppColors.PRIMARY_SOFT)

      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT)

      Text(this.message)
        .fontSize(13)
        .fontColor(AppColors.TEXT_MUTED)
        .textAlign(TextAlign.Center)
        .lineHeight(20)
        .maxLines(3)
    }
    .width('100%')
    .padding({ top: 56, bottom: 40, left: 32, right: 32 })
  }
}

