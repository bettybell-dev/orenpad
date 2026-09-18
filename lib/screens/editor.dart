import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

import '../models/novel.dart';
import '../services/storage.dart';

class EditorPage extends StatefulWidget {
  final Chapter chapter;

  const EditorPage({
    super.key,
    required this.chapter,
  });

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late TextEditingController titleController;
  late QuillController quillController;

  Timer? saveTimer;

  bool saving = false;
  bool readerMode = false;

  // Format yang akan dipakai untuk teks berikutnya.
  String currentFontSize = '18';
  String currentFont = 'Default';

  bool currentBold = false;
  bool currentItalic = false;

  final FocusNode editorFocusNode = FocusNode();

  final ScrollController editorScrollController =
      ScrollController();

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.chapter.title,
    );

    quillController = _createController(
      widget.chapter.content,
    );

    titleController.addListener(onTitleChanged);
    quillController.addListener(onContentChanged);
  }

  // ============================================================
  // CONTROLLER
  // ============================================================

  QuillController _createController(String content) {
    try {
      if (content.trim().isNotEmpty) {
        final decoded = jsonDecode(content);

        if (decoded is List) {
          final document = Document.fromJson(decoded);

          return QuillController(
            document: document,
            selection: TextSelection.collapsed(
              offset: _safeDocumentEnd(document),
            ),
          );
        }
      }
    } catch (_) {
      // Data lama bukan Delta JSON.
      // Dibuka sebagai teks biasa.
    }

    final document = Document();

    if (content.isNotEmpty) {
      document.insert(0, content);
    }

    return QuillController(
      document: document,
      selection: TextSelection.collapsed(
        offset: _safeDocumentEnd(document),
      ),
    );
  }

  int _safeDocumentEnd(Document document) {
    final end = document.length - 1;

    if (end < 0) {
      return 0;
    }

    return end;
  }

  // ============================================================
  // AUTOSAVE
  // ============================================================

  void onTitleChanged() {
    widget.chapter.title = titleController.text;

    scheduleSave();

    if (mounted) {
      setState(() {});
    }
  }

  void onContentChanged() {
    scheduleSave();

    if (mounted) {
      setState(() {});
    }
  }

  void scheduleSave() {
    saveTimer?.cancel();

    saveTimer = Timer(
      const Duration(milliseconds: 700),
      save,
    );
  }

  Future<void> save() async {
    if (saving) return;

    saving = true;

    try {
      widget.chapter.title = titleController.text;

      widget.chapter.content = jsonEncode(
        quillController.document.toDelta().toJson(),
      );

      final novels = await StorageService.loadNovels();

      bool found = false;

      for (final novel in novels) {
        for (final chapter in novel.chapters) {
          if (identical(chapter, widget.chapter)) {
            chapter.title = widget.chapter.title;
            chapter.content = widget.chapter.content;
            chapter.status = widget.chapter.status;

            found = true;
            break;
          }
        }

        if (found) break;
      }

      if (found) {
        await StorageService.saveNovels(novels);
      }
    } catch (_) {
      // Penyimpanan gagal tidak membuat aplikasi crash.
    }

    saving = false;

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // WORD COUNT
  // ============================================================

  int get wordCount {
    final text = quillController.document
        .toPlainText()
        .trim();

    if (text.isEmpty) {
      return 0;
    }

    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  // ============================================================
  // STATUS
  // ============================================================

  Color get statusColor {
    switch (widget.chapter.status) {
      case 'revision':
        return Colors.red;

      case 'done':
        return Colors.green;

      default:
        return Colors.orange;
    }
  }

  // ============================================================
  // FORMAT TEXT
  // ============================================================

  void setFontSize(String size) {
    currentFontSize = size;

    // formatSelection pada collapsed selection
    // akan menjadi format untuk teks yang diketik berikutnya.
    quillController.formatSelection(
      Attribute.fromKeyValue(
        Attribute.size.key,
        size,
      ),
    );

    if (mounted) {
      setState(() {});
    }

    editorFocusNode.requestFocus();
  }

  void setFont(String font) {
    currentFont = font;

    if (font == 'Default') {
      quillController.formatSelection(
        Attribute.clone(
          Attribute.font,
          null,
        ),
      );
    } else {
      String value;

      switch (font) {
        case 'Sans':
          value = 'sans-serif';
          break;

        case 'Serif':
          value = 'serif';
          break;

        case 'Mono':
          value = 'monospace';
          break;

        case 'Cambria':
          value = 'Cambria';
          break;

        default:
          value = 'sans-serif';
      }

      quillController.formatSelection(
        Attribute.fromKeyValue(
          Attribute.font.key,
          value,
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }

    editorFocusNode.requestFocus();
  }

  void toggleBold() {
    currentBold = !currentBold;

    if (currentBold) {
      quillController.formatSelection(
        Attribute.bold,
      );
    } else {
      quillController.formatSelection(
        Attribute.clone(
          Attribute.bold,
          null,
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }

    editorFocusNode.requestFocus();
  }

  void toggleItalic() {
    currentItalic = !currentItalic;

    if (currentItalic) {
      quillController.formatSelection(
        Attribute.italic,
      );
    } else {
      quillController.formatSelection(
        Attribute.clone(
          Attribute.italic,
          null,
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }

    editorFocusNode.requestFocus();
  }

  // ============================================================
  // INSERT TEXT
  // ============================================================

  void insertText(String left, String right) {
    final selection = quillController.selection;

    final documentEnd = _safeDocumentEnd(
      quillController.document,
    );

    final start = selection.start < 0
        ? documentEnd
        : selection.start;

    final end = selection.end < 0
        ? start
        : selection.end;

    final fullText =
        quillController.document.toPlainText();

    final safeStart = start.clamp(
      0,
      fullText.length,
    );

    final safeEnd = end.clamp(
      safeStart,
      fullText.length,
    );

    final selectedText = fullText.substring(
      safeStart,
      safeEnd,
    );

    final replacement =
        '$left$selectedText$right';

    quillController.replaceText(
      safeStart,
      safeEnd - safeStart,
      replacement,
      TextSelection.collapsed(
        offset: safeStart +
            left.length +
            selectedText.length,
      ),
    );

    editorFocusNode.requestFocus();
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  void insertDivider() {
    final selection = quillController.selection;

    final index = selection.start < 0
        ? _safeDocumentEnd(
            quillController.document,
          )
        : selection.start;

    const divider = '\n────────────\n';

    quillController.replaceText(
      index,
      0,
      divider,
      TextSelection.collapsed(
        offset: index + divider.length,
      ),
    );

    editorFocusNode.requestFocus();
  }

  // ============================================================
  // IMAGE
  // ============================================================

  Future<void> addImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null ||
        result.files.single.path == null) {
      return;
    }

    final path = result.files.single.path!;

    final selection = quillController.selection;

    final index = selection.start < 0
        ? _safeDocumentEnd(
            quillController.document,
          )
        : selection.start;

    quillController.replaceText(
      index,
      0,
      BlockEmbed.image(path),
      TextSelection.collapsed(
        offset: index + 1,
      ),
    );

    await save();

    if (mounted) {
      editorFocusNode.requestFocus();
    }
  }

  // ============================================================
  // CHAPTER TITLE
  // ============================================================

  Future<void> editChapterTitle() async {
    final controller = TextEditingController(
      text: widget.chapter.title,
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Chapter'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Chapter Title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title = controller.text.trim();

                if (title.isEmpty) {
                  return;
                }

                widget.chapter.title = title;
                titleController.text = title;

                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    await save();
  }

  // ============================================================
  // MENU
  // ============================================================

  Future<void> showMenu() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                ),
                title: const Text('Edit Chapter'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  editChapterTitle();
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf_outlined,
                ),
                title: const Text('Convert PDF'),
                subtitle: const Text(
                  'Not available',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'PDF conversion is not available yet.',
                      ),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.menu_book_outlined,
                ),
                title: const Text('Reader Mode'),
                onTap: () {
                  Navigator.pop(sheetContext);

                  setState(() {
                    readerMode = true;
                  });

                  quillController.readOnly = true;
                  editorFocusNode.unfocus();
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.groups_outlined,
                ),
                title: const Text('Meetings'),
                subtitle: const Text(
                  'Not available',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Meetings are not available yet.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void exitReaderMode() {
    setState(() {
      readerMode = false;
    });

    quillController.readOnly = false;

    editorFocusNode.requestFocus();
  }

  // ============================================================
  // TOOLBAR BUTTON
  // ============================================================

  Widget toolbarButton({
    required Widget child,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 42,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
          ),
          minimumSize: const Size(40, 42),
          tapTargetSize:
              MaterialTapTargetSize.shrinkWrap,
        ),
        child: child,
      ),
    );
  }

  Widget compactIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 42,
        minHeight: 42,
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 20,
        color: active ? Colors.orange : null,
      ),
    );
  }

  // ============================================================
  // TOOLBAR
  // ============================================================

  Widget buildToolbar() {
    const toolbarBackground = Color(0xFF181818);
    const orange = Colors.orange;

    return Material(
      color: toolbarBackground,
      elevation: 6,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 46,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics:
                const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                compactIconButton(
                  icon: Icons.undo,
                  tooltip: 'Undo',
                  onPressed: quillController.undo,
                ),

                compactIconButton(
                  icon: Icons.redo,
                  tooltip: 'Redo',
                  onPressed: quillController.redo,
                ),

                const SizedBox(width: 2),

                // FONT SIZE
                PopupMenuButton<String>(
                  tooltip: 'Text size',
                  onSelected: setFontSize,
                  itemBuilder: (context) {
                    return [
                      for (int size = 14;
                          size <= 24;
                          size++)
                        PopupMenuItem(
                          value: '$size',
                          child: Text('$size'),
                        ),
                    ];
                  },
                  child: Container(
                    height: 40,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      currentFontSize,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // FONT
                PopupMenuButton<String>(
                  tooltip: 'Font',
                  onSelected: setFont,
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(
                        value: 'Default',
                        child: Text('Default'),
                      ),
                      PopupMenuItem(
                        value: 'Sans',
                        child: Text('Sans'),
                      ),
                      PopupMenuItem(
                        value: 'Serif',
                        child: Text('Serif'),
                      ),
                      PopupMenuItem(
                        value: 'Mono',
                        child: Text('Mono'),
                      ),
                      PopupMenuItem(
                        value: 'Cambria',
                        child: Text('Cambria'),
                      ),
                    ];
                  },
                  child: Container(
                    height: 40,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      currentFont,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                compactIconButton(
                  icon: Icons.format_bold,
                  tooltip: 'Bold',
                  onPressed: toggleBold,
                  active: currentBold,
                ),

                compactIconButton(
                  icon: Icons.format_italic,
                  tooltip: 'Italic',
                  onPressed: toggleItalic,
                  active: currentItalic,
                ),

                compactIconButton(
                  icon: Icons.image_outlined,
                  tooltip: 'Add image',
                  onPressed: addImage,
                ),

                const SizedBox(width: 2),

                toolbarButton(
                  onPressed: insertDivider,
                  child: const Text(
                    '—|—',
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),

                toolbarButton(
                  onPressed: () {
                    insertText('(', ')');
                  },
                  child: const Text('(…)'),
                ),

                toolbarButton(
                  onPressed: () {
                    insertText('"', '"');
                  },
                  child: const Text('"…"'),
                ),

                toolbarButton(
                  onPressed: () {
                    insertText("'", "'");
                  },
                  child: const Text("'…'"),
                ),

                toolbarButton(
                  onPressed: () {
                    insertText('', '…');
                  },
                  child: const Text('…'),
                ),

                toolbarButton(
                  onPressed: () {
                    insertText('— ', '');
                  },
                  child: const Text('—'),
                ),

                toolbarButton(
                  onPressed: () {
                    insertText('「', '」');
                  },
                  child: const Text('「…」'),
                ),

                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EDITOR
  // ============================================================

  Widget buildEditor() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        2,
        14,
        2,
      ),
      child: QuillEditor(
        focusNode: editorFocusNode,
        scrollController: editorScrollController,
        controller: quillController,
        config: QuillEditorConfig(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 20,
          ),
          placeholder: 'Start writing...',
          expands: true,
          embedBuilders:
              FlutterQuillEmbeds.editorBuilders(),
        ),
      ),
    );
  }

  // ============================================================
  // READER
  // ============================================================

  Widget buildReader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        20,
      ),
      child: QuillEditor(
        focusNode: editorFocusNode,
        scrollController: editorScrollController,
        controller: quillController,
        config: QuillEditorConfig(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 30,
          ),
          expands: true,
          embedBuilders:
              FlutterQuillEmbeds.editorBuilders(),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    saveTimer?.cancel();

    titleController.removeListener(
      onTitleChanged,
    );

    quillController.removeListener(
      onContentChanged,
    );

    titleController.dispose();
    quillController.dispose();
    editorFocusNode.dispose();
    editorScrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF101010);

    // ==========================================================
    // READER MODE
    // ==========================================================

    if (readerMode) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          elevation: 0,
          toolbarHeight: 50,

          leading: const BackButton(),

          title: Text(
            widget.chapter.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          actions: [
            IconButton(
              tooltip: 'Exit Reader Mode',
              onPressed: exitReaderMode,
              icon: const Icon(
                Icons.edit_outlined,
              ),
            ),
          ],
        ),

        body: buildReader(),
      );
    }

    // ==========================================================
    // EDITOR MODE
    // ==========================================================

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        toolbarHeight: 50,

        leadingWidth: 44,

        leading: const BackButton(),

        titleSpacing: 0,

        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: titleController,
                maxLines: 1,
                decoration:
                    const InputDecoration(
                  hintText: 'Chapter Title',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      EdgeInsets.zero,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 5),

            Text(
              '$wordCount words',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),

            const SizedBox(width: 7),

            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
              ),
            ),

            const SizedBox(width: 6),
          ],
        ),

        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            onPressed: showMenu,
            icon: const Icon(
              Icons.more_vert,
              size: 22,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: buildEditor(),
          ),

          buildToolbar(),
        ],
      ),
    );
  }
}
