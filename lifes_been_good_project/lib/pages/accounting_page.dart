/*
 * @Date: 2026-04-15 11:48:42
 * @Github: https://github.com/AndroidFreeman
 * Now, I use my Codespace
 * @Author: Android_Freeman
 * @LastEditTime: 2026-04-15 11:48:45
 * @FilePath: /Code/lifes_been_good_project/lib/pages/accounting_page.dart
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/accounting_record.dart';
import '../state/session.dart';
import '../widgets/expressive_ui.dart';

class AccountingPage extends StatefulWidget {
  final Session session;
  final VoidCallback? onReady;

  static const List<
          ({String id, String label_cn, String label_en, IconData icon})>
      categories = [
    (
      id: 'meals',
      label_cn: '三餐',
      label_en: 'Meals',
      icon: Icons.restaurant_rounded
    ),
    (
      id: 'snacks',
      label_cn: '零食/饮料',
      label_en: 'Snacks',
      icon: Icons.takeout_dining_rounded
    ),
    (
      id: 'clothes',
      label_cn: '衣服',
      label_en: 'Clothes',
      icon: Icons.checkroom_rounded
    ),
    (
      id: 'transport',
      label_cn: '交通',
      label_en: 'Transport',
      icon: Icons.directions_bus_rounded
    ),
    (
      id: 'phone',
      label_cn: '话费网费',
      label_en: 'Phone/Net',
      icon: Icons.phone_android_rounded
    ),
    (
      id: 'study',
      label_cn: '学习',
      label_en: 'Study',
      icon: Icons.menu_book_rounded
    ),
    (
      id: 'daily',
      label_cn: '日用品',
      label_en: 'Daily',
      icon: Icons.shopping_bag_rounded
    ),
    (
      id: 'medical',
      label_cn: '医疗',
      label_en: 'Medical',
      icon: Icons.medical_services_rounded
    ),
    (
      id: 'entertainment',
      label_cn: '娱乐',
      label_en: 'Fun',
      icon: Icons.videogame_asset_rounded
    ),
    (
      id: 'electronics',
      label_cn: '电器数码',
      label_en: 'Gadgets',
      icon: Icons.camera_alt_rounded
    ),
    (
      id: 'utility',
      label_cn: '水费/电费',
      label_en: 'Utility',
      icon: Icons.water_drop_rounded
    ),
    (
      id: 'other',
      label_cn: '其它',
      label_en: 'Others',
      icon: Icons.more_horiz_rounded
    ),
  ];

  const AccountingPage({super.key, required this.session, this.onReady});

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> {
  List<AccountingRecord> _records = [];
  bool _loading = true;

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  String _filterType = 'all'; // all, balance, income, expense

  @override
  void initState() {
    super.initState();
    _loadRecords();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady?.call();
    });
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    final allRecords = await widget.session.accounting.listRecords();
    if (mounted) {
      setState(() {
        final myId = widget.session.isTeacher
            ? widget.session.profile.staffNo
            : widget.session.profile.studentNo;
        if (widget.session.isTeacher) {
          _records = allRecords;
        } else {
          _records = allRecords.where((r) => r.studentId == myId).toList();
        }
        _loading = false;
      });
    }
  }

  double get _monthIncome => _records
      .where((r) =>
          r.type == 0 &&
          r.timestamp.startsWith(
              '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}'))
      .fold(0.0, (sum, r) => sum + r.amount);

  double get _monthExpense => _records
      .where((r) =>
          r.type == 1 &&
          r.timestamp.startsWith(
              '${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}'))
      .fold(0.0, (sum, r) => sum + r.amount);

  List<AccountingRecord> get _filteredRecords {
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final daily = _records.where((r) => r.timestamp.startsWith(dateStr));

    if (_filterType == 'income')
      return daily.where((r) => r.type == 0).toList();
    if (_filterType == 'expense')
      return daily.where((r) => r.type == 1).toList();
    return daily.toList();
  }

  IconData _getCategoryIcon(String categoryName) {
    try {
      return AccountingPage.categories
          .firstWhere((c) => c.label_cn == categoryName)
          .icon;
    } catch (_) {
      return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent, // Adapt to ShellPage background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: InkWell(
          onTap: () => _showMonthPicker(loc),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_focusedMonth.year}.${_focusedMonth.month.toString().padLeft(2, '0')}',
                style: tt.titleLarge?.copyWith(
                    color: cs.onSurface, fontWeight: FontWeight.bold),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurface),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: cs.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildCalendar(cs, tt),
                      _buildFilterBar(loc, cs, tt),
                      _buildSummaryRow(loc, tt, cs),
                    ],
                  ),
                ),
                _filteredRecords.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            loc.t('暂无记录', 'No records found'),
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final record = _filteredRecords[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Dismissible(
                                key: Key(record.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 204),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(Icons.delete_sweep_rounded,
                                      color: Colors.white, size: 28),
                                ),
                                confirmDismiss: (direction) =>
                                    _showDeleteConfirm(record),
                                onDismissed: (direction) {
                                  // The actual deletion happens in _showDeleteConfirm
                                },
                                child: _buildRecordTile(record, loc, cs),
                              ),
                            );
                          },
                          childCount: _filteredRecords.length,
                        ),
                      ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
      floatingActionButton: _buildFloatingButtons(loc, cs),
    );
  }

  Widget _buildCalendar(ColorScheme cs, TextTheme tt) {
    final daysInMonth =
        DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayOffset =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      margin: const EdgeInsets.symmetric(horizontal: 100, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 204),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 128)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['一', '二', '三', '四', '五', '六', '日']
                .map((d) => SizedBox(
                      width: 16,
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 7)),
                      ),
                    ))
                .toList(),
          ),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              childAspectRatio: 1.0,
            ),
            itemCount: daysInMonth + firstDayOffset,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) return const SizedBox.shrink();
              final day = index - firstDayOffset + 1;
              final date =
                  DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              final isToday = DateUtils.isSameDay(date, DateTime.now());

              return InkWell(
                onTap: () => setState(() => _selectedDate = date),
                borderRadius: BorderRadius.circular(4),
                child: Center(
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary
                          : isToday
                              ? cs.primary.withValues(alpha: 51)
                              : null,
                      borderRadius: BorderRadius.circular(4),
                      border: isToday && !isSelected
                          ? Border.all(color: cs.primary, width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          color: isSelected ? cs.onPrimary : cs.onSurface,
                          fontWeight:
                              isSelected || isToday ? FontWeight.bold : null,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(LocaleProvider loc, ColorScheme cs, TextTheme tt) {
    final filterOptions = [
      (id: 'all', label: loc.t('收&支', 'All')),
      (id: 'balance', label: loc.t('结余', 'Balance')),
      (id: 'income', label: loc.t('收入', 'Income')),
      (id: 'expense', label: loc.t('支出', 'Expense')),
    ];

    return Container(
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 100),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 204),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 128)),
      ),
      child: Row(
        children: filterOptions.map((opt) {
          final isSelected = _filterType == opt.id;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _filterType = opt.id),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? cs.primaryContainer : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  opt.label,
                  style: TextStyle(
                    color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryRow(LocaleProvider loc, TextTheme tt, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${loc.t('月收入', 'Income')}:${_monthIncome.toStringAsFixed(2)}  '
            '${loc.t('月支出', 'Expense')}:${_monthExpense.toStringAsFixed(2)}  '
            '${loc.t('月结余', 'Balance')}:${(_monthIncome - _monthExpense).toStringAsFixed(2)}',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons(LocaleProvider loc, ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'add_record',
          onPressed: _showAddDialog,
          backgroundColor: cs.primary,
          child: Icon(Icons.add, color: cs.onPrimary),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.small(
          heroTag: 'go_today',
          onPressed: () => setState(() {
            _selectedDate = DateTime.now();
            _focusedMonth = DateTime.now();
          }),
          backgroundColor: cs.surfaceContainerHigh.withValues(alpha: 204),
          child: Text(loc.t('今', 'Now'), style: TextStyle(color: cs.onSurface)),
        ),
      ],
    );
  }

  void _showMonthPicker(LocaleProvider loc) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _focusedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (date != null) {
      setState(() {
        _focusedMonth = DateTime(date.year, date.month);
        _selectedDate = DateTime(date.year, date.month, 1);
      });
    }
  }

  Widget _buildRecordTile(
      AccountingRecord record, LocaleProvider loc, ColorScheme cs) {
    final isIncome = record.type == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ExpressiveCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isIncome
                  ? Colors.green.withValues(alpha: 26)
                  : Colors.red.withValues(alpha: 26),
              child: Icon(
                _getCategoryIcon(record.category),
                color: isIncome ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.category,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  if (record.description.isNotEmpty)
                    Text(
                      record.description,
                      style:
                          TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${record.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (widget.session.isTeacher)
                  Text(
                    record.studentId,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(AccountingRecord record) {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.t('确认删除', 'Confirm Delete')),
        content: Text(loc.t(
            '确定要删除这条记录吗？', 'Are you sure you want to delete this record?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.t('取消', 'Cancel')),
          ),
          TextButton(
            onPressed: () async {
              final ok =
                  await widget.session.accounting.deleteRecord(record.id);
              if (mounted) Navigator.pop(context, ok);
              if (ok) _loadRecords();
            },
            child: Text(loc.t('删除', 'Delete'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final loc = Provider.of<LocaleProvider>(context, listen: false);
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int type = 1; // Default expense
    String selectedCategoryId = 'meals';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            title: Text(loc.t('添加记录', 'Add Record')),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(
                            value: 0, label: Text(loc.t('收入', 'Income'))),
                        ButtonSegment(
                            value: 1, label: Text(loc.t('支出', 'Expense'))),
                      ],
                      selected: {type},
                      onSelectionChanged: (val) {
                        setDialogState(() => type = val.first);
                      },
                    ),
                    const SizedBox(height: 24),
                    // Category Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: AccountingPage.categories.length,
                      itemBuilder: (context, index) {
                        final cat = AccountingPage.categories[index];
                        final isSelected = selectedCategoryId == cat.id;
                        return InkWell(
                          onTap: () {
                            setDialogState(() => selectedCategoryId = cat.id);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cs.primaryContainer
                                      : cs.surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  cat.icon,
                                  color: isSelected
                                      ? cs.onPrimaryContainer
                                      : cs.onSurfaceVariant,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                loc.t(cat.label_cn, cat.label_en),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: amountCtrl,
                      decoration:
                          InputDecoration(labelText: loc.t('金额', 'Amount')),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                          labelText: loc.t('备注', 'Description')),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.t('取消', 'Cancel')),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text) ?? 0;
                  if (amount <= 0) return;

                  final myId = widget.session.isTeacher
                      ? widget.session.profile.staffNo
                      : widget.session.profile.studentNo;

                  final selectedCategory = AccountingPage.categories
                      .firstWhere((c) => c.id == selectedCategoryId);

                  final ok = await widget.session.accounting.addRecord(
                    studentId: myId,
                    amount: amount,
                    type: type,
                    category: selectedCategory.label_cn,
                    description: descCtrl.text,
                  );

                  if (mounted) Navigator.pop(context);
                  if (ok) _loadRecords();
                },
                child: Text(loc.t('保存', 'Save')),
              ),
            ],
          );
        },
      ),
    );
  }
}
