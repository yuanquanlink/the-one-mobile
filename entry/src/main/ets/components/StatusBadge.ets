import { AppColors } from '../ui/Theme';

@Component
export struct StatusBadge {
  label: string = '';
  active: boolean = false;

  build() {
    Text(this.label)
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.active ? AppColors.SUCCESS : AppColors.TEXT_SECONDARY)
      .padding({ left: 9, right: 9, top: 4, bottom: 4 })
      .backgroundColor(this.active ? '#173B35' : '#202B3A')
      .borderRadius(999)
  }
}

