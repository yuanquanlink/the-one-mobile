import { InboxType } from '../model/InboxItem';
import { inboxTypeLabel } from '../utils/DisplayText';
import { AppColors } from '../ui/Theme';

@Component
export struct TypeBadge {
  type: InboxType = InboxType.IDEA;

  build() {
    Text(inboxTypeLabel(this.type))
      .fontSize(11)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.PRIMARY)
      .padding({ left: 9, right: 9, top: 4, bottom: 4 })
      .backgroundColor(AppColors.PRIMARY_SOFT)
      .borderRadius(999)
  }
}

