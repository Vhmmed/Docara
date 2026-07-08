import 'package:flutter/material.dart';

class ChipInput extends StatefulWidget {
  final List<String> initialValues;
  final ValueChanged<List<String>> onChanged;
  final String hintText;
  final IconData icon;

  const ChipInput({
    super.key,
    this.initialValues = const [],
    required this.onChanged,
    this.hintText = 'Add item...',
    this.icon = Icons.add,
  });

  @override
  State<ChipInput> createState() => _ChipInputState();
}

class _ChipInputState extends State<ChipInput> {
  late List<String> _items;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialValues);
  }

  void _addItem(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || _items.contains(trimmed)) return;
    setState(() {
      _items.add(trimmed);
      _controller.clear();
    });
    widget.onChanged(List.from(_items));
    _focusNode.requestFocus();
  }

  void _removeItem(String value) {
    setState(() => _items.remove(value));
    widget.onChanged(List.from(_items));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _items
                  .map((item) => Chip(
                        label: Text(item, style: const TextStyle(fontSize: 13)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeItem(item),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: _addItem,
                textInputAction: TextInputAction.done,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(widget.icon),
              onPressed: () => _addItem(_controller.text),
              tooltip: 'Add',
            ),
          ],
        ),
      ],
    );
  }
}
