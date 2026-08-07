import 'package:flutter/material.dart';

import 'package:zennyt/features/jobs/domain/entities/job.dart';
class EmploymentTypeBottomSheet extends StatefulWidget {
  final ContractType selected;

  const EmploymentTypeBottomSheet({super.key, required this.selected});

  static Future<ContractType?> show(BuildContext context, {required ContractType selected}) {
    return showModalBottomSheet<ContractType>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => EmploymentTypeBottomSheet(selected: selected),
    );
  }

  @override
  State<EmploymentTypeBottomSheet> createState() => _EmploymentTypeBottomSheetState();
}

class _EmploymentTypeBottomSheetState extends State<EmploymentTypeBottomSheet> {
  late ContractType _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  void _confirm() => Navigator.of(context).pop(_current);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.60,
      minChildSize: 0.4,
      maxChildSize: 0.80,
      builder: (_, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose the employment type',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF232323),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Determine and choose the type of work according to what you want',
                      style: TextStyle(fontSize: 13, color: Color(0xFF7C8393)),
                    ),
                    SizedBox(height: 12),
                    Divider(color: Color(0xFFEEEEEE), height: 1),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: ContractType.values.map((type) {
                    final isSelected = _current == type;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _current = type),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              type.label,
                              style: TextStyle(
                                fontSize: 15,
                                color: const Color(0xFF232323),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            const Spacer(),
                            Radio<ContractType>(
                              value: type,
                              groupValue: _current,
                              activeColor: const Color(0xFF21438A),
                              onChanged: (val) {
                                if (val != null) setState(() => _current = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF21438A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
