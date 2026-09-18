import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/novel.dart';
import '../services/storage.dart';
import 'editor.dart';

class NovelPage extends StatefulWidget {
  final Novel novel;
  final bool openEdit;

  const NovelPage({
    super.key,
    required this.novel,
    this.openEdit = false,
  });

  @override
  State<NovelPage> createState() => _NovelPageState();
}

class _NovelPageState extends State<NovelPage> {
  Future<void> save({String? originalTitle}) async {
    final novels = await StorageService.loadNovels();

    final index = novels.indexWhere(
      (novel) =>
          novel.title == (originalTitle ?? widget.novel.title),
    );

    if (index != -1) {
      novels[index] = widget.novel;
      await StorageService.saveNovels(novels);
    }
  }

  Future<void> pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    setState(() {
      widget.novel.coverPath = result.files.single.path;
    });

    await save();
  }

  Future<void> editNovel() async {
    final oldTitle = widget.novel.title;

    final titleController = TextEditingController(
      text: widget.novel.title,
    );

    final descriptionController = TextEditingController(
      text: widget.novel.description,
    );

    final tagController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void addTag() {
              final tag = tagController.text.trim();

              if (tag.isEmpty) return;

              if (!widget.novel.tags.contains(tag)) {
                setDialogState(() {
                  widget.novel.tags.add(tag);
                  tagController.clear();
                });
              }
            }

            return AlertDialog(
              title: const Text('Edit Novel'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // COVER
                    const Text(
                      'Cover',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    GestureDetector(
                      onTap: () async {
                        await pickCover();
                        setDialogState(() {});
                      },
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFF1C1C1C),
                        ),
                        child: widget.novel.coverPath == null
                            ? const Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 45,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Choose Cover',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(10),
                                child: Image.file(
                                  File(widget.novel.coverPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 50,
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // TITLE
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Novel Title',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // DESCRIPTION
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Synopsis / Description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // GENRE
                    const Text(
                      'Genre',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...widget.novel.tags.map(
                          (tag) {
                            return InputChip(
                              label: Text(tag),
                              deleteIcon: const Icon(
                                Icons.close,
                                size: 16,
                              ),
                              onDeleted: () {
                                setDialogState(() {
                                  widget.novel.tags.remove(tag);
                                });
                              },
                            );
                          },
                        ),

                        ActionChip(
                          avatar: const Icon(
                            Icons.add,
                            size: 17,
                          ),
                          label: const Text('Add'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (tagDialogContext) {
                                return AlertDialog(
                                  title: const Text(
                                    'Add Genre',
                                  ),
                                  content: TextField(
                                    controller: tagController,
                                    autofocus: true,
                                    decoration:
                                        const InputDecoration(
                                      hintText:
                                          'Example: Fantasy',
                                      border:
                                          OutlineInputBorder(),
                                    ),
                                    onSubmitted: (_) {
                                      addTag();
                                      Navigator.pop(
                                        tagDialogContext,
                                      );
                                    },
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(
                                          tagDialogContext,
                                        );
                                      },
                                      child:
                                          const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        addTag();
                                        Navigator.pop(
                                          tagDialogContext,
                                        );
                                      },
                                      child:
                                          const Text('Add'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
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
                  onPressed: () async {
                    final newTitle =
                        titleController.text.trim();

                    if (newTitle.isEmpty) return;

                    widget.novel.title = newTitle;
                    widget.novel.description =
                        descriptionController.text.trim();

                    await save(
                      originalTitle: oldTitle,
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }

                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    tagController.dispose();
  }

  Future<void> addChapter() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Chapter'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Chapter Title',
              border: OutlineInputBorder(),
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
              onPressed: () async {
                final title = controller.text.trim();

                if (title.isEmpty) return;

                setState(() {
                  widget.novel.chapters.add(
                    Chapter(title: title),
                  );
                });

                await save();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Color statusColor(String status) {
    switch (status) {
      case 'revision':
        return Colors.red;
      case 'done':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String statusText(String status) {
    switch (status) {
      case 'revision':
        return 'Revision';
      case 'done':
        return 'Completed';
      default:
        return 'Writing';
    }
  }

  @override
  Widget build(BuildContext context) {
    final novel = widget.novel;

    return Scaffold(
      backgroundColor: const Color(0xFF101010),

      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        title: Text(
          novel.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Novel',
            onPressed: editNovel,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          14,
          8,
          14,
          20,
        ),
        children: [
          // COVER
          AspectRatio(
            aspectRatio: 0.70,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF1C1C1C),
              ),
              child: novel.coverPath == null
                  ? const Center(
                      child: Icon(
                        Icons.menu_book,
                        size: 70,
                        color: Colors.grey,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(novel.coverPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 60,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 14),

          // TITLE
          Text(
            novel.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (novel.description.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              novel.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ],

          // TAGS
          if (novel.tags.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: novel.tags.map(
                (tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF3A2818),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ],

          const SizedBox(height: 20),

          // CHAPTER HEADER
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chapter',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: addChapter,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 38),
                ),
                icon: const Icon(
                  Icons.add,
                  size: 18,
                ),
                label: const Text('Add'),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // CHAPTER LIST
          if (novel.chapters.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 30,
              ),
              child: Center(
                child: Text(
                  'No chapters yet',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

          ...novel.chapters.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final chapter = entry.value;

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 6,
                ),
                color: const Color(0xFF181818),
                elevation: 0,
                child: ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  leading: CircleAvatar(
                    radius: 18,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  title: Text(
                    chapter.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor(
                            chapter.status,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText(chapter.status),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    size: 20,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditorPage(
                          chapter: chapter,
                        ),
                      ),
                    );

                    setState(() {});
                    await save();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
