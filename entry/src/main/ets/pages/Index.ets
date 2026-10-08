import { DashboardPage } from './DashboardPage';

@Entry
@Component
struct Index {
  build() {
    // DIRECT_ROOT_DASHBOARD_FALLBACK: verified on the physical API 26 device.
    Column() {
      DashboardPage({
        inboxPending: 0,
        taskPending: 0
      })
    }
    .width('100%')
    .height('100%')
  }
}
