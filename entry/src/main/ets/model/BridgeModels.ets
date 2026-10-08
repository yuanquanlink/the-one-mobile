export class BridgeResult {
  success: boolean;
  message: string;
  responseCode: number;
  data: string;

  constructor(success: boolean, message: string, responseCode: number = 0, data: string = '') {
    this.success = success;
    this.message = message;
    this.responseCode = responseCode;
    this.data = data;
  }
}

export class BrainSearchResult {
  id: string;
  title: string;
  excerpt: string;

  constructor(id: string, title: string, excerpt: string) {
    this.id = id;
    this.title = title;
    this.excerpt = excerpt;
  }
}

export class BridgeSearchHit {
  path: string = '';
  title: string = '';
  excerpt: string = '';
}

export class BridgeSearchResponse {
  capability: string = '';
  obsidianConnected: boolean = false;
  query: string = '';
  hits: Array<BridgeSearchHit> = [];
}

export class BridgeTaskData {
  id: string = '';
  status: string = '';
  result: string = '';
}

export class BridgeTaskResponse {
  task: BridgeTaskData = new BridgeTaskData();
}

export class InboxSyncPayload {
  id: string;
  content: string;
  type: string;
  tags: Array<string>;
  upsert: boolean;

  constructor(id: string, content: string, type: string, tags: Array<string>) {
    this.id = id;
    this.content = content;
    this.type = type;
    this.tags = tags;
    this.upsert = true;
  }
}

export class TaskSyncPayload {
  id: string;
  title: string;
  description: string;
  status: string;
  upsert: boolean;

  constructor(id: string, title: string, description: string, status: string) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.status = status;
    this.upsert = true;
  }
}

export class BrainSearchRequest {
  query: string;

  constructor(query: string) {
    this.query = query;
  }
}
