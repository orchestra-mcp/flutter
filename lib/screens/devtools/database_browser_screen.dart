import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orchestra/core/theme/color_tokens.dart';
import 'package:orchestra/core/utils/platform_utils.dart';
import 'package:orchestra/features/devtools/providers/database_browser_provider.dart';
import 'package:orchestra/features/devtools/providers/devtools_selection_provider.dart';
import 'package:orchestra/widgets/glass_card.dart';

// ── Driver metadata ─────────────────────────────────────────────────────────

const _drivers = ['postgres', 'sqlite', 'mysql', 'mongodb', 'redis'];

Color _driverColor(String driver) {
  return switch (driver) {
    'postgres' => const Color(0xFF336791),
    'mysql' => const Color(0xFF4479A1),
    'sqlite' => const Color(0xFF003B57),
    'mongodb' => const Color(0xFF47A248),
    'redis' => const Color(0xFFDC382D),
    _ => const Color(0xFF6B7280),
  };
}

IconData _driverIcon(String driver) {
  return switch (driver) {
    'postgres' => Icons.view_in_ar_rounded,
    'mysql' => Icons.dns_rounded,
    'sqlite' => Icons.sd_storage_rounded,
    'mongodb' => Icons.eco_rounded,
    'redis' => Icons.bolt_rounded,
    _ => Icons.storage_rounded,
  };
}

String _driverLabel(String driver) {
  return switch (driver) {
    'postgres' => 'PostgreSQL',
    'mysql' => 'MySQL',
    'sqlite' => 'SQLite',
    'mongodb' => 'MongoDB',
    'redis' => 'Redis',
    _ => driver,
  };
}

// ── Main screen ─────────────────────────────────────────────────────────────

/// Database Browser — list-first master/detail on desktop, tabbed on mobile.
///
/// Desktop: Full-width connections list → click → 2-pane detail (schema+query | results).
/// Mobile: Connections list → connection detail tabs (Schema / Query / Results).
class DatabaseBrowserScreen extends ConsumerStatefulWidget {
  const DatabaseBrowserScreen({super.key});

  @override
  ConsumerState<DatabaseBrowserScreen> createState() =>
      _DatabaseBrowserScreenState();
}

class _DatabaseBrowserScreenState extends ConsumerState<DatabaseBrowserScreen>
    with SingleTickerProviderStateMixin {
  // Selection state
  String? _selectedConnectionId;
  String? _selectedTable;

  // Query state
  final _queryController = TextEditingController();
  DbQueryResult? _queryResult;
  String? _queryError;
  bool _isQuerying = false;

  // Mobile tab controller (Schema / Query / Results)
  late TabController _mobileTabController;


  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _mobileTabController.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _runQuery() async {
    final connId = _selectedConnectionId;
    final sql = _queryController.text.trim();
    if (connId == null || sql.isEmpty) return;

    setState(() {
      _isQuerying = true;
      _queryResult = null;
      _queryError = null;
    });

    try {
      final notifier = ref.read(databaseBrowserProvider.notifier);
      final result = await notifier.query(connId, sql);
      if (mounted) {
        setState(() {
          _queryResult = result;
          _isQuerying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _queryError = e.toString();
          _isQuerying = false;
        });
      }
    }
  }

  void _selectConnection(String connectionId) {
    setState(() {
      _selectedConnectionId = connectionId;
      _selectedTable = null;
      _queryResult = null;
      _queryError = null;
    });
  }

  void _goBack() {
    setState(() {
      _selectedConnectionId = null;
      _selectedTable = null;
      _queryResult = null;
      _queryError = null;
    });
  }

  void _selectTable(String table) {
    setState(() {
      _selectedTable = table;
    });
    if (!isDesktop) {
      _mobileTabController.animateTo(0);
    }
  }

  Future<void> _disconnect(String connectionId) async {
    await ref.read(databaseBrowserProvider.notifier).disconnect(connectionId);
    if (mounted && _selectedConnectionId == connectionId) {
      _goBack();
    }
  }

  void _showConnectDialog() {
    var selectedDriver = _drivers.first;
    final dsnController = TextEditingController();
    final tokens = ThemeTokens.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: tokens.bgAlt,
              title: Text(
                'Connect to Database',
                style: TextStyle(color: tokens.fgBright),
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver dropdown
                    Text(
                      'Driver',
                      style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: tokens.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: tokens.borderFaint,
                          width: 0.5,
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: selectedDriver,
                        isExpanded: true,
                        dropdownColor: tokens.bgAlt,
                        underline: const SizedBox.shrink(),
                        style:
                            TextStyle(color: tokens.fgBright, fontSize: 14),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: tokens.fgMuted,
                        ),
                        items: _drivers.map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Row(
                              children: [
                                Icon(
                                  _driverIcon(d),
                                  size: 16,
                                  color: _driverColor(d),
                                ),
                                const SizedBox(width: 8),
                                Text(_driverLabel(d)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => selectedDriver = v);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // DSN text field
                    Text(
                      'Connection String (DSN)',
                      style: TextStyle(
                        color: tokens.fgMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: dsnController,
                      style: TextStyle(
                        color: tokens.fgBright,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: _dsnPlaceholder(selectedDriver),
                        hintStyle: TextStyle(
                          color: tokens.fgDim.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        filled: true,
                        fillColor: tokens.bg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: tokens.borderFaint,
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: tokens.accent,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: tokens.fgMuted),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final dsn = dsnController.text.trim();
                    if (dsn.isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      final conn = await ref
                          .read(databaseBrowserProvider.notifier)
                          .connect(driver: selectedDriver, dsn: dsn);
                      if (mounted) _selectConnection(conn.id);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Connection failed: $e')),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Connect',
                    style: TextStyle(color: tokens.accent),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => dsnController.dispose());
  }

  String _dsnPlaceholder(String driver) {
    return switch (driver) {
      'postgres' => 'postgres://user:pass@localhost:5432/dbname',
      'mysql' => 'user:pass@tcp(localhost:3306)/dbname',
      'sqlite' => '/path/to/database.db',
      'mongodb' => 'mongodb://localhost:27017/dbname',
      'redis' => 'redis://localhost:6379',
      _ => 'connection string',
    };
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokens.of(context);

    if (isDesktop) {
      return _buildDesktopLayout(tokens);
    }
    return _buildMobileLayout(tokens);
  }

  // ── Desktop: list-first master/detail ────────────────────────────────

  Widget _buildDesktopLayout(OrchestraColorTokens tokens) {
    // On desktop the global sidebar IS the list — sync selection from shared provider.
    final providerId = ref.watch(selectedConnectionIdProvider);
    if (providerId != null && providerId != _selectedConnectionId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectConnection(providerId);
      });
    }

    if (_selectedConnectionId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storage_rounded,
                size: 48, color: tokens.fgDim.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('Select a connection',
                style: TextStyle(
                    color: tokens.fgMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Choose a database connection from the sidebar, or tap + to connect.',
                style: TextStyle(color: tokens.fgDim, fontSize: 13)),
          ],
        ),
      );
    }
    return _buildDesktopDetail(tokens);
  }


  Widget _buildConnectionTile(
    OrchestraColorTokens tokens,
    DbConnection connection,
  ) {
    final driverColor = _driverColor(connection.driver);
    final isConnected = connection.status == 'connected';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: EdgeInsets.zero,
      borderRadius: 12,
      onTap: () => _selectConnection(connection.id),
      child: Row(
        children: [
          // Driver icon circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: driverColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _driverIcon(connection.driver),
              size: 20,
              color: driverColor,
            ),
          ),
          const SizedBox(width: 14),

          // DSN + driver label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverLabel(connection.driver),
                  style: TextStyle(
                    color: tokens.fgBright,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  connection.dsn,
                  style: TextStyle(
                    color: tokens.fgDim,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isConnected
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFF59E0B))
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  connection.status ?? 'unknown',
                  style: TextStyle(
                    color: isConnected
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF59E0B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Disconnect button
          Tooltip(
            message: 'Disconnect',
            child: InkWell(
              onTap: () => _disconnect(connection.id),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.link_off_rounded,
                  size: 16,
                  color: tokens.fgDim.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),

          // Chevron
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: tokens.fgDim.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  // ── Desktop detail (schema+query | results) ───────────────────────────

  Widget _buildDesktopDetail(OrchestraColorTokens tokens) {
    final asyncConnections = ref.watch(databaseBrowserProvider);
    final connection = asyncConnections.value
        ?.where((c) => c.id == _selectedConnectionId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: Column(
        children: [
          // Back bar
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: tokens.borderFaint, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: tokens.fgBright,
                    size: 20,
                  ),
                  onPressed: _goBack,
                  tooltip: 'Back to connections',
                ),
                if (connection != null) ...[
                  Icon(
                    _driverIcon(connection.driver),
                    size: 16,
                    color: _driverColor(connection.driver),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _driverLabel(connection.driver),
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      connection.dsn,
                      style: TextStyle(
                        color: tokens.fgDim,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
              ],
            ),
          ),

          // 2-pane content: center (schema + query) | right (results)
          Expanded(
            child: Row(
              children: [
                // CENTER: Schema viewer + Query editor
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: tokens.borderFaint,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: _buildCenterPane(tokens),
                  ),
                ),

                // RIGHT: Query results
                SizedBox(
                  width: 350,
                  child: _buildResultsPane(tokens),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile: list → connection detail ──────────────────────────────────

  Widget _buildMobileLayout(OrchestraColorTokens tokens) {
    if (_selectedConnectionId == null) {
      return _buildMobileConnectionsList(tokens);
    }
    return _buildMobileDetail(tokens);
  }

  Widget _buildMobileConnectionsList(OrchestraColorTokens tokens) {
    final asyncConnections = ref.watch(databaseBrowserProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: asyncConnections.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: tokens.accent),
          ),
          error: (e, _) => Center(
            child: Text(
              'Failed to load connections:\n$e',
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          data: (connections) {
            if (connections.isEmpty) {
              return _buildEmptyState(
                tokens,
                icon: Icons.storage_rounded,
                title: 'No connections',
                subtitle:
                    'Connect to a database to browse tables and run queries.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: connections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) =>
                  _buildConnectionTile(tokens, connections[i]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showConnectDialog,
        backgroundColor: tokens.accent,
        child: Icon(
          Icons.add_rounded,
          color: tokens.isLight ? Colors.white : tokens.bg,
        ),
      ),
    );
  }

  Widget _buildMobileDetail(OrchestraColorTokens tokens) {
    final asyncConnections = ref.watch(databaseBrowserProvider);
    final connection = asyncConnections.value
        ?.where((c) => c.id == _selectedConnectionId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        backgroundColor: tokens.bgAlt,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tokens.fgBright),
          onPressed: _goBack,
        ),
        title: Text(
          connection != null
              ? _driverLabel(connection.driver)
              : 'Database',
          style: TextStyle(
            color: tokens.fgBright,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: tokens.accent),
            onPressed: _showConnectDialog,
            tooltip: 'Connect',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _mobileTabController,
            labelColor: tokens.accent,
            unselectedLabelColor: tokens.fgMuted,
            indicatorColor: tokens.accent,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Schema'),
              Tab(text: 'Query'),
              Tab(text: 'Results'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _mobileTabController,
        children: [
          _buildSchemaTab(tokens),
          _buildQueryTab(tokens),
          _buildResultsPane(tokens),
        ],
      ),
    );
  }

  // ── Schema tab (mobile) ───────────────────────────────────────────────

  Widget _buildSchemaTab(OrchestraColorTokens tokens) {
    if (_selectedConnectionId == null) {
      return _buildEmptyState(
        tokens,
        icon: Icons.link_off_rounded,
        title: 'No connection selected',
        subtitle: 'Connect to a database to browse its schema.',
      );
    }

    return Column(
      children: [
        if (_selectedTable == null)
          Expanded(child: _buildTablesList(tokens, _selectedConnectionId!))
        else ...[
          _buildSelectedTableHeader(tokens),
          Expanded(child: _buildSchemaViewer(tokens)),
        ],
      ],
    );
  }

  Widget _buildSelectedTableHeader(OrchestraColorTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.bgAlt,
        border: Border(
          bottom: BorderSide(color: tokens.borderFaint, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedTable = null),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: tokens.accent,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.table_chart_rounded, size: 16, color: tokens.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedTable!,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Query tab (mobile) ────────────────────────────────────────────────

  Widget _buildQueryTab(OrchestraColorTokens tokens) {
    if (_selectedConnectionId == null) {
      return _buildEmptyState(
        tokens,
        icon: Icons.code_rounded,
        title: 'No connection selected',
        subtitle: 'Connect to a database to run queries.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildQueryEditor(tokens),
    );
  }

  // ── Center pane (schema + query) — desktop detail ─────────────────────

  Widget _buildCenterPane(OrchestraColorTokens tokens) {
    if (_selectedConnectionId == null) {
      return _buildEmptyState(
        tokens,
        icon: Icons.link_off_rounded,
        title: 'No connection selected',
        subtitle: 'Select a connection from the sidebar to browse its schema.',
      );
    }

    return Column(
      children: [
        // Left panel: tables list (280px) | Schema viewer (rest)
        Expanded(
          flex: 5,
          child: Row(
            children: [
              SizedBox(
                width: 200,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: tokens.borderFaint,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: _buildTablesList(tokens, _selectedConnectionId!),
                ),
              ),
              Expanded(child: _buildSchemaViewer(tokens)),
            ],
          ),
        ),
        // Divider
        Container(height: 0.5, color: tokens.borderFaint),
        // Bottom: Query editor
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _buildQueryEditor(tokens),
          ),
        ),
      ],
    );
  }

  // ── Tables list ───────────────────────────────────────────────────────

  Widget _buildTablesList(OrchestraColorTokens tokens, String connectionId) {
    final asyncTables = ref.watch(dbTablesProvider(connectionId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Text(
            'Tables',
            style: TextStyle(
              color: tokens.fgMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: asyncTables.when(
            loading: () => Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokens.accent,
                ),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Error: $e',
                style: TextStyle(color: tokens.fgMuted, fontSize: 11),
              ),
            ),
            data: (tables) {
              if (tables.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'No tables found',
                    style: TextStyle(color: tokens.fgDim, fontSize: 12),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                itemCount: tables.length,
                itemBuilder: (context, index) {
                  final table = tables[index];
                  final isActive = _selectedTable == table.name;

                  return InkWell(
                    onTap: () => _selectTable(table.name),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(bottom: 1),
                      decoration: BoxDecoration(
                        color: isActive
                            ? tokens.accent.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.table_chart_outlined,
                            size: 14,
                            color: isActive ? tokens.accent : tokens.fgDim,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              table.name,
                              style: TextStyle(
                                color: isActive
                                    ? tokens.accent
                                    : tokens.fgBright,
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (table.rowCount != null)
                            Text(
                              '${table.rowCount}',
                              style: TextStyle(
                                color: tokens.fgDim,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Schema viewer ─────────────────────────────────────────────────────

  Widget _buildSchemaViewer(OrchestraColorTokens tokens) {
    if (_selectedTable == null) {
      return _buildEmptyState(
        tokens,
        icon: Icons.table_chart_outlined,
        title: 'No table selected',
        subtitle: 'Select a table to view its schema.',
      );
    }

    final asyncColumns = ref.watch(
      dbColumnsProvider((
        connectionId: _selectedConnectionId!,
        table: _selectedTable!,
      )),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: tokens.borderFaint, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.table_chart_rounded, size: 16, color: tokens.accent),
              const SizedBox(width: 8),
              Text(
                _selectedTable!,
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Quick query button
              GestureDetector(
                onTap: () {
                  _queryController.text =
                      'SELECT * FROM $_selectedTable LIMIT 50;';
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'SELECT *',
                    style: TextStyle(
                      color: tokens.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Columns list
        Expanded(
          child: asyncColumns.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: tokens.accent),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: TextStyle(color: tokens.fgMuted, fontSize: 13),
              ),
            ),
            data: (columns) {
              if (columns.isEmpty) {
                return Center(
                  child: Text(
                    'No columns found',
                    style: TextStyle(color: tokens.fgDim, fontSize: 13),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: columns.length,
                itemBuilder: (context, index) {
                  return _buildColumnRow(tokens, columns[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColumnRow(OrchestraColorTokens tokens, DbColumn column) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Row(
              children: [
                if (column.primaryKey)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.key_rounded,
                      size: 12,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                Expanded(
                  child: Text(
                    column.name,
                    style: TextStyle(
                      color: tokens.fgBright,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              column.type,
              style: TextStyle(
                color: tokens.accent,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!column.nullable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'NOT NULL',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (column.primaryKey) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PK',
                style: TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (column.defaultValue != null)
            Text(
              '= ${column.defaultValue}',
              style: TextStyle(
                color: tokens.fgDim,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }

  // ── Query editor ──────────────────────────────────────────────────────

  Widget _buildQueryEditor(OrchestraColorTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.code_rounded, size: 16, color: tokens.accent),
            const SizedBox(width: 8),
            Text(
              'SQL Query',
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _selectedConnectionId != null && !_isQuerying
                  ? _runQuery
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _selectedConnectionId != null
                      ? tokens.accent
                      : tokens.fgDim.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isQuerying)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 14,
                        color: _selectedConnectionId != null
                            ? Colors.white
                            : tokens.fgDim,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      'Run',
                      style: TextStyle(
                        color: _selectedConnectionId != null
                            ? Colors.white
                            : tokens.fgDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.borderFaint, width: 0.5),
            ),
            child: TextField(
              controller: _queryController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                color: tokens.fgBright,
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'SELECT * FROM table_name LIMIT 50;',
                hintStyle: TextStyle(
                  color: tokens.fgDim.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
                contentPadding: const EdgeInsets.all(12),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _runQuery(),
            ),
          ),
        ),
      ],
    );
  }

  // ── Results pane ──────────────────────────────────────────────────────

  Widget _buildResultsPane(OrchestraColorTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              Icon(Icons.dataset_rounded, size: 16, color: tokens.accent),
              const SizedBox(width: 8),
              Text(
                'Results',
                style: TextStyle(
                  color: tokens.fgBright,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_queryResult != null) ...[
                _buildBadge(
                  tokens,
                  '${_queryResult!.rowCount} rows',
                  tokens.accent,
                ),
                if (_queryResult!.durationMs != null) ...[
                  const SizedBox(width: 6),
                  _buildBadge(
                    tokens,
                    '${_queryResult!.durationMs}ms',
                    const Color(0xFF22C55E),
                  ),
                ],
              ],
            ],
          ),
        ),
        Container(height: 0.5, color: tokens.borderFaint),
        Expanded(child: _buildResultsContent(tokens)),
      ],
    );
  }

  Widget _buildBadge(OrchestraColorTokens tokens, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildResultsContent(OrchestraColorTokens tokens) {
    if (_queryError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: const Color(0xFFEF4444).withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              const Text(
                'Query Error',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _queryError!,
                style: TextStyle(
                  color: tokens.fgMuted,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_isQuerying) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: tokens.accent),
            const SizedBox(height: 12),
            Text(
              'Running query...',
              style: TextStyle(color: tokens.fgMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_queryResult == null) {
      return _buildEmptyState(
        tokens,
        icon: Icons.table_rows_rounded,
        title: 'Run a query to see results',
        subtitle: 'Write SQL in the editor and press Run.',
      );
    }

    if (_queryResult!.rows.isEmpty) {
      return _buildEmptyState(
        tokens,
        icon: Icons.check_circle_outline_rounded,
        title: 'Query executed successfully',
        subtitle: '0 rows returned.',
      );
    }

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: _buildResultsTable(tokens, _queryResult!),
        ),
      ),
    );
  }

  Widget _buildResultsTable(
    OrchestraColorTokens tokens,
    DbQueryResult result,
  ) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        tokens.bgAlt.withValues(alpha: 0.6),
      ),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return tokens.accent.withValues(alpha: 0.05);
        }
        return Colors.transparent;
      }),
      headingTextStyle: TextStyle(
        color: tokens.fgBright,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      dataTextStyle: TextStyle(
        color: tokens.fgMuted,
        fontSize: 12,
        fontFamily: 'monospace',
      ),
      columnSpacing: 24,
      horizontalMargin: 16,
      border: TableBorder(
        horizontalInside: BorderSide(
          color: tokens.borderFaint,
          width: 0.5,
        ),
      ),
      columns: result.columns.map((col) {
        return DataColumn(label: Text(col));
      }).toList(),
      rows: result.rows.map((row) {
        return DataRow(
          cells: result.columns.map((col) {
            final value = row[col];
            return DataCell(
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  value?.toString() ?? 'NULL',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: value == null
                      ? TextStyle(
                          color: tokens.fgDim.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  // ── Shared empty state ────────────────────────────────────────────────

  Widget _buildEmptyState(
    OrchestraColorTokens tokens, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: tokens.fgDim.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: tokens.fgMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: tokens.fgDim, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
