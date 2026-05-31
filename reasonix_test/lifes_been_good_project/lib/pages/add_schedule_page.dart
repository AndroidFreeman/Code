import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/schedule_event.dart';
import '../services/database_helper.dart';
import '../state/session.dart';
import '../state/locale_provider.dart';

class AddSchedulePage extends StatefulWidget {
  final Session session;
  final ScheduleEvent? event;

  const AddSchedulePage({super.key, required this.session, this.event});

  @override
  State<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime =
      TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);

  String _type = '工作';
  String _color = 'FF2196F3'; // Blue

  final List<String> _defaultTypes = ['学习', '工作', '运动', '生活', '其他'];
  final List<String> _colors = [
    'FF2196F3',
    'FFF44336',
    'FF4CAF50',
    'FFFF9800',
    'FF9C27B0'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _locationController.text = widget.event!.location;
      _noteController.text = widget.event!.note;
      _type = widget.event!.type;
      _color = widget.event!.backgroundColor;

      try {
        final startDt = DateTime.parse(widget.event!.startTime);
        _startDate = startDt;
        _startTime = TimeOfDay.fromDateTime(startDt);

        final endDt = DateTime.parse(widget.event!.endTime);
        _endDate = endDt;
        _endTime = TimeOfDay.fromDateTime(endDt);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入标题')));
      return;
    }

    final startStr =
        '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')} ${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
    final endStr =
        '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')} ${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00';

    final event = ScheduleEvent(
      id: widget.event?.id ?? 'se_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      location: _locationController.text.trim(),
      startTime: startStr,
      endTime: endStr,
      type: _type,
      backgroundColor: _color,
      note: _noteController.text.trim(),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await DatabaseHelper.instance.insertScheduleEvent(event);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    if (widget.event != null) {
      await DatabaseHelper.instance.deleteScheduleEvent(widget.event!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null
            ? loc.t('添加日程', 'Add Schedule')
            : loc.t('编辑日程', 'Edit Schedule')),
        actions: [
          if (widget.event != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
                labelText: loc.t('标题', 'Title'),
                border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
                labelText: loc.t('地点', 'Location'),
                border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(loc.t('开始时间', 'Start Time')),
            subtitle: Text(
                '${_startDate.year}-${_startDate.month}-${_startDate.day} ${_startTime.format(context)}'),
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100));
              if (d != null) {
                final t = await showTimePicker(
                    context: context, initialTime: _startTime);
                if (t != null) {
                  setState(() {
                    _startDate = d;
                    _startTime = t;
                  });
                }
              }
            },
          ),
          ListTile(
            title: Text(loc.t('结束时间', 'End Time')),
            subtitle: Text(
                '${_endDate.year}-${_endDate.month}-${_endDate.day} ${_endTime.format(context)}'),
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100));
              if (d != null) {
                final t = await showTimePicker(
                    context: context, initialTime: _endTime);
                if (t != null) {
                  setState(() {
                    _endDate = d;
                    _endTime = t;
                  });
                }
              }
            },
          ),
          const SizedBox(height: 16),
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _type),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return _defaultTypes;
              }
              return _defaultTypes.where((String option) {
                return option.contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              setState(() {
                _type = selection;
              });
            },
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
              // Ensure we capture user typed input that isn't selected from the list
              textEditingController.addListener(() {
                _type = textEditingController.text;
              });
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                    labelText:
                        loc.t('类型 (可输入新类型)', 'Type (can input new type)'),
                    border: const OutlineInputBorder()),
              );
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _color,
            decoration: InputDecoration(
                labelText: loc.t('颜色', 'Color'),
                border: const OutlineInputBorder()),
            items: _colors
                .map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Container(
                            width: 16,
                            height: 16,
                            color: Color(int.parse(c, radix: 16))),
                        const SizedBox(width: 8),
                        Text('#$c'),
                      ],
                    )))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _color = v);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
                labelText: loc.t('备注', 'Note'),
                border: const OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}
