import { AppColors } from '../ui/Theme';

@Component
export struct SectionHeader {
  title: string = '';
  caption: string = '';

  build() {
    Row() {
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT)
      Blank()
      if (this.caption.length > 0) {
        Text(this.caption)
          .fontSize(12)
          .fontColor(AppColors.TEXT_MUTED)
      }
    }
    .width('100%')
  }
}

