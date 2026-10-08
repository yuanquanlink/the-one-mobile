function pad(value: number): string {
  return value < 10 ? `0${value}` : `${value}`;
}

export function formatDateTime(timestamp: number): string {
  const date: Date = new Date(timestamp);
  return `${date.getFullYear()}.${pad(date.getMonth() + 1)}.${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

export function greetingForNow(): string {
  const hour: number = new Date().getHours();
  if (hour < 6) {
    return '夜深了';
  }
  if (hour < 12) {
    return '早上好';
  }
  if (hour < 18) {
    return '下午好';
  }
  return '晚上好';
}

