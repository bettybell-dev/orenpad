import 'dart:io';

import 'package:flutter/material.dart';

import '../models/novel.dart';
import '../services/storage.dart';
import 'novel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Novel> novels = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNovels();
  }

  Future<void> loadNovels() async {
    final loaded = await StorageService.loadNovels();

    if (!mounted) return;

    setState(() {
      novels = loaded;
      loading = false;
    });
  }

  Future<void> save() async {
    await StorageService.saveNovels(novels);
  }

  Future<void> addNovel() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Novel'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Novel Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
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
                final title = titleController.text.trim();

                if (title.isEmpty) return;

                final novel = Novel(
                  title: title,
                  description: descriptionController.text.trim(),
                );

                setState(() {
                  novels.add(novel);
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

    titleController.dispose();
    descriptionController.dispose();
  }

  void showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Orenpad',
      applicationVersion: '0.2.0',
      applicationLegalese:
          'An application for starting and writing novels simply.',
      children: const [
        SizedBox(height: 12),
        Text(
          'Orenpad is a novel writing application created '
          'to help you start, organize, and write novels '
          'with simplicity.',
        ),
        SizedBox(height: 12),
        Text(
          'Created by: MacLeo-Nim',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void showPdfMessage() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Convert to PDF'),
          content: const Text(
            'The novel-to-PDF conversion feature will be available '
            'after the PDF editor system is completed.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),

      appBar: AppBar(
        backgroundColor: const Color(0xFF101010),
        elevation: 0,
        centerTitle: true,

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              'Orenpad',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'pdf') {
                showPdfMessage();
              }

              if (value == 'about') {
                showAbout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'pdf',
                child: Text('Convert to PDF'),
              ),
              PopupMenuItem(
                value: 'about',
                child: Text('About'),
              ),
            ],
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : novels.isEmpty
              ? const Center(
                  child: Text(
                    'No novels yet',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    14,
                    28,
                    14,
                    90,
                  ),
                  itemCount: novels.length,
                  itemBuilder: (context, index) {
                    final novel = novels[index];

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      color: const Color(0xFF181818),
                      elevation: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),

                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NovelPage(
                                novel: novel,
                              ),
                            ),
                          );

                          await save();

                          if (mounted) {
                            setState(() {});
                          }
                        },

                        child: Padding(
                          padding: const EdgeInsets.all(10),

                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // COVER
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(7),
                                child: Container(
                                  width: 72,
                                  height: 102,
                                  color: const Color(0xFF252525),

                                  child: novel.coverPath == null
                                      ? const Icon(
                                          Icons.menu_book,
                                          color: Colors.grey,
                                          size: 32,
                                        )
                                      : Image.file(
                                          File(novel.coverPath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            );
                                          },
                                        ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // TITLE + STATS
                              Expanded(
                                child: SizedBox(
                                  height: 102,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        novel.title,
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      Text(
                                        '${novel.chapters.length} Chapters • - Words',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 6),

                              // NOVEL MENU
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  size: 20,
                                ),

                                onSelected: (value) async {
                                  // EDIT
                                  if (value == 'edit') {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => NovelPage(
                                          novel: novel,
                                          openEdit: true,
                                        ),
                                      ),
                                    );

                                    await save();

                                    if (mounted) {
                                      setState(() {});
                                    }
                                  }

                                  // MOVE TO TOP
                                  if (value == 'top') {
                                    setState(() {
                                      novels.removeAt(index);
                                      novels.insert(0, novel);
                                    });

                                    await save();
                                  }

                                  // DELETE
                                  if (value == 'delete') {
                                    final confirm =
                                        await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) {
                                        return AlertDialog(
                                          title: const Text(
                                            'Delete Novel?',
                                          ),
                                          content: Text(
                                            'Novel "${novel.title}" will be deleted.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                  dialogContext,
                                                  false,
                                                );
                                              },
                                              child: const Text(
                                                'Cancel',
                                              ),
                                            ),
                                            FilledButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                  dialogContext,
                                                  true,
                                                );
                                              },
                                              child: const Text(
                                                'Delete',
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (confirm == true) {
                                      setState(() {
                                        novels.removeAt(index);
                                      });

                                      await save();
                                    }
                                  }
                                },

                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'top',
                                    child: Text(
                                      'Move to top',
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

      floatingActionButton: FloatingActionButton(
        onPressed: addNovel,
        child: const Icon(Icons.add),
      ),
    );
  }
}
