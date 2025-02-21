// lib/screens/profile_page_pro.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ProfileProPage extends StatefulWidget {
  const ProfileProPage({Key? key}) : super(key: key);

  @override
  State<ProfileProPage> createState() => _ProfileProPageState();
}

class _ProfileProPageState extends State<ProfileProPage> {
  static const int MAX_FILE_SIZE_BYTES = 1 * 1024 * 1024; // 1MB

  int _selectedIndex = 2; // Default to "Profil" tab

  final List<String> _images = []; // Holds up to 3 image URLs
  final List<Map<String, dynamic>> _prestations = [];
  Map<String, dynamic> _doctorInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctorInfo();
  }

  Future<void> _fetchDoctorInfo() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .get();
      if (doc.exists) {
        setState(() {
          _doctorInfo = doc.data() as Map<String, dynamic>;

          // Load prestations
          if (_doctorInfo.containsKey('prestations') &&
              _doctorInfo['prestations'] is Map) {
            final prestationsMap =
            _doctorInfo['prestations'] as Map<String, dynamic>;
            _prestations.clear();
            prestationsMap.forEach((key, value) {
              final prestationData = Map<String, dynamic>.from(value);
              prestationData['id'] = key;
              _prestations.add(prestationData);
            });
          }

          // Load images
          if (_doctorInfo.containsKey('images') &&
              _doctorInfo['images'] is List) {
            _images.clear();
            _images.addAll(List<String>.from(_doctorInfo['images']));
          }

          _isLoading = false;
        });
      } else {
        print('No doctor found for the current user.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching doctor info: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addImage() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous ne pouvez ajouter que 3 images.')),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      print('No image selected');
      return;
    }

    int fileSize;
    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      fileSize = bytes.lengthInBytes;
    } else {
      fileSize = File(pickedFile.path).lengthSync();
    }
    if (fileSize > MAX_FILE_SIZE_BYTES) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le fichier est trop volumineux. 1 MB max.')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final filePath = 'doctors/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      String imageUrl;
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        final uploadTask =
        FirebaseStorage.instance.ref(filePath).putData(bytes);
        final snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      } else {
        final file = File(pickedFile.path);
        final uploadTask =
        FirebaseStorage.instance.ref(filePath).putFile(file);
        final snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      if (imageUrl.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(uid)
            .update({
          'images': FieldValue.arrayUnion([imageUrl]),
        });
        setState(() => _images.add(imageUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image ajoutée avec succès!')),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de l’ajout de l’image.')),
      );
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('doctors').doc(uid).update({
        'images': FieldValue.arrayRemove([imageUrl]),
      });
      setState(() => _images.remove(imageUrl));

      // (Optional) also delete from storage if you want:
      // await FirebaseStorage.instance.refFromURL(imageUrl).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image supprimée.')),
      );
    } catch (e) {
      print('Error deleting image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression de l’image.')),
      );
    }
  }

  void _addPrestataire() async {
    String? prestataireName;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter un prestataire'),
          content: TextField(
            decoration:
            const InputDecoration(labelText: 'Nom du prestataire'),
            onChanged: (value) => prestataireName = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final trimmedName = prestataireName?.trim();
                if (trimmedName != null && trimmedName.isNotEmpty) {
                  final uid = FirebaseAuth.instance.currentUser!.uid;
                  try {
                    await FirebaseFirestore.instance
                        .collection('doctors')
                        .doc(uid)
                        .update({
                      'prestataires': FieldValue.arrayUnion([trimmedName]),
                      // so you can track each prestataire's "batches"
                      'prestataires_availabilities.$trimmedName': [],
                    });

                    setState(() {
                      if (_doctorInfo['prestataires'] != null &&
                          _doctorInfo['prestataires'] is List) {
                        (_doctorInfo['prestataires'] as List).add(trimmedName);
                      } else {
                        _doctorInfo['prestataires'] = [trimmedName];
                      }
                    });

                    // OPTIONAL: Create an empty doc in `availability` right now
                    // So the booking page sees an empty doc (and returns no times).
                    // Without this, a doc won't be created until you add a batch.
                    await _updateAvailabilityCollection(
                      trimmedName,
                      [],
                    );

                    Navigator.pop(context);
                    print('Prestataire "$trimmedName" added.');
                  } catch (e) {
                    print('Error adding prestataire: $e');
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 232, 228, 214),
              ),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePrestataire(String prestataireName) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('doctors').doc(uid).update({
        'prestataires': FieldValue.arrayRemove([prestataireName]),
        'prestataires_availabilities.$prestataireName': FieldValue.delete(),
      });
      setState(() {
        if (_doctorInfo['prestataires'] != null &&
            _doctorInfo['prestataires'] is List) {
          (_doctorInfo['prestataires'] as List)
              .remove(prestataireName);
        }
        if (_doctorInfo['prestataires_availabilities'] != null &&
            _doctorInfo['prestataires_availabilities'] is Map) {
          (_doctorInfo['prestataires_availabilities'] as Map)
              .remove(prestataireName);
        }
      });

      // Also remove from "availability" collection
      final availQuery = await FirebaseFirestore.instance
          .collection('availability')
          .where('doctor_id', isEqualTo: uid)
          .where('prestataire_name', isEqualTo: prestataireName)
          .get();
      for (var doc in availQuery.docs) {
        await doc.reference.delete();
      }

      print('Prestataire $prestataireName deleted.');
    } catch (e) {
      print('Error deleting prestataire: $e');
    }
  }

  Future<void> _manageBatchAvailabilities(String prestataireName) async {
    List<dynamic> batches = [];
    if (_doctorInfo['prestataires_availabilities'] != null &&
        _doctorInfo['prestataires_availabilities'] is Map) {
      batches = List<dynamic>.from(
        _doctorInfo['prestataires_availabilities'][prestataireName] ?? [],
      );
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          return AlertDialog(
            title: Text('Disponibilités pour $prestataireName'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (batches.isNotEmpty)
                    Column(
                      children: batches.map<Widget>((batch) {
                        String batchName = batch['batch_name'] ?? 'Inconnu';
                        String startDate = batch['start_date'] ?? '';
                        String endDate = batch['end_date'] ?? '';
                        Map daySchedules = batch['day_schedules'] ?? {};
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(batchName),
                            subtitle: Text(
                              'Du $startDate au $endDate\n'
                                  'Jours: ${daySchedules.keys.join(', ')}',
                            ),
                            trailing: IconButton(
                              icon:
                              const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                dialogSetState(() {
                                  batches.remove(batch);
                                });
                                final uid = FirebaseAuth
                                    .instance.currentUser!.uid;
                                await FirebaseFirestore.instance
                                    .collection('doctors')
                                    .doc(uid)
                                    .update({
                                  'prestataires_availabilities.$prestataireName':
                                  batches,
                                });
                                await _updateAvailabilityCollection(
                                    prestataireName, batches);
                                setState(() {
                                  (_doctorInfo['prestataires_availabilities']
                                  as Map)[prestataireName] =
                                      batches;
                                });
                                print('Batch removed for $prestataireName');
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    const Text('Aucune disponibilité définie.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      // Open custom date/time intervals
                      var newBatch = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => CustomAvailabilityDialog(
                          prestataireName: prestataireName,
                        ),
                      );
                      if (newBatch != null) {
                        dialogSetState(() {
                          batches.add(newBatch);
                        });
                        final uid =
                            FirebaseAuth.instance.currentUser!.uid;
                        await FirebaseFirestore.instance
                            .collection('doctors')
                            .doc(uid)
                            .update({
                          'prestataires_availabilities.$prestataireName': batches,
                        });
                        setState(() {
                          if (_doctorInfo['prestataires_availabilities'] ==
                              null ||
                              !(_doctorInfo['prestataires_availabilities']
                              is Map)) {
                            _doctorInfo['prestataires_availabilities'] = {};
                          }
                          (_doctorInfo['prestataires_availabilities']
                          as Map)[prestataireName] =
                              batches;
                        });
                        await _updateAvailabilityCollection(
                            prestataireName, batches);
                        print('New batch added for $prestataireName');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    child: const Text(
                      'Ajouter une plage horaire',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Creates/updates the doc in "availability"
  Future<void> _updateAvailabilityCollection(
      String prestataireName,
      List<dynamic> batches,
      ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final availQuery = await FirebaseFirestore.instance
        .collection('availability')
        .where('doctor_id', isEqualTo: uid)
        .where('prestataire_name', isEqualTo: prestataireName)
        .limit(1)
        .get();
    if (availQuery.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('availability').add({
        'doctor_id': uid,
        'prestataire_name': prestataireName,
        'batches': batches,
      });
      print('Created new availability doc for $prestataireName');
    } else {
      final docRef = availQuery.docs.first.reference;
      await docRef.update({'batches': batches});
      print('Updated availability doc for $prestataireName');
    }
  }

  void _addPrestation() async {
    String? name, description, duration, price;
    List<String> selectedPrestataires = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          List<Widget> prestataireWidgets = [];
          if (_doctorInfo['prestataires'] != null &&
              _doctorInfo['prestataires'] is List &&
              (_doctorInfo['prestataires'] as List).isNotEmpty) {
            prestataireWidgets = (_doctorInfo['prestataires'] as List).map<Widget>((pName) {
              return CheckboxListTile(
                title: Text(pName),
                value: selectedPrestataires.contains(pName),
                onChanged: (val) {
                  dialogSetState(() {
                    if (val == true) {
                      selectedPrestataires.add(pName);
                    } else {
                      selectedPrestataires.remove(pName);
                    }
                  });
                },
              );
            }).toList();
          } else {
            prestataireWidgets = [
              const Text('Aucun prestataire disponible.'),
            ];
          }

          return AlertDialog(
            title: const Text('Ajouter une prestation'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Nom'),
                    onChanged: (val) => name = val,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    onChanged: (val) => description = val,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Durée (min)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => duration = val,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Prix (EUR)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => price = val,
                  ),
                  const SizedBox(height: 10),
                  const Text('Sélectionnez les prestataires:'),
                  ...prestataireWidgets,
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (name != null &&
                      description != null &&
                      duration != null &&
                      price != null &&
                      selectedPrestataires.isNotEmpty) {
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    final prestationId =
                    DateTime.now().millisecondsSinceEpoch.toString();
                    final newPrestation = {
                      'nom': name!.trim(),
                      'description': description!.trim(),
                      'duree': duration!.trim(),
                      'prix': price!.trim(),
                      'prestataires': selectedPrestataires,
                    };
                    try {
                      await FirebaseFirestore.instance
                          .collection('doctors')
                          .doc(uid)
                          .update({
                        'prestations.$prestationId': newPrestation,
                      });

                      setState(() {
                        if (_doctorInfo['prestations'] != null &&
                            _doctorInfo['prestations'] is Map) {
                          (_doctorInfo['prestations']
                          as Map<String, dynamic>)[prestationId] =
                              newPrestation;
                        } else {
                          _doctorInfo['prestations'] = {
                            prestationId: newPrestation,
                          };
                        }
                        newPrestation['id'] = prestationId;
                        _prestations.add(newPrestation);
                      });
                      Navigator.pop(context);
                    } catch (e) {
                      print('Error adding prestation: $e');
                      Navigator.pop(context);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Veuillez remplir tous les champs et sélectionner au moins un prestataire.',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 232, 228, 214),
                ),
                child: const Text('Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editPrestation(Map<String, dynamic> prestation) async {
    final prestationId = prestation['id'];
    String name = prestation['nom'] ?? '';
    String description = prestation['description'] ?? '';
    String duration = prestation['duree'] ?? '';
    String price = prestation['prix'] ?? '';
    List<String> selectedPrestataires =
    prestation['prestataires'] is List
        ? List<String>.from(prestation['prestataires'])
        : [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          List<Widget> prestataireWidgets = [];
          if (_doctorInfo['prestataires'] is List &&
              (_doctorInfo['prestataires'] as List).isNotEmpty) {
            prestataireWidgets =
                (_doctorInfo['prestataires'] as List).map<Widget>((pName) {
                  return CheckboxListTile(
                    title: Text(pName),
                    value: selectedPrestataires.contains(pName),
                    onChanged: (val) {
                      dialogSetState(() {
                        if (val == true) {
                          selectedPrestataires.add(pName);
                        } else {
                          selectedPrestataires.remove(pName);
                        }
                      });
                    },
                  );
                }).toList();
          } else {
            prestataireWidgets = [
              const Text('Aucun prestataire disponible.'),
            ];
          }

          return AlertDialog(
            title: const Text('Modifier la prestation'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Nom'),
                    controller: TextEditingController(text: name),
                    onChanged: (val) => name = val,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    controller: TextEditingController(text: description),
                    onChanged: (val) => description = val,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Durée (min)'),
                    controller: TextEditingController(text: duration),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => duration = val,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Prix (EUR)'),
                    controller: TextEditingController(text: price),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => price = val,
                  ),
                  const SizedBox(height: 10),
                  const Text('Sélectionnez les prestataires:'),
                  ...prestataireWidgets,
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (name.isNotEmpty &&
                      description.isNotEmpty &&
                      duration.isNotEmpty &&
                      price.isNotEmpty &&
                      selectedPrestataires.isNotEmpty) {
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    final updatedPrestation = {
                      'nom': name.trim(),
                      'description': description.trim(),
                      'duree': duration.trim(),
                      'prix': price.trim(),
                      'prestataires': selectedPrestataires,
                    };
                    try {
                      await FirebaseFirestore.instance
                          .collection('doctors')
                          .doc(uid)
                          .update({
                        'prestations.$prestationId': updatedPrestation,
                      });
                      setState(() {
                        final idx = _prestations.indexWhere(
                                (p) => p['id'] == prestationId);
                        if (idx != -1) {
                          updatedPrestation['id'] = prestationId;
                          _prestations[idx] = updatedPrestation;
                        }
                        if (_doctorInfo['prestations'] is Map) {
                          (_doctorInfo['prestations']
                          as Map<String, dynamic>)[prestationId] =
                              updatedPrestation;
                        }
                      });
                      Navigator.pop(context);
                    } catch (e) {
                      print('Error editing prestation: $e');
                      Navigator.pop(context);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Veuillez remplir tous les champs et sélectionner au moins un prestataire.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 232, 228, 214),
                ),
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deletePrestation(String prestationId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('doctors').doc(uid).update({
        'prestations.$prestationId': FieldValue.delete(),
      });
      setState(() {
        _prestations.removeWhere((p) => p['id'] == prestationId);
        if (_doctorInfo['prestations'] is Map) {
          (_doctorInfo['prestations'] as Map<String, dynamic>)
              .remove(prestationId);
        }
      });
      print('Prestation $prestationId deleted.');
    } catch (e) {
      print('Error deleting prestation: $e');
    }
  }

  Future<void> _editField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier $field'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'Nouveau $field'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection('doctors')
                    .doc(uid)
                    .update({field: controller.text});
                setState(() {
                  _doctorInfo[field] = controller.text;
                });
                Navigator.pop(context);
              } catch (e) {
                print('Error updating $field: $e');
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 232, 228, 214),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 232, 228, 214),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 20, horizontal: 16),
                color: const Color.fromARGB(255, 232, 228, 214),
                child: Center(
                  child: RichText(
                    text: const TextSpan(
                      text: 'Bookit',
                      style: TextStyle(
                        fontFamily: 'DreamAvenue',
                        fontSize: 46,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: ' Pro',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Image row
              SizedBox(
                height: 110,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (String url in _images)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: url.startsWith('http')
                                    ? Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (ctx, error, stack) {
                                    return Container(
                                      color: Colors.grey,
                                      child: const Center(
                                          child: Text(
                                              "Erreur de chargement")),
                                    );
                                  },
                                )
                                    : Image.file(File(url),
                                    fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  onPressed: () => _deleteImage(url),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // "Add" tile if < 3 images
                      if (_images.length < 3)
                        GestureDetector(
                          onTap: _addImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.add,
                                size: 40, color: Colors.black),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Doctor name
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _doctorInfo['doctor_name'] ?? 'Nom de votre salon',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editField(
                      'doctor_name',
                      _doctorInfo['doctor_name'] ?? '',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Address
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _doctorInfo['address'] ?? 'Adresse de votre salon',
                      style: const TextStyle(
                          fontSize: 16, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Phone
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _doctorInfo['phone'] ?? 'Téléphone non défini',
                      style: const TextStyle(
                          fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        _editField('phone', _doctorInfo['phone'] ?? ''),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Email
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _doctorInfo['email'] ?? 'Email non défini',
                      style:
                      const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        _editField('email', _doctorInfo['email'] ?? ''),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Prestations
              const Text(
                'Prestations',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._prestations.map((prestation) {
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(prestation['nom'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(prestation['description'] ?? ''),
                        Text(
                            'Durée estimée: ${prestation['duree'] ?? '??'} min'),
                        Text('Prix: ${prestation['prix'] ?? '??'} EUR'),
                        Text(
                          'Prestataires: ${prestation['prestataires'] is List ? (prestation['prestataires'] as List).join(', ') : 'Aucun'}',
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => _editPrestation(prestation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                                255, 232, 228, 214),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Éditer',
                              style: TextStyle(color: Colors.black)),
                        ),
                        IconButton(
                          icon:
                          const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deletePrestation(prestation['id']),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _addPrestation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Ajouter une prestation',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Prestataires
              const Text(
                'Prestataires',
                style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildPrestatairesList(),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _addPrestataire,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Ajouter un prestataire',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 232, 228, 214),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Ajouter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/home_pro');
              break;
            case 1:
              Navigator.pushNamed(context, '/add_event_pro');
              break;
            case 2:
            // Already here
              break;
          }
        },
      ),
    );
  }

  Widget _buildPrestatairesList() {
    if (_doctorInfo['prestataires'] is List &&
        (_doctorInfo['prestataires'] as List).isNotEmpty) {
      return Wrap(
        spacing: 8.0,
        children: (_doctorInfo['prestataires'] as List).map<Widget>((pName) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => _manageBatchAvailabilities(pName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 232, 228, 214),
                  ),
                  child: Text(pName),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePrestataire(pName),
                  tooltip: 'Supprimer $pName',
                ),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      return const Text('Aucun prestataire ajouté');
    }
  }
}

/// A custom dialog for adding a new "batch" with a date range + daily intervals.
class CustomAvailabilityDialog extends StatefulWidget {
  final String prestataireName;
  const CustomAvailabilityDialog({Key? key, required this.prestataireName})
      : super(key: key);

  @override
  _CustomAvailabilityDialogState createState() =>
      _CustomAvailabilityDialogState();
}

class _CustomAvailabilityDialogState extends State<CustomAvailabilityDialog> {
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _daysShort = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  final Map<String, String> _dayMapping = {
    'Lun': 'monday',
    'Mar': 'tuesday',
    'Mer': 'wednesday',
    'Jeu': 'thursday',
    'Ven': 'friday',
    'Sam': 'saturday',
    'Dim': 'sunday',
  };
  Set<String> _selectedDays = {};
  List<Map<String, TimeOfDay>> _intervals = [];

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickStartDate() async {
    final init = _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final init = _endDate ?? (_startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _addCustomInterval() async {
    TimeOfDay? start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (start == null) return;

    TimeOfDay? end = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (end == null) return;

    setState(() {
      _intervals.add({'start': start, 'end': end});
    });
  }

  Future<void> _editInterval(int index) async {
    final interval = _intervals[index];
    TimeOfDay? newStart = await showTimePicker(
      context: context,
      initialTime: interval['start']!,
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (newStart == null) return;

    TimeOfDay? newEnd = await showTimePicker(
      context: context,
      initialTime: interval['end']!,
      builder: (ctx, child) {
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (newEnd == null) return;

    setState(() {
      _intervals[index] = {'start': newStart, 'end': newEnd};
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ajouter une plage horaire pour ${widget.prestataireName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date range
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Début'),
                    subtitle: Text(_startDate != null
                        ? _formatDate(_startDate!)
                        : 'Sélectionnez'),
                    onTap: _pickStartDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Fin'),
                    subtitle: Text(_endDate != null
                        ? _formatDate(_endDate!)
                        : 'Sélectionnez'),
                    onTap: _pickEndDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Days of week
            const Text('Jours à appliquer :',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8.0,
              children: _daysShort.map((dayShort) {
                return ChoiceChip(
                  label: Text(dayShort),
                  selected: _selectedDays.contains(dayShort),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(dayShort);
                      } else {
                        _selectedDays.remove(dayShort);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Intervals
            const Text('Horaires de travail :',
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (_intervals.isNotEmpty)
              Column(
                children: _intervals.asMap().entries.map((entry) {
                  final i = entry.key;
                  final interval = entry.value;
                  return ListTile(
                    title: Text(
                      '${_formatTime(interval['start']!)} - '
                          '${_formatTime(interval['end']!)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _editInterval(i),
                        ),
                        IconButton(
                          icon:
                          const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => setState(() {
                            _intervals.removeAt(i);
                          }),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            else
              const Text('Aucun horaire ajouté.'),
            const SizedBox(height: 8),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[600]),
              onPressed: _addCustomInterval,
              child: const Text('Ajouter plage horaire'),
            ),
            const SizedBox(height: 16),
            if (_startDate != null && _endDate != null)
              Text(
                'Période: ${_formatDate(_startDate!)} à ${_formatDate(_endDate!)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_startDate == null ||
                _endDate == null ||
                _selectedDays.isEmpty ||
                _intervals.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Remplissez tous les champs & horaires'),
                ),
              );
              return;
            }

            // day_schedules
            Map<String, dynamic> daySchedules = {};
            for (var short in _selectedDays) {
              final dayKey = _dayMapping[short]!;
              daySchedules[dayKey] = _intervals.map((interval) {
                return {
                  'start_time': _formatTime(interval['start']!),
                  'end_time': _formatTime(interval['end']!),
                };
              }).toList();
            }

            final batchId = DateTime.now().millisecondsSinceEpoch.toString();
            final newBatch = {
              'batch_id': batchId,
              'batch_name':
              '${_formatDate(_startDate!)} to ${_formatDate(_endDate!)}',
              'day_schedules': daySchedules,
              'start_date': _formatDate(_startDate!),
              'end_date': _formatDate(_endDate!),
              'doctor_id': FirebaseAuth.instance.currentUser!.uid,
              'prestataire_name': widget.prestataireName,
            };

            Navigator.pop(context, newBatch);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
