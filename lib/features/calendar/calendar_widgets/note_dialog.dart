import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../calendar_uitils.dart';

class EventNoteDialog extends StatefulWidget {
  final String eventTitle;
  final bool isCompleted;

  const EventNoteDialog({
    super.key,
    required this.eventTitle,
    required this.isCompleted,
  });

  @override
  State<EventNoteDialog> createState() => _EventNoteDialogState();
}

class _EventNoteDialogState extends State<EventNoteDialog> {
  final TextEditingController _noteController = TextEditingController();
  List<String> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    setState(() {
      _notes = getEventNotes(widget.eventTitle);
    });
  }

  void _addNote() {
    final text = _noteController.text.trim();
    if (text.isNotEmpty && _notes.length < 3) {
      saveEventNote(widget.eventTitle, text);
      _noteController.clear();
      _loadNotes();
    }
  }

  void _deleteNote(int index) {
    deleteEventNote(widget.eventTitle, index);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.eventTitle,
                    style: GoogleFonts.pressStart2p(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.isCompleted
                  ? "Past Event Memories"
                  : "Event Notes & Reminders",
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Notes List
            if (_notes.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "No notes yet.",
                    style: GoogleFonts.poppins(
                      color: Colors.white30,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ] else ...[
              ...List.generate(_notes.length, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.push_pin_rounded,
                        color: Colors.amberAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _notes[index],
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!widget.isCompleted)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => _deleteNote(index),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: 10),

            // Input Field (Only if not completed & under limit)
            if (!widget.isCompleted && _notes.length < 3) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                maxLength: 60,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Add a short note...",
                  hintStyle: GoogleFonts.poppins(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.black26,
                  counterStyle: GoogleFonts.poppins(
                    color: Colors.white30,
                    fontSize: 10,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.cyanAccent,
                    ),
                    onPressed: _addNote,
                  ),
                ),
                onSubmitted: (_) => _addNote(),
              ),
            ] else if (!widget.isCompleted && _notes.length >= 3) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Note limit reached (3/3)",
                    style: GoogleFonts.poppins(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
