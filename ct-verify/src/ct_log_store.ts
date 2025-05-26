import { CtLogList, CtLog } from './ct_log_types';

export class CtLogStore {
  public static LOG_LIST_URL = "https://www.gstatic.com/ct/log_list/v3/all_logs_list.json";
  private static FRESH_DATA_THRESHOLD_MS = 3 * 24 * 60 * 60 * 1000;
  private static instance: Promise<CtLogStore> | null = null;

  private version = "";
  private time = new Date("1970-01-01T00:00:00Z");
  private logs: Record<string, CtLog> | null = null;

  private constructor() {}

  public getLogById(logId: string): CtLog | undefined {
    return this.logs[logId];
  }

  private async initLogRecords(): Promise<void> {
    if (this.logs !== null && this.isDataFresh()) {
      return;
    }
    // When data is not already in store, fetch and process it
    this.logs = {};

    const logList = await this.fetchCtLogList();
    for (const operator of logList.operators) {
      if (!operator.logs) {
        continue;
      }
      for (const log of operator.logs) {
        this.logs[log.log_id] = log;
      }
    }

    this.time = new Date(logList.log_list_timestamp);
    this.version = logList.version;
  }

  public addLog(log: CtLog): void {
    if (this.logs === null) {
      throw new Error("Log store not initialized. Call getInstance() first.");
    }
    if (this.logs[log.log_id]) {
      console.warn(`Log with ID ${log.log_id} already exists. Overwriting.`);
    }
    this.logs[log.log_id] = log;
  }

  private async fetchCtLogList(): Promise<CtLogList> {
    const response = await fetch(CtLogStore.LOG_LIST_URL);

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();

    return data;
  }

  private isDataFresh(): boolean {
    const storedTime = this.time.getTime();
    const currentTime = new Date().getTime();
    return currentTime - storedTime < CtLogStore.FRESH_DATA_THRESHOLD_MS;
  }

  public static async getInstance(): Promise<CtLogStore> {
    if (CtLogStore.instance === null) {
      CtLogStore.instance = (async () => {
        const store = new CtLogStore();
        await store.initLogRecords();
        return store;
      })();
    }

    return CtLogStore.instance;
  }
}
