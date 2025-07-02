import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class RoutineTableView extends StatefulWidget {
  final List<List<String>> sectionA;
  final List<List<String>> sectionB;

  const RoutineTableView({
    super.key,
    required this.sectionA,
    required this.sectionB,
  });

  @override
  State<RoutineTableView> createState() => _RoutineTableViewState();
}

class _RoutineTableViewState extends State<RoutineTableView>
    with SingleTickerProviderStateMixin {
  late List<DataRow> _rows = [];
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;
  String _currentSection = 'Section B';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _scale = Tween<double>(
      begin: 0.95,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _loadSection();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSection() async {
    final prefs = await SharedPreferences.getInstance();
    final section = prefs.getString('section') ?? 'Section B';
    setState(() {
      _currentSection = section;
      _rows = _currentSection == 'Section A'
          ? _generateRows(widget.sectionA)
          : _generateRows(widget.sectionB);
    });
    _controller.forward();
  }

  List<DataRow> _generateRows(List<List<String>> data) {
    return List.generate(data.length, (index) {
      return DataRow(
        cells: List.generate(data[index].length, (cellIndex) {
          return DataCell(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: AnimatedText(
                text: data[index][cellIndex],
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          );
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasData = widget.sectionA.isNotEmpty && widget.sectionB.isNotEmpty;
    final columns = hasData
        ? List.generate(
            widget.sectionA[0].length,
            (index) => DataColumn2(
              label: GlassHeader(text: widget.sectionA[0][index]),
              size: ColumnSize.L,
            ),
          )
        : <DataColumn2>[];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 10,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 3, 236, 244)),
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [Color.fromARGB(255, 153, 200, 214), Color(0xFF00DBDE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: const Text(
            'Timetable',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E0E2C), Color(0xFF0E0E2C)],
          ),
        ),
        child: Center(
          child: hasData
              ? Column(
                  children: [
                    const SizedBox(height: 25),
                    _buildSectionSelector(),
                    const SizedBox(height: 25),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fade.value,
                            child: Transform.scale(
                              scale: _scale.value,
                              child: GlassTable(
                                child: DataTable2(
                                  columnSpacing: 12,
                                  horizontalMargin: 12,
                                  minWidth: 1000,
                                  headingRowHeight: 0,
                                  dividerThickness: 0,
                                  dataRowHeight: 90,
                                  columns: columns,
                                  rows: _rows,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                )
              : const Center(
                  child: Text(
                    "No timetable data available",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C3483), Color(0xFF0F3460)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: DropdownButton<String>(
        value: _currentSection,
        dropdownColor: const Color(0xFF1A1A2E),
        icon: Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
        iconSize: 32,
        underline: const SizedBox(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        items: ['Section A', 'Section B'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Row(
              children: [
                Icon(Icons.class_, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 12),
                Text(value),
              ],
            ),
          );
        }).toList(),
        onChanged: (String? newValue) async {
          if (newValue != null) {
            setState(() {
              _currentSection = newValue;
              _rows = newValue == 'Section A'
                  ? _generateRows(widget.sectionA)
                  : _generateRows(widget.sectionB);
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('section', newValue);
            _controller.reset();
            _controller.forward();
          }
        },
      ),
    );
  }
}

class GlassTable extends StatelessWidget {
  final Widget child;
  const GlassTable({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.cyanAccent.withValues(alpha: 0.05),
            Colors.deepPurple.withValues(alpha: 0.07),
          ],
        ),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: child,
        ),
      ),
    );
  }
}

class GlassHeader extends StatelessWidget {
  final String text;
  const GlassHeader({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C3483), Color(0xFF00DBDE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const AnimatedText({super.key, required this.text, required this.style});

  @override
  State<AnimatedText> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(_controller);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Text(widget.text, style: widget.style),
      ),
    );
  }
}
