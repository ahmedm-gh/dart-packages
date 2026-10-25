import 'package:dependency_box/dependency_box.dart';

class SessionQueryEngine {
  final String userId;
  final DateTime initializedAt = DateTime.now();

  SessionQueryEngine(this.userId);

  void executeQuery(String sql) {
    print('[$userId @ ${initializedAt.toIso8601String()}] Executing: $sql');
  }
}

// Arguments record / object
class PaginationArgs {
  final int page;
  final int pageSize;
  const PaginationArgs({required this.page, required this.pageSize});
}

class PaginatedListFetcher {
  final PaginationArgs pagination;
  PaginatedListFetcher(this.pagination);

  void fetch() {
    print(
        'Fetching items page ${pagination.page} (size: ${pagination.pageSize})');
  }
}

void main() {
  print('=== 04 Parameterized Factory Example ===\n');

  final box = DependencyBox.main();

  // 1. Parameterized factory accepting a String argument
  box.addFactoryWith<SessionQueryEngine, String>(
    (container, userId) => SessionQueryEngine(userId),
  );

  // 2. Parameterized factory accepting a custom Argument object
  box.addFactoryWith<PaginatedListFetcher, PaginationArgs>(
    (container, args) => PaginatedListFetcher(args),
  );

  // Resolve with String argument
  final user1Engine = box.get<SessionQueryEngine>(args: 'user_alice_123');
  final user2Engine = box.get<SessionQueryEngine>(args: 'user_bob_456');

  user1Engine.executeQuery('SELECT * FROM orders WHERE status = "pending"');
  user2Engine.executeQuery('SELECT balance FROM accounts WHERE active = true');

  // Resolve with Object argument
  final fetcher = box.get<PaginatedListFetcher>(
    args: const PaginationArgs(page: 1, pageSize: 25),
  );
  fetcher.fetch();

  print('\nParameterized factory instances created and verified cleanly.');
}
