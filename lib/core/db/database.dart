import 'package:drift/drift.dart';

import 'tables/daily_os.dart';
import 'tables/finance.dart';
import 'tables/ideas.dart';
import 'tables/kronik.dart';
import 'tables/linkku.dart';
import 'tables/profile_meta.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Ideas,
    IdeaCategories,
    Habits,
    HabitSubtasks,
    HabitChecks,
    Todos,
    TodoSubtasks,
    JournalEntries,
    JournalHabitLogs,
    Books,
    BookAccounts,
    Accounts,
    CategoriesFinance,
    FinanceTransactions,
    Members,
    MasterBudgets,
    BudgetsLegacy,
    SavingsPots,
    SavingsEvents,
    SavedLinks,
    LinkCategories,
    LinkTags,
    LinkSecurity,
    Profiles,
    Reminders,
    AppMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
      );
}

List<String> get backupTableNames => const [
      'ideas',
      'idea_categories',
      'habits',
      'habit_subtasks',
      'habit_checks',
      'todos',
      'todo_subtasks',
      'journal_entries',
      'journal_habit_logs',
      'books',
      'book_accounts',
      'accounts',
      'categories_finance',
      'transactions',
      'members',
      'master_budgets',
      'budgets_legacy',
      'savings_pots',
      'savings_events',
      'links',
      'link_categories',
      'link_tags',
      'profile',
      'reminders',
      'app_meta',
    ];
