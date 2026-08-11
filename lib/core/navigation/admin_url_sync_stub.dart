void replaceAdminBrowserUrl(String path) {}

void resetAdminBrowserHistory(String path) {}

void pushAdminBrowserHistory(String path) {}

bool get adminBrowserHistoryAvailable => false;

void goAdminBrowserBack() {}

void ensureAdminPopStateInstalled(void Function() onPop) {}

void persistAdminCmsPath(String path) {}

String? readPersistedAdminCmsPath() => null;
